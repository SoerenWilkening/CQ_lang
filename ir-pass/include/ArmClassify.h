// ArmClassify.h — Per-arm lineage classification for swap-route control regions.
//
// Given a shape-recovered `ControlRegion` (from `ControlDetect::recoverRegion`),
// decide whether every arm's contribution to the merge `φ` is a pure PHASE chain
// over a tainted quantum handle (the §0 accept criterion 2+3) or whether some arm
// is a value/permutation redefinition — and, if so, whether it clobbers a
// register in the condition's transitive taint provenance (the §3c PERMANENT
// reject) or merely rewrites a non-condition register (a value-arm deferred to
// 4.2). Pure analysis: NO IR is mutated (Rule 9 — runs before lowering).
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
//                (the §0 accept criteria 2 and 3 both hold). NO diagnostic was
//                fired; the caller decides what to do (WI-1: transitional
//                decline; WI-2+: push the region for emission).
//   * Declined — some arm failed a criterion; `classifyArms` has ALREADY fired
//                the precise loud diagnostic (§3c clobber / value-arm / non-
//                quantum base). The caller must lower nothing for this region.
enum class ArmDisposition { Accept, Declined };

// Classify every arm of `Region` (a recovered diamond or if/else). Reads
// `Region.Merge` (the merge `PHINode`), `Region.Arm`/`Region.ArmFalse` (the arm
// blocks), `Region.Pred` (for the diamond straight-through incoming), and
// `Region.Condition`. Fires at most one diagnostic. See `ArmDisposition`.
ArmDisposition classifyArms(const ControlRegion &Region, TaintSet &Taint);

}  // namespace cq

#endif  // CQ_IRPASS_ARM_CLASSIFY_H_
