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

#include "ArithLowering.h"
#include "RailWindow.h"       // railWindowReachesAvoiding  // isLateImmediateReassignSite / railZeroedAndReleased
#include "TaintPropagation.h"
#include "Uncomputation.h"  // planInteriorDischarges

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Instructions.h"

#include <optional>

using namespace llvm;

namespace cq {

// bd dm7f.83 R11 r1 (rD1-F2) — the CONVERSE of `usersBefore`, and the one
// spelling of "the REGISTER is provably live after `At`": some other user of
// the rail `V` (a later Ry, template read, measure — the lowered IR names the
// rail by ONE handle across `cq_theta`'s new SSA names) runs after `At` on a
// path that does not first re-execute `V`'s own definition (a next trip's
// fresh rail is a different register). `usersBefore` answers "PROVEN dead" and
// is conservative in loops; this answers "PROVEN live" and is conservative the
// other way, so a loud rule keyed on deadness keys on `!registerLiveAfter`.
bool registerLiveAfter(const Value *V, const Instruction *At) {
  SmallPtrSet<const Instruction *, 1> Barriers;
  if (const auto *VI = dyn_cast<Instruction>(V))
    Barriers.insert(VI);
  for (const User *U : V->users()) {
    const auto *UI = dyn_cast<Instruction>(U);
    if (!UI || UI == At)
      continue;
    if (railWindowReachesAvoiding(At, UI, Barriers))
      return true;
  }
  return false;
}

// The SSA bit alone is not register deadness: `v = q + 3; cq_theta(&q, .)`
// marks `%q` dead while the theta rotates the SAME rail under a new name (and
// an `icmp` on the new name reads it). Such a register is LIVE: out of place is
// the program. Asked of the lowered handle by `registerLiveAfter` (PROVEN
// live, so a loop's per-trip fresh rail stays dead: it never re-reads the old
// register), here so every caller of this spelling gets it (R12). Measured:
// 19 of the 23 dm7f.83 flips were refusals on such live registers
// (laneL/dm7f83_flips.md); the rest are G4 (dm7f.83.1) and G7 (dead, a prior
// reader unsettled: still loud, the real r2j3.33 population).
bool qqDeadUserRegisterOperand(const CallInst *T, unsigned Idx,
                               const DominatorTree &DT, const LoopInfo &LI) {
  (void)DT;
  (void)LI;
  Value *V = T->getArgOperand(Idx);
  return (deadOperandMask(T) >> Idx & 1u) && qqTargetIsUserData(T, V) &&
         !registerLiveAfter(V, T);
}

bool qqResultKept(CallInst *T, const TaintSet &taint, Function &F,
                  PostDominatorTree &PDT, const InteriorDischargePlan &Plan) {
  return !(railZeroedAndReleased(T, nullptr, nullptr) || Plan.GateAt.count(T) ||
           !qqResultSurvives(T, taint, F, PDT));
}

// bd r2j3.44 (R11 rD1-F1) — the injective-dead-target rule's site set as built
// so far: `add`/`sub`/`xor` with a classical immediate on EITHER side
// (`isLateImmediateReassignSite`; `_lh` `m - q` converts in place as
// `~q + (m+1)`), and that site's handle slot. An injective map of a dead user
// register is lowered in place or the pass fails loudly. NOT YET HERE (bd
// r2j3.44 follow-ups, measured population in the bd record): `mul` by an odd
// constant and a widening `sext`/`zext`, which have no in-place lowering yet.
// -1: not such a site.
int injectiveDeadTargetSlot(const CallInst *C, const TaintSet &taint) {
  Value *P = nullptr;
  if (isLateImmediateReassignSite(C, taint, P))
    return C->getArgOperand(0) == P ? 0 : 1;
  return -1;
}

bool declineRefusedImmediateReassignments(Function &F, TaintSet &taint) {
  std::optional<PostDominatorTree> PDT;
  std::optional<InteriorDischargePlan> Plan;
  DominatorTree DT(F);
  LoopInfo LI(DT);
  for (BasicBlock &BB : F)
    for (Instruction &I : BB) {
      auto *C = dyn_cast<CallInst>(&I);
      const int S = C ? injectiveDeadTargetSlot(C, taint) : -1;
      if (S < 0)
        continue;
      Value *P = C->getArgOperand(S);
      // A dead φ not provably one wire that is user data is refused like the
      // QQ round's B-F1 row.
      const bool Dead =
          qqDeadUserRegisterOperand(C, S, DT, LI) ||
          ((unprovenPhiOperandMask(C) >> S & 1u) && railIsUserData(P) &&
           !registerLiveAfter(P, C));
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

// bd dm7f.83.1: `!cq.classical.params !{i32 k...}` — the integer formal
// parameters stage 2b needs vouched, and only those (emitting it everywhere
// renumbered every module's metadata): a parameter a lowered gate reads RAW in
// a classical-immediate slot (`cqrt_addc`/`cqrt_xorc` slot 1), closed over
// callers that pass their own parameter RAW into such a parameter. Never a
// handle slot (`SpecHandleArgMask`: a lifted clone's quantum arguments; any
// other function receives no handle, since a tainted argument retargets the
// call to a clone). A CLAIM stage 2b checks before it vouches, never trusts.
void tagClassicalParams(Module &M, const TaintSet &taint) {
  DenseMap<Function *, uint64_t> Need;
  auto classical = [&](const Argument *A) {
    return A->getArgNo() < 64 && A->getType()->isIntegerTy() &&
           !(taint.SpecHandleArgMask.lookup(A->getParent()) >> A->getArgNo() & 1);
  };
  for (Function &F : M)
    for (Instruction &I : instructions(F))
      if (auto *C = dyn_cast<CallInst>(&I))
        if (Function *G = C->getCalledFunction();
            G && C->arg_size() == 2 &&
            (G->getName().starts_with("cqrt_addc_") ||
             G->getName().starts_with("cqrt_xorc_")))
          if (auto *A = dyn_cast<Argument>(C->getArgOperand(1));
              A && classical(A))
            Need[&F] |= uint64_t(1) << A->getArgNo();
  for (bool Changed = true; Changed;) {
    Changed = false;
    for (Function &F : M)
      for (Instruction &I : instructions(F))
        if (auto *C = dyn_cast<CallInst>(&I)) {
          Function *G = C->getCalledFunction();
          const uint64_t GN = G ? Need.lookup(G) : 0;
          for (unsigned K = 0; GN && K < C->arg_size() && K < 64; ++K)
            if (auto *A = dyn_cast<Argument>(C->getArgOperand(K));
                A && (GN >> K & 1) && classical(A) &&
                !(Need.lookup(&F) >> A->getArgNo() & 1)) {
              Need[&F] |= uint64_t(1) << A->getArgNo();
              Changed = true;
            }
        }
  }
  LLVMContext &Ctx = M.getContext();
  for (auto &[F, Mask] : Need) {
    SmallVector<Metadata *, 4> Ops;
    for (unsigned K = 0; K < 64; ++K)
      if (Mask >> K & 1)
        Ops.push_back(ConstantAsMetadata::get(
            ConstantInt::get(Type::getInt32Ty(Ctx), K)));
    F->setMetadata("cq.classical.params", MDNode::get(Ctx, Ops));
  }
}

}  // namespace cq
