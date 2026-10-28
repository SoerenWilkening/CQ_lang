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
#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::spine {

namespace {

bool involvesNonClassicalMemory(LoweringContext &ctx, const Value *ptr) {
  if (!ptr->getType()->isPointerTy())
    return false;
  if (ctx.T.isFatPointer(ptr, ctx.S))
    return true;
  for (ObjectId o : ctx.T.provenance(ptr, ctx.S))
    if (ctx.T.classOf(o) != ObjClass::Classical)
      return true;
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
  if (!I.getType()->isIntegerTy(1) || I.use_empty())
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

void lowerMemoryAccess(LoweringContext &ctx, Instruction &I) {
  if (auto *ld = dyn_cast<LoadInst>(&I)) {
    if (ld->isVolatile() || ld->isAtomic()) {
      if (ld->isAtomic())
        conc::lowerAtomic(ctx, I);
      else
        conc::lowerVolatile(ctx, I);
      return;
    }
    const Value *p = ld->getPointerOperand();
    if (ctx.T.isFatPointer(p, ctx.S))
      return fatptr::lowerLoad(ctx, *ld);
    bool qram = false, slot = false;
    for (ObjectId o : ctx.T.provenance(p, ctx.S)) {
      qram |= ctx.T.classOf(o) == ObjClass::Qram;
      slot |= ctx.T.classOf(o) == ObjClass::Slot;
    }
    if (qram)
      return mem::lowerQramLoad(ctx, *ld);
    if (slot)
      return mem::lowerSlotLoad(ctx, *ld);
    if (ctx.T.offsetKind(ld, ctx.S) == OffsetKind::Quantum)
      return mem::lowerQromLoad(ctx, *ld);
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
  const Value *p = st->getPointerOperand();
  if (ctx.T.isFatPointer(p, ctx.S))
    return fatptr::lowerStore(ctx, *st);
  bool qram = false, slot = false;
  for (ObjectId o : ctx.T.provenance(p, ctx.S)) {
    qram |= ctx.T.classOf(o) == ObjClass::Qram;
    slot |= ctx.T.classOf(o) == ObjClass::Slot;
  }
  if (qram)
    return mem::lowerQramStore(ctx, *st);
  if (slot)
    return mem::lowerSlotStore(ctx, *st);
  if (isQ(ctx, st->getValueOperand()))
    internalError("spine: a quantum value stored into memory taint classified Classical", st);
  copyClassical(ctx, I);
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
    if (isQ(ctx, CI->getArgOperand(1)))
      return rot::lowerQuantumAngleTheta(ctx, *CI, ctx.currentFlag());   // rules 11, 15
    if (Value *flag = ctx.currentFlag()) {
      shared(ctx).statePreps.insert(CI);                                  // a merge of it: cq-gtcn
      return rot::lowerControlledTheta(ctx, *CI, flag);                   // rule 10
    }
    return lowerTheta(ctx, *CI);                                         // rule 2
  }
  case Class::Measure:
    if (!CI)
      internalError("spine: cq_measure through invoke", &CB);
    return lowerMeasure(ctx, *CI);
  case Class::Phi:
    if (!CI)
      internalError("spine: cq_phi through invoke", &CB);
    if (isQ(ctx, CI->getArgOperand(0)))
      return rot::lowerQuantumAnglePhase(ctx, *CI, ctx.currentFlag());   // rule 15
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
    return calls::lowerLifted(ctx, CB);
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
    unimplemented("spine: realloc of a slot or QRAM block has no entry in Memory.h (rule 16)", &CB);
  case Class::MemIntrinsic: return mem::lowerMemIntrinsic(ctx, cast<MemIntrinsic>(CB));
  case Class::TemplateIntrinsic: return lowerOpcode(ctx, CB);
  case Class::LibmIntrinsic: return calls::lowerLifted(ctx, CB);
  case Class::Fenv:
    if (isa<ConstrainedFPIntrinsic>(CB))
      return fenv::lowerConstrained(ctx, CB);
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
  if (q)
    return lowerOpcode(ctx, I);
  Instruction *n = copyClassical(ctx, I);
  if (!I.getType()->isVoidTy())
    bindOperand(ctx, &I, Operand{n, false});
}

void lowerInline(LoweringContext &ctx, CallBase &CB, const Specialization &callee) {
  Function &F = *callee.F;
  if (F.size() != 1 || !isa<ReturnInst>(F.getEntryBlock().getTerminator()))
    unimplemented("spine: rule 19 inline of a callee with more than one block", &CB);
  if (!ctx.currentPredicate().isTop())
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
