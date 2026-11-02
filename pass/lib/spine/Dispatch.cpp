// Module spine (cq-w0-construct): the per-instruction dispatch of construct() (cq-arch table).
//
// Classical instructions are copied with their operands remapped. Every other instruction goes to
// the module the cq-arch dispatch table names; this file decides only which. Terminators and phis of
// the walked function belong to the walker (Construct.cpp).
#include "SpineInternal.h"

#include "cq/Abi.h"
#include "cq/Aggregates.h"
#include "cq/Effects.h"
#include "cq/FatPtr.h"
#include "cq/Memory.h"
#include "cq/Rotation.h"
#include "cq/Switch.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "cq/Loops.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

#include "../mem/slots/SlotsInternal.h"

using namespace llvm;

namespace cq::spine {

namespace {

bool involvesNonClassicalMemory(LoweringContext &ctx, const Value *ptr) {
  if (!ptr->getType()->isPointerTy())
    return false;
  if (ctx.T.isFatPointer(ptr, ctx.S))
    return true;
  for (ObjectId o : ctx.T.provenance(ptr, ctx.S))
    if (ctx.T.classOf(o) != ObjClass::Classical && !calls::isVaArea(ctx, o))
      return true;   // a variadic save area is host memory holding handles (95): classical addresses
  return false;
}

// The class of an allocation site: QRAM if any of its objects is, else Slot if any is. An
// array-of-structs site is one object per field column (rule 20), so it is read through provenance,
// never objectOf (cq-qj49).
ObjClass objectsClass(LoweringContext &ctx, const Value *site) {
  ObjClass c = ObjClass::Classical;
  for (ObjectId o : ctx.T.provenance(site, ctx.S)) {
    ObjClass k = ctx.T.classOf(o);
    if (k == ObjClass::Qram)
      return k;
    if (k == ObjClass::Slot)
      c = k;
  }
  return c;
}

// One object of a non-classical class reached by a pointer, for a lifetime end.
ObjectId soleObject(LoweringContext &ctx, const Value *ptr, const Instruction &at) {
  ArrayRef<ObjectId> objs = ctx.T.provenance(ptr, ctx.S);
  if (objs.size() != 1)
    unimplemented("spine: a lifetime end through a pointer with " + std::to_string(objs.size()) + " objects", &at);
  return objs.front();
}

// A quantum i1 whose only users are branch conditions that pred expanded into their terms (rule 8:
// the condition has a classical factor, so no edge predicate uses it as one atom) has no rail to
// compute: its terms are the flags and the classical factor is a classical branch.
bool onlyFactoredConditions(LoweringContext &ctx, const Instruction &I) {
  if (!I.getType()->isIntegerTy(1) || I.use_empty() || spine::shared(ctx).conditionAsData)
    return false;
  Pred whole = Pred::atom(&I);
  for (const User *u : I.users()) {
    auto *br = dyn_cast<BranchInst>(u);
    if (!br || !br->isConditional() || br->getCondition() != &I || br->getFunction() != I.getFunction())
      return false;
    for (const BasicBlock *s : br->successors()) {
      const Pred &e = ctx.preds().edge(br->getParent(), s);
      if (e.isBottom())
        continue;
      if ((e & !whole).isBottom() || (e & whole).isBottom())
        return false;
    }
  }
  return true;
}

// Rule 8: a mixed i1 used as data, -O1's logical select over a classical condition and a constant
// arm: c ? q : false = q & c, c ? true : q = q | c (and their negated-c forms) is the i1 template
// with c as the literal (rule 4, the handle first).
bool lowerLogicalSelect(LoweringContext &ctx, SelectInst &sel) {
  if (!sel.getType()->isIntegerTy(1))
    return false;
  auto *t = dyn_cast<ConstantInt>(sel.getTrueValue());
  auto *f = dyn_cast<ConstantInt>(sel.getFalseValue());
  const Value *q;
  const char *op;
  bool negC;
  if (f && f->isZero() && !t) { q = sel.getTrueValue(); op = "and"; negC = false; }        // c & q
  else if (t && t->isOne() && !f) { q = sel.getFalseValue(); op = "or"; negC = false; }     // c | q
  else if (t && t->isZero() && !f) { q = sel.getFalseValue(); op = "and"; negC = true; }    // !c & q
  else if (f && f->isOne() && !t) { q = sel.getTrueValue(); op = "or"; negC = true; }       // !c | q
  else
    return false;
  Operand h = ctx.operand(q), c = ctx.operand(sel.getCondition());
  if (!h.handle || c.handle)
    return false;
  Value *lit = negC ? ctx.B().CreateNot(c.v) : c.v;
  abi::TemplateSpec spec;
  spec.op = op;
  spec.w = RailType{Kind::Int, 1};
  spec.shape = "hl";
  ctx.emitTemplate(spec, {h, Operand{lit, false}}, &sel);
  return true;
}

// Rule 21: whether a pointer's TAG (which object it points into) depends on quantum data. A pointer
// is (tag, idx); a GEP index, its widening and its scaling only move idx, so a pointer whose every
// root is a classical pointer has a classical tag even when taint calls it fat for a quantum index.
// The tag is quantum where a quantum choice may pick between different objects (a select on a
// quantum condition, a phi merging different provenances) or where the pointer itself arrives
// quantum (loaded through a fat pointer, a clone parameter, inttoptr: rule 21's fat pointer). A
// phi whose incomings differ in provenance counts as quantum-chosen: routing it to rule 21 is never
// wrong (a classical tag is a guard that is constant), only less direct.
bool quantumTagImpl(LoweringContext &ctx, const Value *p, SmallPtrSetImpl<const Value *> &seen) {
  for (;;) {
    if (auto *g = dyn_cast<GEPOperator>(p)) {
      p = g->getPointerOperand();
      continue;
    }
    if (auto *bc = dyn_cast<BitCastOperator>(p)) {
      p = bc->getOperand(0);
      continue;
    }
    if (auto *ac = dyn_cast<AddrSpaceCastOperator>(p)) {
      p = ac->getPointerOperand();
      continue;
    }
    // cq-9w75: a K-loop's walked pointer is its start moved by the trip (LoweringContext::walkedPointer).
    if (const WalkedPtr *w = ctx.walkedPointer(p)) {
      p = w->start;
      continue;
    }
    break;
  }
  // P1 (190): a clone's slot triple formal with a cell count is bound by fatptr (bindFormal); its
  // accesses are rule 21's, checked against the cell count (fatptr boundSlotLoad).
  if (auto *A = dyn_cast<Argument>(p); A && !ctx.S.isEntry() && A->getType()->isPointerTy()) {
    PtrFormal pf = ctx.T.pointerFormal(ctx.S, A->getArgNo());
    if (pf.abi == PtrAbi::TripleCount && pf.pointee == ObjClass::Slot && !mem::isPointerKindFormal(ctx, *A))
      return true;   // cq-oocu: a pointer-kind formal's accesses are mem-slots' (107)
  }
  if (!ctx.T.isFatPointer(p, ctx.S) && !isQ(ctx, p))
    return false;
  if (!seen.insert(p).second)
    return false;   // a cycle through phis adds no root of its own
  auto sameObjects = [&](const Value *a, const Value *b) {
    ArrayRef<ObjectId> x = ctx.T.provenance(a, ctx.S), y = ctx.T.provenance(b, ctx.S);
    return x.size() == 1 && y.size() == 1 && x.front() == y.front();
  };
  if (auto *sel = dyn_cast<SelectInst>(p)) {
    if (isQ(ctx, sel->getCondition()) && !sameObjects(sel->getTrueValue(), sel->getFalseValue()))
      return true;
    return quantumTagImpl(ctx, sel->getTrueValue(), seen) || quantumTagImpl(ctx, sel->getFalseValue(), seen);
  }
  if (auto *phi = dyn_cast<PHINode>(p)) {
    for (const Value *in : phi->incoming_values())
      if (in != phi && !sameObjects(in, phi))
        return true;
    for (const Value *in : phi->incoming_values())
      if (quantumTagImpl(ctx, in, seen))
        return true;
    return false;
  }
  return true;
}

bool quantumTag(LoweringContext &ctx, const Value *p) {
  SmallPtrSet<const Value *, 8> seen;
  return quantumTagImpl(ctx, p, seen);
}

// The construction of one load or store, by rule 20's table and rule 21. A quantum tag is a fat
// pointer (rule 21; its per-object accesses are rule 20's again). A classical tag reaches one
// classified object: QRAM and slot objects take every access through their module (classical or
// quantum offset); classical memory at a quantum offset is a QROM load; anything else is classical.
enum class Access : uint8_t { Fat, Qram, Slot, Qrom, Classical };

Access classifyAccess(LoweringContext &ctx, Instruction &I, const Value *p) {
  if (quantumTag(ctx, p))
    return Access::Fat;
  bool qram = false, slot = false;
  for (ObjectId o : ctx.T.provenance(p, ctx.S)) {
    qram |= ctx.T.classOf(o) == ObjClass::Qram;
    slot |= ctx.T.classOf(o) == ObjClass::Slot;
  }
  if (qram)
    return Access::Qram;
  if (slot)
    return Access::Slot;
  if (ctx.T.offsetKind(&I, ctx.S) == OffsetKind::Quantum) {
    if (isa<StoreInst>(I))
      internalError("spine: a quantum-offset store into memory taint classified Classical (rule 20: QRAM)", &I);
    return Access::Qrom;
  }
  return Access::Classical;
}

void lowerMemoryAccess(LoweringContext &ctx, Instruction &I) {
  if (auto *ld = dyn_cast<LoadInst>(&I)) {
    if (ld->isVolatile() || ld->isAtomic()) {
      if (ld->isAtomic())
        conc::lowerAtomic(ctx, I);
      else
        conc::lowerVolatile(ctx, I);
      return;
    }
    switch (classifyAccess(ctx, I, ld->getPointerOperand())) {
    case Access::Fat:
      return fatptr::lowerLoad(ctx, *ld);
    case Access::Qram:
      return mem::lowerQramLoad(ctx, *ld);
    case Access::Slot:
      return mem::lowerSlotLoad(ctx, *ld);
    case Access::Qrom:
      return mem::lowerQromLoad(ctx, *ld);
    case Access::Classical:
      break;
    }
    if (isQ(ctx, ld))
      internalError("spine: a classical-offset load of classical memory that taint calls quantum", ld);
    bindOperand(ctx, ld, Operand{copyClassical(ctx, I), false});
    return;
  }
  auto *st = cast<StoreInst>(&I);
  if (st->isVolatile() || st->isAtomic()) {
    if (st->isAtomic())
      conc::lowerAtomic(ctx, I);
    else
      conc::lowerVolatile(ctx, I);
    return;
  }
  switch (classifyAccess(ctx, I, st->getPointerOperand())) {
  case Access::Fat:
    return fatptr::lowerStore(ctx, *st);
  case Access::Qram:
    return mem::lowerQramStore(ctx, *st);
  case Access::Slot:
    return mem::lowerSlotStore(ctx, *st);
  case Access::Qrom:
    internalError("spine: a QROM store", st);
  case Access::Classical:
    break;
  }
  if (isQ(ctx, st->getValueOperand()))
    internalError("spine: a quantum value stored into memory taint classified Classical", st);
  copyClassical(ctx, I);
}

// Rule 20, index operand: the widening of a quantum index is address arithmetic and never emitted
// when its every use is a GEP index (that GEP has a quantum index, so it is never emitted either;
// the access reads the logical index rail beneath the cast). A cast with any other use is a value
// and lowered as one.
bool onlyAddressIndex(const Instruction &I) {
  return !I.use_empty() && llvm::all_of(I.uses(), [](const Use &u) {
    return isa<GetElementPtrInst>(u.getUser()) && u.getOperandNo() != 0;
  });
}

// Rule 12 under a rule-14 trip (cq-99f7): the trip predicate is quantum, so a classical-angle phase is
// never global: rz_i1 on the trip's control (the trip rail, or its conjunction with the block's
// quantum part).
void lowerTripPhase(LoweringContext &ctx, CallInst &cqPhi) {
  if (cqPhi.arg_size() != 1)
    internalError("spine: cq_phi with other than one argument", &cqPhi);
  if (ctx.S.pure)
    return;   // a _pure clone is the clone without its phase effects (CR §1.4)
  Operand angle = ctx.operand(cqPhi.getArgOperand(0));
  if (angle.handle)
    internalError("spine: a classical cq_phi angle whose operand is a rail", &cqPhi);
  Value *f = ctx.currentFlag();
  if (!f)
    internalError("spine: no control under a trip flag", &cqPhi);
  ctx.emitCore(abi::CoreSpec{abi::Core::RzI1, RailType{Kind::Int, 1}}, {f, angle.v});
}

void lowerCall(LoweringContext &ctx, CallBase &CB) {
  using calls::Class;
  Class c = calls::classify(CB, ctx.T, ctx.S);
  auto *CI = dyn_cast<CallInst>(&CB);
  switch (c) {
  case Class::Classical: {
    Instruction *n = copyClassical(ctx, CB);
    if (!CB.getType()->isVoidTy())
      bindOperand(ctx, &CB, Operand{n, false});
    return;
  }
  case Class::Theta: {
    if (!CI)
      internalError("spine: cq_theta through invoke", &CB);
    // cq-s32y: a use of the operand after an in-place rotation reads a copy taken before the Ry.
    // cq-6qum: an uncontrolled rotation of a register state rotates a copy: rule 2's (classical
    // angle) and rule 15's (quantum angle, cq-r9j0) alike.
    bool uncontrolled = ctx.currentPredicate().isTop() && !shared(ctx).tripFlag;
    std::optional<PendingCopy> pre = beginPreRotation(ctx, *CI, uncontrolled);
    if (isQ(ctx, CI->getArgOperand(1))) {
      // cq-t3rd: under a flag it is rule 10's in-place rotation (rot-cry), a register state as the
      // classical angle's.
      if (ctx.currentFlag())
        shared(ctx).statePreps.insert(CI);
      rot::lowerQuantumAngleTheta(ctx, *CI, ctx.currentFlag());          // rules 11, 15
    } else if (Value *flag = ctx.currentFlag()) {
      shared(ctx).statePreps.insert(CI);                                  // a merge of it: cq-gtcn
      rot::lowerControlledTheta(ctx, *CI, flag);                          // rule 10
    } else {
      lowerTheta(ctx, *CI);                                               // rule 2
    }
    finishPreRotation(ctx, pre);
    return;
  }
  case Class::Measure:
    if (!CI)
      internalError("spine: cq_measure through invoke", &CB);
    lowerMeasure(ctx, *CI);
    return fenv::afterMeasure(ctx, *CI);   // rule 2 collapse of the fenv state (rule 23, cq-tigu)
  case Class::Phi:
    if (!CI)
      internalError("spine: cq_phi through invoke", &CB);
    if (isQ(ctx, CI->getArgOperand(0)))
      return rot::lowerQuantumAnglePhase(ctx, *CI, ctx.currentFlag());   // rule 15
    if (shared(ctx).tripFlag)
      return lowerTripPhase(ctx, *CI);                                   // rules 12, 14 (cq-99f7)
    return lowerPhase(ctx, *CI);                                         // rule 12
  case Class::InvertBegin:
  case Class::InvertEnd:
    internalError("spine: a cq_invert marker outside the walker's region handling", &CB);
  case Class::Lift: {
    // Rule 19: an in-module entry function that returns an unmeasured quantum value, called with
    // no quantum argument, is inlined into its in-module caller (162). Everything else is rule 18.
    const Function *callee = CB.getCalledFunction();
    bool qArg = false;
    for (const Use &u : CB.args())
      qArg |= isQ(ctx, u.get());
    if (callee && !qArg && !CB.getType()->isVoidTy() && isQ(ctx, &CB)) {
      const Specialization *cs = ctx.T.calleeSpecialization(CB, ctx.S);
      if (!cs || !cs->isEntry()) {
        cs = nullptr;
        for (const Specialization &s : ctx.T.specializations())
          if (s.F == callee && s.isEntry())
            cs = &s;
      }
      if (cs && cs->isEntry())
        return lowerInline(ctx, CB, *cs);
    }
    Instruction *before = ctx.B().GetInsertPoint() == ctx.B().GetInsertBlock()->begin()
                              ? nullptr
                              : &*std::prev(ctx.B().GetInsertPoint());
    BasicBlock *startBlock = ctx.B().GetInsertBlock();
    calls::lowerLifted(ctx, CB);
    // cq-ihlt: the rails whose formal the callee measures (rule 2 re-read in the caller).
    return noteCalleeMeasures(ctx, CB, startBlock, before);
  }
  case Class::Indirect: return calls::lowerIndirect(ctx, CB);
  case Class::Declared: return calls::lowerDeclared(ctx, CB);
  case Class::Asm: {
    bool q = false;
    for (const Use &u : CB.args())
      q |= isQ(ctx, u.get());
    if (!q && !isQ(ctx, &CB)) {   // an asm with only classical operands stays the asm (rule 27)
      Instruction *n = copyClassical(ctx, CB);
      if (!CB.getType()->isVoidTy())
        bindOperand(ctx, &CB, Operand{n, false});
      return;
    }
    return calls::lowerAsm(ctx, CB);
  }
  case Class::HostEffect: return tape::lowerHostEffect(ctx, CB);
  case Class::Noreturn: return tape::lowerNoreturn(ctx, CB);
  case Class::Alloc:
    if (auto *II = dyn_cast<IntrinsicInst>(&CB); II && II->getIntrinsicID() == Intrinsic::lifetime_start) {
      // The start of a slot/QRAM object's scope: the object is allocated at its alloca.
      return;
    }
    if (objectsClass(ctx, &CB) == ObjClass::Qram)
      return mem::allocateQram(ctx, CB);
    return mem::allocateSlots(ctx, CB);
  case Class::Dealloc: {
    const Value *p = nullptr;
    if (auto *II = dyn_cast<IntrinsicInst>(&CB)) {
      if (II->getIntrinsicID() == Intrinsic::lifetime_end)
        p = II->getArgOperand(1);
      else
        unimplemented("spine: stackrestore of a scope holding slot or QRAM objects (rule 20, 192)", &CB);
    } else {
      p = CB.getArgOperand(0);
    }
    ObjectId o = soleObject(ctx, p, CB);
    if (ctx.T.classOf(o) == ObjClass::Qram)
      return mem::endQramLifetime(ctx, o, &CB);
    return mem::endSlotLifetime(ctx, o, &CB);
  }
  case Class::Realloc:
    if (objectsClass(ctx, &CB) == ObjClass::Qram)
      return mem::reallocQram(ctx, CB);   // M5 (cq-arch 2026-11-01)
    unimplemented("spine: realloc of a slot block has no entry in Memory.h (rule 16)", &CB);
  case Class::MemIntrinsic: return mem::lowerMemIntrinsic(ctx, cast<MemIntrinsic>(CB));
  case Class::TemplateIntrinsic:
    if (auto *II = dyn_cast<IntrinsicInst>(&CB); II && II->getIntrinsicID() == Intrinsic::ptrmask) {
      fatptr::lower(ctx, &CB);   // rule 21 (105): binds the masked pointer's (tag, idx) here
      return;
    }
    return lowerOpcode(ctx, CB);
  case Class::LibmIntrinsic: return calls::lowerLifted(ctx, CB);
  case Class::Fenv:
    if (isa<ConstrainedFPIntrinsic>(CB))
      return fenv::lowerConstrained(ctx, CB);
    if (isa<IntrinsicInst>(CB))
      unimplemented("spine: llvm.get.rounding / llvm.set.rounding have no entry in Effects.h (rule 23, "
                    "eff-fenv)",
                    &CB);
    return fenv::lowerFenvCall(ctx, CB);
  case Class::Thread: return conc::lowerThreadCall(ctx, CB);
  case Class::Setjmp: return conc::lowerSetjmp(ctx, CB);
  case Class::Longjmp: return conc::lowerLongjmp(ctx, CB);
  case Class::Varargs: return calls::lowerVarargs(ctx, CB);
  case Class::Atomic: return conc::lowerAtomic(ctx, CB);
  }
  internalError("spine: unknown call class", &CB);
}

} // namespace

namespace {

bool boolRangeLoad(const LoadInst *ld) {
  MDNode *r = ld->getMetadata(LLVMContext::MD_range);
  if (!ld->getType()->isIntegerTy(8) || !r || r->getNumOperands() != 2)
    return false;
  auto *lo = mdconst::dyn_extract<ConstantInt>(r->getOperand(0));
  auto *hi = mdconst::dyn_extract<ConstantInt>(r->getOperand(1));
  return lo && hi && lo->isZero() && hi->getZExtValue() == 2;
}

bool boolValueStore(const StoreInst *st) {
  const Value *v = st->getValueOperand();
  if (auto *c = dyn_cast<ConstantInt>(v); c && c->getBitWidth() > 8 && c->getBitWidth() % 8 == 0) {
    for (unsigned k = 0; k < c->getBitWidth() / 8; ++k)
      if (c->getValue().extractBitsAsZExtValue(8, 8 * k) > 1)
        return false;
    return true;
  }
  if (!v->getType()->isIntegerTy(8))
    return false;
  if (auto *z = dyn_cast<ZExtInst>(v))
    return z->getSrcTy()->isIntegerTy(1);
  if (auto *c = dyn_cast<ConstantInt>(v))
    return c->getZExtValue() <= 1;
  return false;
}

} // namespace

bool boolCellAccess(LoweringContext &ctx, const Instruction &access) {
  const Value *p;
  if (auto *ld = dyn_cast<LoadInst>(&access)) {
    if (ld->isVolatile() || ld->isAtomic())
      return false;
    p = ld->getPointerOperand();
  } else if (auto *st = dyn_cast<StoreInst>(&access)) {
    if (st->isVolatile() || st->isAtomic())
      return false;
    p = st->getPointerOperand();
  } else {
    return false;
  }
  auto &I = const_cast<Instruction &>(access);
  if (classifyAccess(ctx, I, p) != Access::Slot)
    return false;
  ArrayRef<ObjectId> objs = ctx.T.provenance(p, ctx.S);
  if (objs.size() != 1)
    return false;   // mem-slots stops on an access of several objects
  ObjectId o = objs.front();
  auto hasO = [&](const Value *q) { return llvm::is_contained(ctx.T.provenance(q, ctx.S), o); };
  for (const Instruction &J : instructions(*access.getFunction())) {
    if (auto *ld = dyn_cast<LoadInst>(&J)) {
      if (hasO(ld->getPointerOperand()) && !boolRangeLoad(ld))
        return false;
    } else if (auto *st = dyn_cast<StoreInst>(&J)) {
      if (hasO(st->getPointerOperand()) && !boolValueStore(st))
        return false;
    }
  }
  return true;
}

namespace {

// cq-nzlq (owner ruling 2026-11-02, CR rule 9 / rule 14): whether the copy being emitted now may run on
// an input where the C program does not execute the original: the current block runs under a quantum
// predicate (its arm is linearized, rule 9), the copy is in a loop trip masked by a quantum exit (rule 14
// case 3's trip rail, a K-loop trip of the cutoff, or a classical loop inside either), or the function is
// a clone (rule 18: a _ctl clone runs whenever it is called, the flag 0 included, and a clone with no
// effects is called unconditionally from a quantum arm, its value selected; s5 in tests/spine/probes).
bool speculated(LoweringContext &ctx) {
  Shared &sh = shared(ctx);
  if (!ctx.S.isEntry() || sh.tripFlag || (sh.curPred && !sh.curPred->isTop()))
    return true;
  const Loop *U = ctx.loopUnit();
  if (!U || !sh.cur)
    return false;
  const Instruction *at = sh.cur;   // walk out through inlined call sites into the unit's function
  for (size_t i = sh.inlineStack.size(); at->getFunction() != U->getHeader()->getParent();) {
    if (i == 0)
      internalError("spine: the current instruction is outside its loop unit's function", sh.cur);
    at = sh.inlineStack[--i];
  }
  // Each loop from U down to the innermost one holding `at`: only rule 14 case 1 runs its trips exactly
  // where C does.
  for (const Loop *L = U; L && L->contains(at->getParent());) {
    if (loops::classify(*L, ctx.T, ctx.S) != loops::Case::ClassicalBound)
      return true;
    const Loop *inner = nullptr;
    for (const Loop *sub : L->getSubLoops())
      if (sub->contains(at->getParent()))
        inner = sub;
    L = inner;
  }
  return false;
}

// cq-nzlq (owner ruling 2026-11-02): an integer division or remainder is the classical arithmetic that
// traps (llvm::isSafeToSpeculativelyExecute is false for it unless the divisor is a constant other than
// 0 and, signed, -1). Copied where C may not run it, it gets a safe divisor: 1 wherever the divisor is 0
// or, signed, the pair is MIN / -1. On every input where C executes it the operands are outside that set
// (else the input has undefined behaviour and is outside the domain), so the value is C's; elsewhere the
// value is never selected into state. Vectors are guarded lane-wise the same way.
void guardSpeculated(LoweringContext &ctx, Instruction *n) {
  unsigned op = n->getOpcode();
  if (op != Instruction::UDiv && op != Instruction::URem && op != Instruction::SDiv && op != Instruction::SRem)
    return;
  if (isSafeToSpeculativelyExecute(n) || !speculated(ctx))
    return;
  IRBuilder<> &B = ctx.B();
  Value *a = n->getOperand(0), *d = n->getOperand(1);
  Type *T = d->getType();
  Value *bad = B.CreateICmpEQ(d, Constant::getNullValue(T), "cq.div0");
  auto *ca = dyn_cast<ConstantInt>(a);
  if ((op == Instruction::SDiv || op == Instruction::SRem) && !(ca && !ca->getValue().isMinSignedValue())) {
    unsigned w = T->getScalarSizeInBits();
    Value *ovf = B.CreateAnd(B.CreateICmpEQ(a, ConstantInt::get(T, APInt::getSignedMinValue(w))),
                             B.CreateICmpEQ(d, Constant::getAllOnesValue(T)), "cq.divovf");
    bad = B.CreateOr(bad, ovf);
  }
  n->setOperand(1, B.CreateSelect(bad, ConstantInt::get(T, 1), d, "cq.safediv"));
}

} // namespace

Instruction *copyClassical(LoweringContext &ctx, Instruction &I) {
  if (isa<PHINode>(I) || I.isTerminator())
    internalError("spine: copyClassical of a phi or terminator (the walker's)", &I);
  Instruction *n = I.clone();
  for (unsigned i = 0; i < n->getNumOperands(); ++i) {
    Value *v = I.getOperand(i);
    if (isa<BasicBlock>(v) || isa<MetadataAsValue>(v))
      continue;
    Operand op = ctx.operand(v);
    if (op.handle)
      internalError("spine: a rail handle reaching a classical instruction", &I);
    n->setOperand(i, op.v);
  }
  guardSpeculated(ctx, n);
  if (!I.getName().empty())
    n->setName(I.getName());
  ctx.B().Insert(n);
  return n;
}

void dispatch(LoweringContext &ctx, Instruction &I) {
  if (isa<DbgInfoIntrinsic>(I))
    return;   // debug records carry no semantics; the original values they name are gone
  if (auto *CB = dyn_cast<CallBase>(&I)) {
    if (isa<InvokeInst>(CB) || isa<CallBrInst>(CB))
      unimplemented("spine: invoke/callbr", &I);
    return lowerCall(ctx, *CB);
  }
  if (isa<PHINode>(I) || I.isTerminator())
    internalError("spine: dispatch of a phi or terminator (the walker's)", &I);

  bool q = (!I.getType()->isVoidTy() && isQ(ctx, &I)) || anyQuantumOperand(ctx, I);
  bool vec = I.getType()->isVectorTy();
  for (const Use &u : I.operands())
    vec |= u->getType()->isVectorTy();

  switch (I.getOpcode()) {
  case Instruction::Alloca: {
    ObjClass c = objectsClass(ctx, &I);
    if (c == ObjClass::Slot)
      return mem::allocateSlots(ctx, I);
    if (c == ObjClass::Qram)
      return mem::allocateQram(ctx, I);
    bindOperand(ctx, &I, Operand{copyClassical(ctx, I), false});
    return;
  }
  case Instruction::Load:
  case Instruction::Store:
    if (q || involvesNonClassicalMemory(ctx, I.getOperand(isa<StoreInst>(I) ? 1 : 0)) ||
        cast<Instruction>(I).isAtomic() ||
        (isa<LoadInst>(I) && ctx.T.offsetKind(&I, ctx.S) == OffsetKind::Quantum))
      return lowerMemoryAccess(ctx, I);
    if (isa<LoadInst>(I) && cast<LoadInst>(I).isVolatile())
      return conc::lowerVolatile(ctx, I);
    if (isa<StoreInst>(I) && cast<StoreInst>(I).isVolatile())
      return conc::lowerVolatile(ctx, I);
    if (isa<StoreInst>(I)) {
      copyClassical(ctx, I);
    } else {
      bindOperand(ctx, &I, Operand{copyClassical(ctx, I), false});
    }
    return;
  case Instruction::ZExt:
  case Instruction::SExt:
    if (q && onlyAddressIndex(I))
      return;
    break;
  case Instruction::GetElementPtr:
  case Instruction::AddrSpaceCast:
    // Address arithmetic into a slot or QRAM object, or with a quantum index, is never emitted:
    // the access re-derives the cell index (rules 20, 21). Classical address arithmetic is copied.
    if (q || involvesNonClassicalMemory(ctx, &I))
      return;
    bindOperand(ctx, &I, Operand{copyClassical(ctx, I), false});
    return;
  case Instruction::PtrToInt:
    if (q || ctx.T.isFatPointer(I.getOperand(0), ctx.S))
      return fatptr::lowerPtrToInt(ctx, I);
    break;
  case Instruction::IntToPtr:
    if (q || ctx.T.isFatPointer(&I, ctx.S))
      return fatptr::lowerIntToPtr(ctx, I);
    break;
  case Instruction::ExtractValue:
    if (q)
      return aggr::lowerExtractValue(ctx, cast<ExtractValueInst>(I));
    break;
  case Instruction::InsertValue:
    if (q)
      return aggr::lowerInsertValue(ctx, cast<InsertValueInst>(I));
    break;
  case Instruction::AtomicRMW:
  case Instruction::AtomicCmpXchg:
    if (q || involvesNonClassicalMemory(ctx, I.getOperand(0)))
      return conc::lowerAtomic(ctx, I);
    break;
  case Instruction::Fence:
    break;   // single-thread collapse keeps a classical fence as it is (rule 24)
  case Instruction::VAArg:
    if (q)
      return calls::lowerVarargs(ctx, I);
    break;
  case Instruction::Select:
    if (q) {
      auto &sel = cast<SelectInst>(I);
      // Rule 21 (cq-xb7r): a quantum pointer select is a fat pointer (tag, idx), whether its tag is
      // quantum (two objects) or classical (one object at a quantum offset); fatptr computes and binds
      // its two fields here, at the select, so their rails are live wherever the pointer is used.
      if (sel.getType()->isPointerTy()) {
        fatptr::lower(ctx, &sel);
        return;
      }
      if (onlyFactoredConditions(ctx, I))
        return;
      // A classical condition with a quantum arm: pred's lowerSelect emits a classical select over
      // the handles (rule 9 at a58c3a4).
      if (!isQ(ctx, sel.getCondition()) && lowerLogicalSelect(ctx, sel))
        return;
      bindOperand(ctx, &I, Operand{lowerSelect(ctx, sel), true});
      return;
    }
    break;
  case Instruction::And:
  case Instruction::Or:
  case Instruction::Xor:
    if (q && onlyFactoredConditions(ctx, I))
      return;
    break;
  case Instruction::ICmp:
    if (q && I.getOperand(0)->getType()->isPointerTy()) {
      bindOperand(ctx, &I, Operand{fatptr::lowerCompare(ctx, cast<ICmpInst>(I)), true});
      return;
    }
    break;
  case Instruction::LandingPad:
  case Instruction::CleanupPad:
  case Instruction::CatchPad:
    unimplemented("spine: exception handling pads", &I);
  default:
    break;
  }

  if (q && vec)
    return aggr::lowerVectorOp(ctx, I);
  if (q && lowerNarrow(ctx, I))
    return;   // rule 3: a view of a narrow register (Views.cpp, cq-su3p)
  if (q)
    return lowerOpcode(ctx, I);
  Instruction *n = copyClassical(ctx, I);
  if (!I.getType()->isVoidTy())
    bindOperand(ctx, &I, Operand{n, false});
}

} // namespace cq::spine

namespace cq {

void lowerInstruction(LoweringContext &ctx, Instruction &I) { lowerInstruction(ctx, I, nullptr); }

void lowerConditionAsData(LoweringContext &ctx, Instruction &I) {
  if (!I.getType()->isIntegerTy(1) || !spine::isQ(ctx, &I))
    internalError("spine: lowerConditionAsData of a value that is not a quantum i1", &I);
  spine::Shared &sh = spine::shared(ctx);
  bool saved = sh.conditionAsData;
  sh.conditionAsData = true;
  lowerInstruction(ctx, I, nullptr);
  sh.conditionAsData = saved;
}

void lowerInstruction(LoweringContext &ctx, Instruction &I, Value *tripFlag) {
  if (isa<PHINode>(I) || I.isTerminator())
    internalError("spine: lowerInstruction of a phi or terminator", &I);
  if (tripFlag && !tripFlag->getType()->isIntegerTy(32))
    internalError("spine: lowerInstruction under a trip flag that is not a rail handle", tripFlag);
  spine::Shared &sh = spine::shared(ctx);
  const Instruction *savedCur = sh.cur;
  std::optional<Pred> savedPred = sh.curPred;
  Value *savedTrip = sh.tripFlag, *savedConj = sh.tripConj;
  sh.cur = &I;
  sh.curPred = ctx.preds().block(I.getParent()).quantumPart(ctx.T, ctx.S);
  sh.tripFlag = tripFlag;
  sh.tripConj = nullptr;
  // cq-lx8f: an unrolled trip re-lowers the body, so I may already be bound (to the previous trip's
  // rails). The new lowering replaces that binding; the old rails stay recorded in Uncompute (records
  // are keyed by rail, not by original value) and are torn down by the spine like any other.
  sh.binds.erase(&I);
  spine::dispatch(ctx, I);
  sh.cur = savedCur;
  sh.curPred = savedPred;
  sh.tripFlag = savedTrip;
  sh.tripConj = savedConj;
}

} // namespace cq

namespace cq::spine {

void lowerInline(LoweringContext &ctx, CallBase &CB, const Specialization &callee) {
  Function &F = *callee.F;
  if (F.size() != 1 || !isa<ReturnInst>(F.getEntryBlock().getTerminator()))
    unimplemented("spine: rule 19 inline of a callee with more than one block", &CB);
  if (!ctx.currentPredicate().isTop() || shared(ctx).tripFlag)
    unimplemented("spine: rule 19 inline under a quantum predicate", &CB);
  Shared &sh = shared(ctx);
  std::unique_ptr<LoweringContext> child = childContext(ctx, callee);
  for (unsigned i = 0; i < F.arg_size(); ++i)
    bindOperand(*child, F.getArg(i), ctx.operand(CB.getArgOperand(i)));
  sh.inlineStack.push_back(&CB);
  const Instruction *saved = sh.cur;
  for (Instruction &I : F.getEntryBlock()) {
    if (auto *ret = dyn_cast<ReturnInst>(&I)) {
      Value *rv = ret->getReturnValue();
      if (!rv)
        internalError("spine: rule 19 inline of a void callee", &CB);
      sh.cur = &I;
      Operand r = child->operand(rv);
      sh.inlineStack.pop_back();
      sh.cur = saved;
      // The callee's values are bound per inlined call: drop them so a second call site rebinds.
      for (Argument &a : F.args())
        sh.binds.erase(&a);
      for (Instruction &J : F.getEntryBlock())
        sh.binds.erase(&J);
      bindOperand(ctx, &CB, r);
      return;
    }
    sh.cur = &I;
    dispatch(*child, I);
  }
  internalError("spine: rule 19 inline: callee block has no return", &CB);
}

} // namespace cq::spine
