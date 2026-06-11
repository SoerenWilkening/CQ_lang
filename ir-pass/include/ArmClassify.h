// ArmClassify.h — Per-arm lineage classification for swap-route control regions.
//
// Given a shape-recovered `ControlRegion` (from `ControlDetect::recoverRegion`),
// classify every arm's contribution to the merge `φ` (4.2, PRD Part II §8.3 +
// IMPLEMENTATION-4.2 §3 — pure analysis, NO IR mutated, Rule 9):
//
//   * PHASE arm — a pure `cq_phi` spine over the tainted routed handle (the 4.1
//     §0 criteria 2+3, unchanged).
//   * VALUE arm — a pure LINEAR chain of supported tainted integer
//     `BinaryOperator`s bottoming at exactly the routed slot (base-identity),
//     each link consuming the threaded value as its sole tainted operand.
//     Routable + `Routed ∈ condProvenance` is the §3c PERMANENT reject (ACTIVE
//     since 4.2 WI-3); routable + disjoint is the accept class — a value
//     DIAMOND (WI-4) or a two-arm value IF/ELSE over ONE shared routed base
//     (WI-5), with the ordered chain recorded in `Shadow`/`ShadowFalse` +
//     `ClassArm`/`ClassArmFalse` for the method-B emitter.
//   * Everything else declines loudly with its precise string: `ChainBase !=
//     Routed` mux shapes (the Defect-2 fix) and FP-typed merges → `control
//     flow`; mixed phase/value content (either stacking order, or
//     heterogeneous if/else arms) → `mixed phase/value arm`; fan-out / stray
//     ops → `impure value arm`; Q+Q links → `value-arm swap-route` (defer).
//
// The §3c provenance walk replicates the per-use arg-1 angle exclusion from
// `TaintPropagation.cpp` verbatim (the angle operand of a `cq_theta`/`cq_phi` is
// classical and must never be mistaken for a condition operand — the f64/angle
// miscompile family). See swap-route 4.1 IMPLEMENTATION §3.

#ifndef CQ_IRPASS_ARM_CLASSIFY_H_
#define CQ_IRPASS_ARM_CLASSIFY_H_

namespace cq {

struct ControlRegion;
struct TaintSet;

// Outcome of classifying every arm of a recovered region.
//   * Accept   — every arm is a pure phase chain over a tainted quantum handle
//                (the §0 accept criteria 2 and 3 both hold), OR every arm is a
//                routable value chain over ONE shared tainted routed base
//                disjoint from the condition's provenance (the 4.2 §0
//                criterion; diamond since WI-4, if/else since WI-5). NO
//                diagnostic was fired; the caller pushes the region for
//                emission.
//   * Declined — some arm failed a criterion; `classifyArms` has ALREADY fired
//                the precise loud diagnostic (§3c clobber / mux / mixed /
//                impure / QQ-defer / non-quantum base). The caller must lower
//                nothing for this region.
enum class ArmDisposition { Accept, Declined };

// Classify every arm of `Region` (a recovered diamond or if/else). Reads
// `Region.Merge` (the merge `PHINode`), `Region.Arm`/`Region.ArmFalse` (the arm
// blocks), `Region.Pred` (for the diamond straight-through incoming), and
// `Region.Condition`; WRITES `Region.ClassArm`/`ClassArmFalse` and the ordered
// value-chain links into `Region.Shadow`/`ShadowFalse` for a value-class arm
// (pure SSA analysis — no IR is mutated; only the plan struct is populated).
// Fires at most one diagnostic. See `ArmDisposition`.
ArmDisposition classifyArms(ControlRegion &Region, TaintSet &Taint);

}  // namespace cq

#endif  // CQ_IRPASS_ARM_CLASSIFY_H_
