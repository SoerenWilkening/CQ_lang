// RegionTreeDetect.h — Depth-2 register-form nest recovery (pure analysis).
//
// Called from ControlDetect's `case RegionShape::Nested:`. Since bd 3qlq Inc 1
// part B it has NO accept: it runs the §0 criteria below only so each nested
// shape declines loudly with its precise per-shape string (the §5h decline
// matrix), and a shape that passes them all declines `nested control flow`. All
// recognition is by SSA-value identity BEFORE any IR mutation (Rule 9), reusing
// the de-anonymized shape recognizers (ControlShape.h), the per-arm lineage
// walks (ArmAnalysis.h) and the tree-homogeneity gate (ArmHomogeneity.h).
//
// The seven §0 criteria, in the order that yields the §5h table (FA2 —
// pinned empirically against the post-4.3 build, NOT the §3.1 narrative order):
//   1. outer one-content-arm diamond (else `nested control flow`);
//   7. inner single-pred / domination invariants (else `nested control flow`);
//   2. depth-2 cap — inner arm not tainted-br, merge exactly 3-incoming (else
//      `nested control flow`);
//   3. exactly-one merge phi (else `control flow`);
//   6. tree-homogeneous phase (else `mixed phase/value arm` / `value-arm
//      swap-route` / `impure phase arm`);
//   4. N-incoming RAUW-collapse to one base (else `control flow` — distinct-base
//      AND a non-`cq_phi` intervening gate, e.g. cq_theta/Ry, both land here);
//   5. mint-from-rail — inner cond operand in the parent-routed value's
//      diagonal-alias closure (else `nested control flow` — the multi-register
//      false-accept, the load-bearing binding signal).
// Homogeneity (6) precedes RAUW-collapse (4): a value-op merge incoming does not
// collapse through the `cq_phi` closure, so the reverse order mis-fires `control
// flow` on a value nest instead of its homogeneity string.

#ifndef CQ_IRPASS_REGION_TREE_DETECT_H_
#define CQ_IRPASS_REGION_TREE_DETECT_H_

#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class BranchInst;
}  // namespace llvm

namespace cq {

struct ControlPlan;
struct TaintSet;

// Outcome of proving the §0 nest shape for `OuterBI` (which `recoverRegion`
// classified `RegionShape::Nested`).
//   * Declined — `recoverRegionTree` has ALREADY fired the precise loud
//     diagnostic; the caller lowers nothing.
//   * Accepted — the proven depth-2 homogeneous-phase nest. NO diagnostic was
//     fired; the inner `BranchInst` was recorded in `Claimed` (so
//     `detectControlRegions` does not re-visit it and false-decline `control
//     flow` — blocker FA0). WI-1: the caller fires the transitional `nested
//     control flow` decline (no emitter yet). WI-3: the caller pushes the
//     Outer (Depth 0) + Inner (Depth 1, ParentIdx=outer) regions onto
//     `plan.Regions` and dispatched `NestedRouteEmit`. ⚠ NEITHER EXISTS SINCE
//     bd test_C_libtooling-3qlq Inc 1 part B: `NestedRouteEmit` is DELETED and
//     this function has no ACCEPT branch left — every criterion it proves is a
//     consequence of the RETIRED register-form arm gate (a merge φ, a `cq_phi`
//     diagonal-alias base, an inner flag minted from the parent's work rail),
//     so under owner decision D1/D2 the shape cannot exist. The register-FREE
//     depth-2 nest is claimed earlier by `ArmClassify::classifyPhaseKickbackNest`
//     and emitted by `SwapRouteEmit::emitPhaseKickbackNestRegion`.
enum class NestDisposition { Accepted, Declined };

NestDisposition recoverRegionTree(
    llvm::BranchInst *OuterBI, TaintSet &Taint, ControlPlan &Plan,
    llvm::SmallPtrSetImpl<llvm::BranchInst *> &Claimed);

}  // namespace cq

#endif  // CQ_IRPASS_REGION_TREE_DETECT_H_
