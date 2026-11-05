// Module spine (cq-w0-construct): the per-instruction dispatch of construct() (cq-arch table).
//
// Classical instructions are copied with their operands remapped. Every other instruction goes to
// the module the cq-arch dispatch table names; this file decides only which. Terminators and phis of
// the walked function belong to the walker (Construct.cpp).
#include "SpineInternal.h"

#include "cq/Abi.h"
#include "cq/Aggregates.h"
#include "cq/Effects.h"
#include "cq/Bus.h"
#include "cq/Rotation.h"
#include "cq/Switch.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "cq/Loops.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::spine {

namespace {

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

// Rule 20: a load or store. A host-resident object with no quantum predicate in scope keeps the plain instruction;
// every other access is the bus (rule 5). Volatile is rule 24's.
void lowerMemoryAccess(LoweringContext &ctx, Instruction &I) {
  if (auto *ld = dyn_cast<LoadInst>(&I)) {
    if (ld->isVolatile())
      return conc::lowerVolatile(ctx, I);
    if (bus::hostAccess(ctx, I)) {
      if (isQ(ctx, ld))
        internalError("spine: a load of a host-resident object that taint calls quantum", ld);
      bindOperand(ctx, ld, Operand{copyClassical(ctx, I), false});
      return;
    }
    return bus::lowerLoad(ctx, *ld);
  }
  auto *st = cast<StoreInst>(&I);
  if (st->isVolatile())
    return conc::lowerVolatile(ctx, I);
  if (bus::hostAccess(ctx, I) && !isQ(ctx, st->getValueOperand())) {
    copyClassical(ctx, I);
    return;
  }
  bus::lowerStore(ctx, *st);
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

// cq-5n3n (CR rule 17 with rule 5): a region inverts only its own gates. A rail the region computed is
// uncomputed inside it, before the end marker (its compute/uncompute pair reverses into itself), and an
// original value read after the end (a later instruction, or a quantum branch whose arms run on past the
// end: its condition is an atom of later predicates) is recomputed right after the end from its operands
// (pure instructions only: arithmetic, comparisons, casts, selects, freeze). A value that cannot be
// recomputed keeps its rail past the end, as before.
bool recomputable(const Instruction *I) {
  return isa<BinaryOperator>(I) || isa<CmpInst>(I) || isa<CastInst>(I) || isa<SelectInst>(I) || isa<FreezeInst>(I) ||
         isa<UnaryOperator>(I);
}

void closeRegionRails(LoweringContext &ctx, CallInst &origEnd) {
  IRBuilder<> &B = ctx.B();
  if (B.GetInsertPoint() == B.GetInsertBlock()->begin())
    internalError("spine: no cqrt_invert_end before the builder", &origEnd);
  Instruction *endCall = &*std::prev(B.GetInsertPoint());
  Shared &sh = shared(ctx);
  // handle -> the original values bound to it
  DenseMap<const Value *, SmallVector<const Value *, 2>> origOf;
  for (auto &[orig, ops] : sh.binds)
    for (const Operand &o : ops)
      if (o.handle)
        origOf[o.v].push_back(orig);
  const Function &F = *origEnd.getFunction();
  PostDominatorTree PDT(const_cast<Function &>(F));
  auto liveAfter = [&](const Value *V) {
    for (const User *u : V->users()) {
      auto *U = dyn_cast<Instruction>(u);
      if (!U || U->getFunction() != &F)
        continue;
      if (U->isTerminator()) {
        // A branch whose arms run on past the end (the end lies in one of them): its condition is an atom
        // of the predicates after the end. One whose arms join before the end is read no more.
        if (isPotentiallyReachable(&origEnd, U))
          return true;   // a branch after the end
        if (isPotentiallyReachable(U, &origEnd) && !PDT.dominates(origEnd.getParent(), U->getParent()))
          return true;
        continue;
      }
      if (auto *P = dyn_cast<PHINode>(U)) {
        for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
          if (P->getIncomingValue(i) == V && isPotentiallyReachable(&origEnd, P->getIncomingBlock(i)->getTerminator()))
            return true;
        continue;
      }
      if (U != &origEnd && isPotentiallyReachable(&origEnd, U))
        return true;
    }
    return false;
  };
  // Kept past the end: a value read after it that is no pure instruction, and every such value a pure one
  // read after it is computed from (the recomputation reads it).
  SmallPtrSet<const Value *, 16> keepSet, seen;
  std::function<void(const Value *)> operandsOf = [&](const Value *V) {
    auto *I = dyn_cast<Instruction>(V);
    if (!I || I->getFunction() != &F || !seen.insert(I).second)
      return;
    if (!recomputable(I)) {
      keepSet.insert(I);
      return;
    }
    for (const Use &u : I->operands())
      operandsOf(u.get());
  };
  for (auto &[orig, ops] : sh.binds)
    if (liveAfter(orig))
      operandsOf(orig);
  auto keep = [&](Value *h) {
    auto it = origOf.find(h);
    if (it == origOf.end())
      return false;   // a rail of the lowering's own (a flag, a scratch): pred makes flags afresh where read
    return any_of(it->second, [&](const Value *V) { return keepSet.count(V) != 0; });
  };
  SmallVector<Value *, 8> resolved = ctx.unc().resolveRegionMade(endCall, keep);
  if (resolved.empty())
    return;
  SmallPtrSet<const Value *, 8> gone;
  for (Value *h : resolved)
    if (auto it = origOf.find(h); it != origOf.end())
      for (const Value *V : it->second)
        gone.insert(V);
  SetVector<Instruction *> redo;
  std::function<void(const Value *)> need = [&](const Value *V) {
    auto *I = const_cast<Instruction *>(dyn_cast<Instruction>(V));
    if (!I || !gone.count(I) || redo.count(I))
      return;
    if (!recomputable(I))
      internalError("spine: a region-made rail a later reader needs that is no pure instruction", I);
    for (const Use &u : I->operands())
      need(u.get());
    redo.insert(I);
  };
  for (const Value *V : gone)
    if (liveAfter(V))
      need(V);
  for (Instruction *I : redo)   // operands first (need inserts them first)
    lowerInstruction(ctx, *I);
}

void lowerCall(LoweringContext &ctx, CallBase &CB) {
  using calls::Class;
  Class c = calls::classify(CB, ctx.T, ctx.S);
  // CR rule 14 "No live exit" (ruling 2026-11-02): a noreturn arm of a K-loop runs per trip under that
  // trip's exit flag (loops-cutoff), a quantum predicate taint's control dependence does not see (the arm
  // may post-dominate the loop). A bodiless noreturn callee there is rule 16's abort_i1 on the flag.
  if (c == Class::Classical && shared(ctx).tripFlag && CB.doesNotReturn() && !CB.hasFnAttr(Attribute::ReturnsTwice))
    if (auto *G = dyn_cast<Function>(CB.getCalledOperand()->stripPointerCasts());
        G && G->isDeclaration() && !G->getName().ends_with("longjmp"))
      c = Class::Noreturn;
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
  {
    if (!CI)
      internalError("spine: a cq_invert marker through invoke", &CB);
    // Rule 17 (2026-11-02, cq-asfn): a marker is a host call executed on every path, at its position in
    // the lowered code; in a quantum arm (or a K-loop trip) the region then holds the arm's controlled
    // gates. A match outside the arm was made a per-depth split of the tail before the final taint
    // (eff-invert splitMarkerPaths).
    invert::lowerMarker(ctx, *CI);   // rule 17: the run-time pair (§1.3)
    if (c == Class::InvertEnd)
      closeRegionRails(ctx, *CI);
    return;
  }
  case Class::Lift: {
    // Rules 18 and 19: the compiler never inlines (cq-i9wk). A callee reached with a quantum argument is
    // a clone; one reached with none is called as it is (calls::lowerLifted).
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
    if (invert::isMarkerFence(CB))
      return;   // rule 17: CQ.h's fence beside a cq_invert marker is consumed
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
    // Rule 20 Allocation: a bus-resident object's lifetime markers are dropped.
    if (auto *II = dyn_cast<IntrinsicInst>(&CB); II && II->getIntrinsicID() == Intrinsic::lifetime_start)
      return;
    return bus::lowerAlloc(ctx, CB);
  case Class::Dealloc:
    return;   // rule 16: `free` and a bus-resident object's end of lifetime are nothing
  case Class::Realloc:
    return bus::lowerRealloc(ctx, CB);
  case Class::MemIntrinsic:
    return bus::lowerMemIntrinsic(ctx, cast<MemIntrinsic>(CB));
  case Class::TemplateIntrinsic:
    if (isa<ConstrainedFPIntrinsic>(CB))
      return fenv::lowerConstrained(ctx, CB);   // a non-raising constrained op: the template in its chain's mode
    if (CB.getType()->isVectorTy() || any_of(CB.args(), [](const Use &u) { return u->getType()->isVectorTy(); }))
      return aggr::lowerVectorOp(ctx, CB);   // rule 25: a vector is its lanes
    return lowerOpcode(ctx, CB);
  case Class::LibmIntrinsic: return calls::lowerLifted(ctx, CB);
  case Class::Fenv:
    if (isa<ConstrainedFPIntrinsic>(CB))
      return fenv::lowerConstrained(ctx, CB);
    if (isa<IntrinsicInst>(CB))
      internalError("spine: llvm.get.rounding / llvm.set.rounding in a lowered function (the plugin rewrites them "
                    "as fegetround / fesetround before the final taint, rule 23)",
                    &CB);
    return fenv::lowerFenvCall(ctx, CB);
  case Class::Thread: return conc::lowerThreadCall(ctx, CB);
  case Class::Setjmp: return conc::lowerSetjmp(ctx, CB);
  case Class::Longjmp: return conc::lowerLongjmp(ctx, CB);
  case Class::Varargs: return calls::lowerVarargs(ctx, CB);
  case Class::Atomic: return bus::lowerAtomic(ctx, CB);
  }
  internalError("spine: unknown call class", &CB);
}

} // namespace


namespace {



} // namespace


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
  const Instruction *at = sh.cur;
  if (at->getFunction() != U->getHeader()->getParent())
    internalError("spine: the current instruction is outside its loop unit's function", sh.cur);
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


namespace {
void dispatchOne(LoweringContext &ctx, Instruction &I);
}

// Rule 5 Memory: an original instruction that is a memory version change notes the first instruction its lowering
// emitted (a load copy un-copied before that point precedes the change).
void dispatch(LoweringContext &ctx, Instruction &I) {
  if (bus::inPlaceBefore(ctx, I))
    return;   // rule 5: the form is emitted at its store
  IRBuilder<> &B = ctx.B();
  BasicBlock *bb = B.GetInsertBlock();
  Instruction *prev = B.GetInsertPoint() == bb->begin() ? nullptr : &*std::prev(B.GetInsertPoint());
  dispatchOne(ctx, I);
  bus::inPlaceAfter(ctx, I);
  if (!bus::versionChange(ctx, I) || bus::notesOwnChange(ctx, I))
    return;
  // Where its code begins, also when the lowering branched away from bb. Nothing emitted: nothing changed.
  Instruction *first = prev ? prev->getNextNode() : bb->empty() ? nullptr : &bb->front();
  if (first)
    ctx.unc().noteVersionChange(first);
}

namespace {
void dispatchOne(LoweringContext &ctx, Instruction &I) {
  if (isa<DbgInfoIntrinsic>(I))
    return;   // debug records carry no semantics; the original values they name are gone
  if (auto *CB = dyn_cast<CallBase>(&I)) {
    if (isa<InvokeInst>(CB) || isa<CallBrInst>(CB))   // terminators: the walker's (emitTerminator)
      internalError("spine: dispatch of an invoke or callbr", &I);
    return lowerCall(ctx, *CB);
  }
  if (isa<PHINode>(I) || I.isTerminator())
    internalError("spine: dispatch of a phi or terminator (the walker's)", &I);

  bool q = (!I.getType()->isVoidTy() && isQ(ctx, &I)) || anyQuantumOperand(ctx, I);
  bool vec = I.getType()->isVectorTy();
  for (const Use &u : I.operands())
    vec |= u->getType()->isVectorTy();

  switch (I.getOpcode()) {
  case Instruction::Alloca:
    if (!ctx.T.hostResident(&I, ctx.S))
      return bus::lowerAlloc(ctx, I);
    bindOperand(ctx, &I, Operand{copyClassical(ctx, I), false});
    return;
  case Instruction::Load:
  case Instruction::Store:
    if (cast<Instruction>(I).isAtomic() && !isa<LoadInst>(I) && !isa<StoreInst>(I))
      internalError("spine: an atomic access that is neither a load nor a store here", &I);
    return lowerMemoryAccess(ctx, I);
  case Instruction::GetElementPtr:
  case Instruction::AddrSpaceCast:
    // Rule 20 Address arithmetic: with nothing tainted the getelementptr stays (a rail measured before it: rule 2).
    if (q && any_of(I.operands(), [&](const Use &u) { return ctx.operand(u.get()).handle; })) {
      bindOperand(ctx, &I, bus::address(ctx, &I));
      return;
    }
    bindOperand(ctx, &I, Operand{copyClassical(ctx, I), false});
    return;
  case Instruction::PtrToInt:
  case Instruction::IntToPtr:
    // Rule 21: identities at 64 bits (to or from another width the trunc/zext template).
    if (q && !vec && ctx.operand(I.getOperand(0)).handle &&
        (isa<PtrToIntInst>(I) ? I.getType() : I.getOperand(0)->getType())->isIntegerTy(64)) {
      bindOperand(ctx, &I, ctx.operand(I.getOperand(0)));
      return;
    }
    if (q && !ctx.operand(I.getOperand(0)).handle) {
      bindOperand(ctx, &I, Operand{copyClassical(ctx, I), false});
      return;
    }
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
    return bus::lowerAtomic(ctx, I);
  case Instruction::Fence:
    break;   // single-thread collapse keeps a classical fence as it is (rule 24)
  case Instruction::VAArg:
    if (q)
      return calls::lowerVarargs(ctx, I);
    break;
  case Instruction::Select:
    if (q) {
      auto &sel = cast<SelectInst>(I);
      // Rules 25, 26 (cq-oa67): a vector, struct or array select merges lane by lane / field by field.
      if (sel.getType()->isVectorTy() || sel.getType()->isAggregateType())
        return aggr::lowerVectorOp(ctx, I);
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
  case Instruction::LandingPad:
  case Instruction::CleanupPad:
  case Instruction::CatchPad:
    internalError("spine: an exception handling pad (landingpad, cleanuppad, catchpad): IR the pinned "
                  "pipeline cannot emit (CR §0, rule 25)",
                  &I);
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
} // namespace

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
