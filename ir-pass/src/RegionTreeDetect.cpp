// RegionTreeDetect.cpp — Depth-2 nested-control region-tree recovery.
// See RegionTreeDetect.h for the contract and the criterion order.
//
// Invoked from ControlDetect's `case RegionShape::Nested:` (where the blanket
// `nested control flow` decline lived). Proves the §0 depth-2 homogeneous-phase
// nest by SSA-value identity (Rule 9) or declines loudly with the §5h per-shape
// string. WI-1 lands DETECTION ONLY: an Accepted nest declines transitionally via
// the existing `nested control flow` string at the call site (no emitter yet),
// while the inner branch is recorded in `Claimed` (FA0) for WI-3.

#include "RegionTreeDetect.h"

#include "ArmAnalysis.h"
#include "ArmHomogeneity.h"
#include "ControlPlan.h"
#include "ControlShape.h"
#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}
bool isPhiCall(const Value *V) { return isCallToPrefix(V, "cq_phi_"); }
bool isThetaCall(const Value *V) { return isCallToPrefix(V, "cq_theta_"); }

// The bottom of `V`'s backward `cq_phi` arg-0 chain — the diagonal-alias base
// (criterion 4). Rz is diagonal, so rotation lowering RAUWs every link on this
// chain to one i32 handle; two merge incomings agree iff their bases are
// identical. A `cq_theta`/Ry or value-op incoming bottoms at itself (NOT the
// routed base) → distinct base → criterion 4 declines.
Value *diagonalBase(Value *V) {
  while (isPhiCall(V)) {
    auto *CI = cast<CallInst>(V);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  return V;
}

}  // namespace

NestDisposition recoverRegionTree(
    BranchInst *OuterBI, TaintSet &Taint, ControlPlan & /*Plan*/,
    SmallPtrSetImpl<BranchInst *> &Claimed) {
  BasicBlock *Pred = OuterBI->getParent();
  BasicBlock *S0 = OuterBI->getSuccessor(0);
  BasicBlock *S1 = OuterBI->getSuccessor(1);
  const bool T0 = hasTaintedCondBranch(S0, Taint);
  const bool T1 = hasTaintedCondBranch(S1, Taint);

  // Criterion 1 — outer ONE-CONTENT-ARM diamond. Exactly one outer successor is
  // the inner (Mid) diamond; the other is the shared merge reached straight from
  // Pred. BOTH tainted-branch (an if/else both-arm nest — not a one-content-arm
  // diamond, §12.4 inv-(i)) OR NEITHER (the sequential `if/else; if` reaching
  // here via the if/else merge's tainted branch) → decline `nested control flow`.
  if (T0 == T1)
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  BasicBlock *Mid = T0 ? S0 : S1;
  BasicBlock *Merge = T0 ? S1 : S0;  // outer straight-through successor.

  // Criterion 7 (part) — the outer single-pred invariant (`Arm`/`Mid` reached
  // ONLY from Pred; a sequential layout sharing Mid fails this).
  if (Mid->getSinglePredecessor() != Pred)
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  // Inner diamond — Mid's terminator is the inner conditional branch (guaranteed
  // conditional + tainted by `hasTaintedCondBranch`).
  auto *InnerBI = cast<BranchInst>(Mid->getTerminator());
  BasicBlock *IS0 = InnerBI->getSuccessor(0);
  BasicBlock *IS1 = InnerBI->getSuccessor(1);

  // The inner content arm is single-pred(Mid) and falls through UNCONDITIONALLY
  // to the SAME outer merge; the other inner successor IS that merge. This also
  // enforces the depth-2 cap (criterion 2): a depth-3 inner arm ends in a tainted
  // br, so `uncondSucc` is null and neither orientation matches → decline.
  BasicBlock *InnerArm = nullptr;
  if (IS1 == Merge && uncondSucc(IS0) == Merge &&
      IS0->getSinglePredecessor() == Mid)
    InnerArm = IS0;
  else if (IS0 == Merge && uncondSucc(IS1) == Merge &&
           IS1->getSinglePredecessor() == Mid)
    InnerArm = IS1;
  else
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  // Criterion 3 — exactly one merge phi. Two phis (the inner cond/arm on distinct
  // registers, real `-O1`) → `control flow`.
  PHINode *MergePhi = nullptr;
  unsigned NumPhi = 0;
  for (PHINode &P : Merge->phis()) {
    MergePhi = &P;
    ++NumPhi;
  }
  if (NumPhi != 1)
    return diagnoseUnderControl(OuterBI, "control flow"),
           NestDisposition::Declined;

  // Criterion 2 (cap) — exactly 3 incomings, exactly {Pred, Mid, InnerArm}.
  if (MergePhi->getNumIncomingValues() != 3 ||
      MergePhi->getBasicBlockIndex(Pred) < 0 ||
      MergePhi->getBasicBlockIndex(Mid) < 0 ||
      MergePhi->getBasicBlockIndex(InnerArm) < 0)
    return diagnoseUnderControl(OuterBI, "nested control flow"),
           NestDisposition::Declined;

  Value *QPred = MergePhi->getIncomingValueForBlock(Pred);   // %q
  Value *GMid = MergePhi->getIncomingValueForBlock(Mid);     // %g (routed to rail1)
  Value *HArm = MergePhi->getIncomingValueForBlock(InnerArm);  // %h
  Value *InnerCond = InnerBI->getCondition();

  // Criterion 6 — TREE HOMOGENEITY (before RAUW-collapse, FA2). Any value arm →
  // `mixed phase/value arm` / `value-arm swap-route`; a Mid stray → `impure phase
  // arm`; a tainted angle → `rotation angle`. (A non-`cq_phi` intervening Mid gate
  // — cq_theta/Ry — is a phase-leaf here, so homogeneity PASSES it through; it
  // declines below at RAUW-collapse, `control flow`.)
  if (!treeHomogeneous(Mid, GMid, InnerCond, InnerArm, HArm, Taint, OuterBI))
    return NestDisposition::Declined;

  // Criterion 4 — N-incoming RAUW-collapse: every merge incoming bottoms at one
  // base through the `cq_phi` diagonal-alias closure. A distinct independently-
  // derived base, or a non-diagonal (cq_theta) intervening gate, → `control flow`.
  Value *BasePred = diagonalBase(QPred);
  if (diagonalBase(GMid) != BasePred || diagonalBase(HArm) != BasePred)
    return diagnoseUnderControl(OuterBI, "control flow"),
           NestDisposition::Declined;

  // Criterion 5 — MINT-FROM-RAIL (the load-bearing binding signal). The inner
  // condition must be a function of ONLY the parent-routed value `%g` (the value
  // physically on rail1 post-route-in) and classical constants — so the inner
  // flag can be minted `icmp(rail1, k)`. Build `%g`'s diagonal-alias closure (the
  // backward `cq_phi` arg-0 chain) and require EVERY quantum-register LEAF in the
  // inner condition's provenance — a `cq_theta` source or a pre-region `cq_phi`
  // handle — to lie in it. A SECOND quantum register (`icmp((%g+%r),9)` /
  // `(%g*0)+%r`) leaves `%r` (a `cq_theta`) outside the closure → decline `nested
  // control flow`: minting from rail1 (which holds only `%g`) cannot evaluate a
  // predicate that depends on off-rail `%r` — a verify-clean wrong predicate (the
  // multi-register false-accept, criterion 4 passes since the merge is all
  // `%g`-lineage). Derivation intermediates (add/mul/icmp/cast — themselves in
  // the provenance) are functions of their operands and are NOT required to be in
  // the closure (else the canonical derived cond `icmp(%g,9)` would over-decline).
  // A single membership hit is INSUFFICIENT — the WHOLE quantum lineage must be
  // contained (the §8 over-accept fix, adversarial review 2026-06-12).
  SmallPtrSet<const Value *, 8> RailClosure;
  for (Value *V = GMid;;) {
    RailClosure.insert(V);
    if (!isPhiCall(V))
      break;
    auto *CI = cast<CallInst>(V);
    if (CI->arg_size() < 1)
      break;
    V = CI->getArgOperand(0);
  }
  SmallPtrSet<Value *, 16> InnerProv;
  condProvenance(InnerCond, Taint, InnerProv);
  for (Value *V : InnerProv)
    if ((isThetaCall(V) || isPhiCall(V)) && !RailClosure.count(V))
      return diagnoseUnderControl(OuterBI, "nested control flow"),
             NestDisposition::Declined;

  // ACCEPT — the proven depth-2 homogeneous-phase nest. Record the inner branch
  // so the detection loop does not re-visit it (FA0). WI-1: the caller fires the
  // transitional `nested control flow` decline (no emitter). WI-3: the caller
  // pushes the Outer/Inner regions + dispatches `NestedRouteEmit`.
  Claimed.insert(InnerBI);
  return NestDisposition::Accepted;
}

}  // namespace cq
