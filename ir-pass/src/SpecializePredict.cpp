// SpecializePredict.cpp — the return-taint predictor declared in
// SpecializeClone.h (`predictReturnTainted`, `specCallResultPredictedClassical`).
// Split out of SpecializeClone.cpp in review round 3 of bd r2j3.19 (2026-10-08,
// <= 400 lines), unchanged in substance.
#include "SpecializeClone.h"

#include "CalleeBody.h"  // calleeBodyTrusted (bd p3kd.2)
#include "SpecializePlan.h"
#include "TaintPropagation.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

// bd 3c6m.54 — the RETURN-taint predictor: does the callee's return value
// derive from a masked-tainted parameter? A forward closure from the masked
// params that, since bd r2j3.19, leaves an inner lift site predicted classical
// untainted, exactly as the clone's seed (`propagateFromParams`) does; plus
// clause (a): any tainted conditional terminator predicts "tainted".
//
// THE INVARIANT (review round 2 F1): `predict == false` ⟹ the built clone
// returns a classical value. The clone's taint equals this closure before main's
// control chain runs (same site predicate, no theta/phi/measure roots). Growth
// after that needs a tainted deciding terminator (the settle step's
// `LaterTaintOracle`, the chain's merge %outs), which clause (a) already counts.
// The one growth clause (a) does not mirror (a phi with no immediate dominator,
// i.e. unreachable) ends loudly: the scrub and the clone fence, or
// `kMsgPredictedClassicalQuantum`. `predict == true` may still build a classical
// clone (an empty tainted diamond the flatten removes, bd dt0r): the scrub, the
// l3oi fence and `buildClone`'s fp mispredict guards make that loud too.
namespace {

// The would-be Phase-6 site SHAPE the prediction is asked about (bd cepm), apart
// from the taint representation (`specCallResultPredictedClassical` below adds the
// front-end-intrinsic membership and the mask). One spelling (R12), shared with the
// recursive predictor. Every conjunct narrows (the safe direction).
bool isPredictableSpecSite(const CallInst &CI) {
  Function *Callee = CI.getCalledFunction();
  // `Execute` (bd p3kd.2, CalleeBody.h): the prediction is about the body that
  // runs at a site that is specialized (retargeted to its clone) or declined, so
  // it asks exactly what `scanBody` asks of a TOP callee; a derefinable ODR body
  // is admitted by both or by neither.
  if (!Callee || Callee->isIntrinsic() ||
      !calleeBodyTrusted(Callee, CalleeBodyUse::Execute) || Callee->isVarArg())
    return false;
  if (CI.getType()->isVoidTy() ||
      CI.getFunctionType() != Callee->getFunctionType() ||
      Callee->arg_size() > kSpecMaxArity)
    return false;
  const StringRef N = Callee->getName();
  return !N.starts_with("cq_") && !N.starts_with("__cq_") &&
         !N.starts_with("cqrt_");
}

using PredictMemo = DenseMap<std::pair<const Function *, SpecMask>, bool>;

bool predictReturnTaintedImpl(Function *Callee, SpecMask Mask,
                              SmallPtrSetImpl<const Function *> &OnStack,
                              PredictMemo &Memo) {
  if (auto It = Memo.find({Callee, Mask}); It != Memo.end())
    return It->second;
  // A call-graph cycle: no inner verdict to ask, so its result stays tainted (the
  // over-approximation every caller tolerates). Not memoised (bd r2j3.19).
  if (!OnStack.insert(Callee).second)
    return true;
  const bool R = [&] {
  // Collect the return value(s). Pre-5po2-I1 this read ONLY the entry-block
  // terminator (a single-block callee, guaranteed by `scanBody`). I1 accepts a
  // MULTI-BLOCK value diamond whose `ret` lives in the exit/merge block, NOT the
  // entry terminator (a `br`) — reading the entry terminator alone under-predicts
  // "classical", so `cloneFor` would keep an fp return type while `emitBennettWrap`
  // copies out to an i32 handle: a mistyped `ret` (broken module). Scan ALL blocks
  // and OVER-approximate: predict tainted if ANY reachable return value derives
  // from a masked param. Soundness is one-directional — an over-prediction is
  // caught by the loud mispredict guard in `buildClone`; an UNDER-prediction is
  // the broken module. A single-block callee's entry `ret` is found first, so its
  // result is byte-identical to the pre-I1 behavior.
  SmallPtrSet<Value *, 16> Tainted;
  std::vector<Value *> WL;
  for (Argument &A : Callee->args())
    if ((Mask & (SpecMask(1) << A.getArgNo())) && Tainted.insert(&A).second)
      WL.push_back(&A);
  while (!WL.empty()) {
    Value *V = WL.back();
    WL.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || I->getFunction() != Callee)
        continue;
      // bd r2j3.19 — an INNER lift site whose own callee is predicted to return
      // a classical value leaves its result classical, exactly as
      // `specCallResultPredictedClassical` leaves it in the clone's taint
      // (`propagateFromParams`). Not marked visited: a later tainted argument
      // reaches the call again and re-asks with the grown mask (monotone).
      if (auto *CI = dyn_cast<CallInst>(I); CI && isPredictableSpecSite(*CI)) {
        SpecMask InnerMask = 0;
        for (unsigned A = 0, E = CI->arg_size(); A < E && A < kSpecMaxArity; ++A)
          if (Tainted.count(CI->getArgOperand(A)))
            InnerMask |= SpecMask(1) << A;
        if (InnerMask && !predictReturnTaintedImpl(CI->getCalledFunction(),
                                                   InnerMask, OnStack, Memo))
          continue;
      }
      if (Tainted.insert(I).second)
        WL.push_back(I);
    }
  }
  // (a) 5po2 I2 (Rule-13 CONFIRMED-finding fix): a return that is CONTROL-DEPENDENT
  //     on a tainted branch — e.g. a CONSTANT returned only on `if(q>C) return K`, or
  //     a merge-phi of constants under a tainted diamond — becomes a TAINTED data-mux
  //     out rail in the clone's select lowering, even though the constant itself is not
  //     param-derived (a constant / const-phi is not a param user, so the forward
  //     closure above never reaches it). UNDER-predicting classical made `cloneFor`
  //     keep the fp return type while that lowering minted an i32 handle → a
  //     mistyped `ret` (a verify-DIRTY / broken module, exit 134). Over-approximate:
  //     if ANY conditional terminator is tainted (a tainted-controlled diamond),
  //     predict the return tainted. SOUND one-directional — an OVER-prediction is
  //     caught by the `buildClone` fp-mispredict guards (a clean decline); an
  //     UNDER-prediction is the broken module. ⚠ "Affects ONLY the fp-return
  //     rewrite … inert for an int/void return" stood here and is FALSE since bd
  //     cepm: `specCallResultPredictedClassical` (below) asks this for EVERY
  //     would-be Phase-6 site at propagation, whatever its return type, and a
  //     `false` there leaves the call's RESULT classical. An UNDER-prediction
  //     there is caught by `specialize()`'s `kMsgPredictedClassicalQuantum`
  //     check (a loud decline, never a silent one); an over-prediction there is
  //     the pre-cepm conservative taint (the scrub + bd l3oi's fence).
  for (BasicBlock &BB : *Callee) {
    const Instruction *T = BB.getTerminator();
    if (const auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() && Tainted.count(BI->getCondition()))
        return true;
    } else if (const auto *SW = dyn_cast<SwitchInst>(T)) {
      if (Tainted.count(SW->getCondition()))
        return true;
    }
  }
  // (b) the param-derived return (the pre-I2 single-block / straight-line case). A
  //     constant RV is never in `Tainted`, so the `!isa<Constant>` filter is
  //     subsumed by the membership test.
  for (BasicBlock &BB : *Callee)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (Value *RV = R->getReturnValue(); RV && Tainted.count(RV))
        return true;
  return false;
  }();
  OnStack.erase(Callee);
  Memo[{Callee, Mask}] = R;
  return R;
}

}  // namespace

bool predictReturnTainted(Function *Callee, SpecMask Mask) {
  SmallPtrSet<const Function *, 8> OnStack;
  PredictMemo Memo;
  return predictReturnTaintedImpl(Callee, Mask, OnStack, Memo);
}


// bd `test_C_libtooling-cepm` / bd `test_C_libtooling-3zr4` — see SpecializeClone.h
// for the contract and the two backstops. Every conjunct below narrows the set of
// calls the prediction is asked about (a false return keeps today's conservative
// taint), so each is the SAFE direction on its own:
//   * a DIRECT `CallInst` to a LIFTABLE (`calleeBodyTrusted(…, Execute)`: exact, or
//     ODR-derefinable and not interposable — bd p3kd.2), non-intrinsic, non-variadic
//     DEFINITION, called
//     with the callee's own function type and of arity ≤ `kSpecMaxArity` — the
//     candidate shape `detectSpecializations` / `scanBody` accept (an invoke, an
//     indirect call, a declaration, an interposable body, a vararg tail — whose
//     argument `taintArgMask` would count and `predictReturnTainted` would not see
//     — and a 65th parameter the mask cannot hold all keep their taint);
//   * a non-VOID result (a void call carries no value; tainting it is today's
//     behaviour and nothing reads it);
//   * not a front-end intrinsic site, by MEMBERSHIP (a module may DEFINE
//     `cq_theta_si32`), and not a callee in a reserved namespace (`cq_`, `__cq_`,
//     `cqrt_` — the name used ONLY to keep taint, the conservative direction, the
//     `DeadValueLiveness.h` roots precedent);
//   * ≥1 argument in `taint.Tainted` (an operand-bundle-only read keeps its taint);
//   * and the predictor says the return is classical.
// ⚠ NOT EXCLUDED, AND WHY (L8 retirement trigger): a `naked` callee. Its parameters
// have no IR uses (the verifier forbids them), so the predictor calls its return
// classical even though its inline asm reads the argument REGISTERS (bd ctz4's
// hazard). Sound today only because `scanBody` declines inline asm, so such a site
// is refused loudly at detection whatever its result's taint — the SAME trigger
// `nullSafeSlot` carries (SpecializeDetect.h): the day `scanBody` admits inline asm,
// add `!Callee->hasFnAttribute(Attribute::Naked)` here in the same change.
bool specCallResultPredictedClassical(const CallInst &CI, const TaintSet &taint) {
  if (!isPredictableSpecSite(CI))
    return false;
  CallInst *Site = const_cast<CallInst *>(&CI);
  if (taint.ThetaCalls.contains(Site) || taint.PhiCalls.contains(Site) ||
      taint.PhaseCalls.contains(Site) || taint.MeasureCalls.contains(Site))
    return false;
  const SpecMask Mask = taintArgMask(&CI, taint);
  if (Mask == 0)
    return false;
  return !predictReturnTainted(CI.getCalledFunction(), Mask);
}

}  // namespace cq
