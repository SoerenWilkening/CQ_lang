// InPlaceQQConsume.cpp — the in-place round's decision ACROSS A LIFTED CALL
// (bd test_C_libtooling-r2j3.37.1; SpecializeConsume.h builds the candidates).
//
// A tagged lift site `r = f(args)` (`!cq.lift.tail.owed`, SpecializeLiftTag.h)
// is decided exactly as the in-place round decides the inlined body's chain op
// (InPlaceQQ.h), with its predicates asked, never re-spelt:
//   * KEPT: the result survives (`qqResultSurvives`, E3) and no emitter or M-B
//     plan discharges it (`railZeroedAndReleased`, `Plan.GateAt`); a discharged
//     temporary stays the out-of-place Bennett clone (out of place, then its own
//     adjoint at its death: the dead-record ruling).
//   * ELIGIBLE slot k: a chain parameter whose operand is DEAD after the call
//     (`qqDeadRecordBits`, the record's own predicate at the call's position) and
//     a USER-DATA rail (`qqTargetIsUserData`, E2) — asked on the lowered IR, so a
//     register an earlier conversion (QQ or consume) relabelled counts.
//   * two eligible slots -> `kMsgInPlaceQQAmbiguousTarget`; a dead φ not provably
//     one wire beside a kept result -> `kMsgInPlaceQQRefused`; the slot's
//     candidate refused at build -> its reason's message (self-dependent,
//     not in place); the positional fence `inPlacePositionHolds(call, t,
//     QuantumSource)` refusing -> `kMsgInPlaceQQRefused`.
//   * otherwise the call becomes ONE call to the consuming clone, tagged
//     `!cq.inplace.qq` (an in-place gate on slot k, `isInPlaceQQGate`), and `r`
//     is RAUW'd to t's handle.
// Sites are decided one at a time in program order on the current IR,
// alternating with the QQ round (a conversion on either side re-opens the
// other: `t ^= a; r = f(t, b)` needs the xor on `t` first, `r = f(t, a);
// s = r ^ b` the consume first).

#include "InPlaceQQ.h"

#include "ArithLowering.h"        // inPlacePositionHolds / railZeroedAndReleased
#include "SpecializeConsume.h"    // ConsumeReason / kConsumeAuxAttr
#include "SpecializeLiftTag.h"    // kLiftTailOwedTag / kMsgLiftTailUnhoisted
#include "TaintPropagation.h"
#include "Uncomputation.h"        // planInteriorDischarges

#include "llvm/ADT/STLExtras.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

uint64_t tagWord(const MDNode *MD, unsigned I) {
  if (!MD || MD->getNumOperands() <= I)
    return 0;
  auto *C = mdconst::dyn_extract<ConstantInt>(MD->getOperand(I));
  return C ? C->getZExtValue() : 0;
}

struct Entry {
  ConsumeReason Why = ConsumeReason::Unsupported;
  Function *Consumer = nullptr;
};

Entry entryFor(const MDNode *MD, unsigned K) {
  for (unsigned I = 1; MD && I < MD->getNumOperands(); ++I) {
    auto *E = dyn_cast<MDNode>(MD->getOperand(I));
    if (!E || E->getNumOperands() != 3 || tagWord(E, 0) != K)
      continue;
    Entry R;
    R.Why = static_cast<ConsumeReason>(tagWord(E, 1));
    if (auto *VM = dyn_cast<ValueAsMetadata>(E->getOperand(2)))
      R.Consumer = dyn_cast<Function>(VM->getValue());
    return R;
  }
  return Entry{};
}

const char *messageFor(ConsumeReason Why) {
  switch (Why) {
  case ConsumeReason::SelfDependent:
    return kMsgInPlaceQQSelfDependent;
  case ConsumeReason::NotInPlace:
    return kMsgInPlaceQQRefused;
  default:
    return kMsgLiftTailUnhoisted;
  }
}

}  // namespace

bool continuesThroughLiftedChain(const CallInst *C, const Value *R,
                                 Function &F) {
  const MDNode *MD = C->getMetadata(kLiftTailOwedTag);
  if (!MD)
    return false;
  const uint64_t Chain = tagWord(MD, 0);
  for (unsigned A = 0; A < C->arg_size() && A < 64; ++A)
    if ((Chain >> A & 1) && C->getArgOperand(A) == R) {
      DominatorTree DT(F);
      LoopInfo LI(DT);
      return qqDeadRecordBits(const_cast<Value *>(R), const_cast<CallInst *>(C),
                              DT, LI) & 1u;
    }
  return false;
}

int consumeNextLiftedCall(Function &F, WidthDispatch &wd, TaintSet &taint,
                          SmallPtrSetImpl<CallInst *> &Done) {
  CallInst *CI = nullptr;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (auto *C = dyn_cast<CallInst>(&I);
          !CI && C && !Done.count(C) && C->getMetadata(kLiftTailOwedTag))
        CI = C;
  if (!CI)
    return 0;
  Done.insert(CI);
  const MDNode *MD = CI->getMetadata(kLiftTailOwedTag);
  auto loud = [&](const char *Msg) {
    F.getContext().diagnose(
        DiagnosticInfoUnsupported(F, Msg, CI->getDebugLoc()));
    return 2;
  };
  DominatorTree DT(F);
  LoopInfo LI(DT);
  PostDominatorTree PDT(F);
  InteriorDischargePlan Plan = planInteriorDischarges(F, taint);
  if (!qqResultKept(CI, taint, F, PDT, Plan))
    return 1;  // a temporary: the out-of-place clone is its own discharge.
  // E1+E2, asked ONCE, here, on the lowered IR (R11 r1 rL1C-F3: the build no
  // longer pre-judges them): a chain slot whose operand is a dead user register,
  // never one filling two handle slots (`consumeSlotReadsTwice`).
  const uint64_t Chain = tagWord(MD, 0);
  const uint64_t Handles = taint.SpecHandleArgMask.lookup(CI->getCalledFunction());
  SmallVector<unsigned, 2> Eligible;
  bool PhiOwed = false;
  for (unsigned K = 0; K < CI->arg_size() && K < 64; ++K) {
    Value *V = CI->getArgOperand(K);
    if (!(Chain >> K & 1) || !(Handles >> K & 1) ||
        consumeSlotReadsTwice(*CI, K, Handles) || !qqTargetIsUserData(CI, V))
      continue;
    const unsigned Bits = qqDeadRecordBits(V, CI, DT, LI);
    if (Bits & 1u)
      Eligible.push_back(K);
    else if (Bits & 4u)
      PhiOwed = true;  // a dead φ not provably one wire: the B-F1 row.
  }
  if (Eligible.size() >= 2)
    return loud(kMsgInPlaceQQAmbiguousTarget);
  if (Eligible.empty())
    return PhiOwed ? loud(kMsgInPlaceQQRefused) : 1;
  const unsigned K = Eligible.front();
  const Entry E = entryFor(MD, K);
  if (E.Why != ConsumeReason::Ok || !E.Consumer)
    return loud(messageFor(E.Why));
  Value *T = CI->getArgOperand(K);
  // A source the consumer reads that depends on t's OLD value (a merge rail a
  // condition on `t` built, `outer(q, c ? x : 5)`): the inlined twin's E3
  // refusal, asked of every other handle operand (`dependsOnTarget`).
  for (unsigned J = 0; J < CI->arg_size() && J < 64; ++J)
    if (J != K && (Handles >> J & 1) &&
        qqSourceDependsOnTarget(CI->getArgOperand(J), T, CI, DT))
      return loud(kMsgInPlaceQQSelfDependent);
  if (!inPlacePositionHolds(CI, T, taint, DT, LI, &Plan,
                            /*IgnoreSelfMarking=*/false, /*QuantumSource=*/true))
    return loud(kMsgInPlaceQQRefused);
  if (!materializeConsumer(*E.Consumer, taint, wd))
    return loud(kMsgInPlaceQQRefused);  // no in-place symbol at the width.
  IRBuilder<> B(CI);
  CallInst *G = B.CreateCall(E.Consumer, SmallVector<Value *, 8>(CI->args()));
  G->setCallingConv(E.Consumer->getCallingConv());
  G->setDebugLoc(CI->getDebugLoc());
  G->setMetadata(kInPlaceQQTag, MDNode::get(F.getContext(), {}));
  CI->replaceAllUsesWith(T);  // `r` IS t's register now.
  taint.Tainted.erase(CI);
  taint.HandleWidth.erase(CI);
  taint.BirthOrder.erase(CI);
  Function *Old = CI->getCalledFunction();
  CI->eraseFromParent();
  if (Old && Old->use_empty())  // the replaced clone: erased if nothing else
    Old->addFnAttr(kConsumeAuxAttr);  // calls it (`eraseUnusedConsumeAux`).
  return 3;
}

void stripConsumeTags(Module &M) {
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        I.setMetadata(kLiftTailOwedTag, nullptr);
}

void eraseUnusedConsumeAux(Module &M) {
  SmallPtrSet<Function *, 16> Callees;  // what an erased body called
  for (bool Erased = true; Erased;) {
    Erased = false;
    for (Function &F : make_early_inc_range(M))
      if (F.hasFnAttribute(kConsumeAuxAttr) && F.use_empty() &&
          F.hasLocalLinkage()) {
        Callees.erase(&F);
        for (BasicBlock &BB : F)
          for (Instruction &I : BB)
            if (auto *C = dyn_cast<CallInst>(&I))
              if (Function *G = C->getCalledFunction()) {
                if (G->isDeclaration())
                  Callees.insert(G);
                else if (G->hasLocalLinkage() &&
                         G->getName().starts_with("__cq_q_"))
                  G->addFnAttr(kConsumeAuxAttr);  // a nested clone only the
                                                  // erased body called.
              }
        F.eraseFromParent();
        Erased = true;
      }
  }
  // Never leave a phantom declaration only an erased candidate used (n0ui).
  for (Function *G : Callees)
    if (G->use_empty())
      G->eraseFromParent();
  // The mark is bookkeeping, never output: a survivor (a clone the drain's
  // cache shared with a real site, a consumer that was called) drops it.
  for (Function &F : M)
    F.removeFnAttr(kConsumeAuxAttr);
}

}  // namespace cq
