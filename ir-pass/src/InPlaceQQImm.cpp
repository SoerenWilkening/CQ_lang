// InPlaceQQImm.cpp — the in-place rounds' two shared questions, and the
// classical-immediate refusal that leaves a dead register standing (bd
// test_C_libtooling-dm7f.83; ruling-dm7f83-inplace-fence-refusal-loud-2026-10-16).
//
// The QQ round (InPlaceQQ.cpp) converts a quantum-source op whose dead operand
// is a user register beside a KEPT result, or fails loudly (owner-ruling-dm7f51-
// inplace-qq-2026-10-14 Q1). The classical-immediate M-C round (ArithLowering)
// had no such rule: a refusal by any guard of `inPlaceFenceHolds` — G4's formal-
// PARAMETER immediate (stage 2b cannot vouch for it), G5 in a loop, G6/G7
// position — left the out-of-place `_hl` template beside the dead register's old
// rail, the r2j3.33 wrong unitary, with only a later-rotation warning. Now the
// same two predicates the QQ round asks decide it, after both rounds have run
// (a refused site never converts later): dead user register + kept -> LOUD. No
// "only if later rotated" carve-out. RETIREMENT (the dm7f.83 follow-up): once
// stage 2b vouches for a classical parameter immediate and G4 is dropped, the
// G4 population converts instead of reaching here.

#include "InPlaceQQ.h"

#include "ArithLowering.h"  // isLateImmediateReassignSite / railZeroedAndReleased
#include "TaintPropagation.h"
#include "Uncomputation.h"  // planInteriorDischarges

#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <optional>

using namespace llvm;

namespace cq {

bool qqDeadUserRegisterOperand(const CallInst *T, unsigned Idx) {
  return (deadOperandMask(T) >> Idx & 1u) &&
         qqTargetIsUserData(T, T->getArgOperand(Idx));
}

bool qqResultKept(CallInst *T, const TaintSet &taint, Function &F,
                  PostDominatorTree &PDT, const InteriorDischargePlan &Plan) {
  return !(railZeroedAndReleased(T, nullptr, nullptr) || Plan.GateAt.count(T) ||
           !qqResultSurvives(T, taint, F, PDT));
}

bool declineRefusedImmediateReassignments(Function &F, TaintSet &taint) {
  std::optional<PostDominatorTree> PDT;
  std::optional<InteriorDischargePlan> Plan;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB) {
      auto *C = dyn_cast<CallInst>(&I);
      Value *P = nullptr;
      if (!C || !isLateImmediateReassignSite(C, taint, P))
        continue;
      // The handle is slot 0 of `_hl`. A dead φ not provably one wire that is
      // user data is refused like the QQ round's B-F1 row.
      const bool Dead = qqDeadUserRegisterOperand(C, 0) ||
                        ((unprovenPhiOperandMask(C) & 1u) && railIsUserData(P));
      if (!Dead)
        continue;
      if (!PDT) {
        PDT.emplace(F);
        Plan.emplace(planInteriorDischarges(F, taint));
      }
      if (!qqResultKept(C, taint, F, *PDT, *Plan))
        continue;  // a temporary: out of place, then its own adjoint.
      F.getContext().diagnose(
          DiagnosticInfoUnsupported(F, kMsgInPlaceQQRefused, C->getDebugLoc()));
      return true;
    }
  return false;
}

}  // namespace cq
