// MergeDissolution.h — Dissolve a region's merge node (PRD §2.6,
// IMPLEMENTATION §5.5). The merge is a stock SSA merge (no `cq_template_*` to
// suffix), so it gets its own dissolution keyed on arm taint. WP3 handles the
// `[modified, original]` `br`-diamond case: the controlled gate mutated the
// register in place, so the merge `φ[rotated_y, y]` RAUWs to the in-place
// handle `y` (the incoming value from the non-arm predecessor) and the `φ` is
// erased. The `[classical, classical]` reduction is WP4; a `[≥1 tainted arm]`
// merge is rejected at detection (no region built), so nothing dissolves it.

#ifndef CQ_IRPASS_MERGE_DISSOLUTION_H_
#define CQ_IRPASS_MERGE_DISSOLUTION_H_

namespace cq {

struct TaintSet;
struct ControlRegion;

// Dissolve `region.Merge`. For the WP3 `[modified, original]` `br` case: RAUW
// the merge `φ` to the in-place handle (the incoming value from `region.Pred`,
// the original/unmodified arm) and erase the `φ`. Must run AFTER controlled
// substitution (which RAUW'd the modified arm to the handle) and BEFORE CFG
// linearization erases the arm/merge blocks (so no use dangles, §1.6).
void dissolveMerge(ControlRegion &region, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_DISSOLUTION_H_
