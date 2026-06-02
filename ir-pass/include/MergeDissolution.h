// MergeDissolution.h — Dissolve a region's merge node (PRD §2.6,
// IMPLEMENTATION §5.5). The merge is a stock SSA merge (no `cq_template_*` to
// suffix), so it gets its own dissolution keyed on arm taint.
//
//   * `br`-diamond case: dissolve EVERY `φ` in the merge block (WP7), each by
//     its own arm-taint class. A `[modified, original]` gate-handle `φ` RAUWs
//     to the in-place handle (the incoming value from the non-arm predecessor)
//     and is erased; a `[classical, classical]` data `φ` that rode along under
//     the same guard reduces via the §5.5 host-difference path (below). A
//     single-arm diamond may carry ≥2 `φ` (multiple gated handles, or a data
//     assignment alongside a gate); leaving any behind crashes linearization.
//   * WP4 `[classical, classical]` `select` case (`region.Merge` is a
//     `SelectInst`): `select i1 %c, A, B` reduces to `y = B + flag·(A−B)`.
//     Emit a host `%d = sub A, B` (plain LLVM — stays classical), then
//     `cqrt_alloc_<W>(B)` and `cq_template_add_<W>_hl_controlled(flag, regB,
//     %d)`; RAUW the select result to the controlled-add result and erase.
//
// A `[≥1 tainted arm]` merge is rejected at detection (no region built), so
// nothing dissolves it.

#ifndef CQ_IRPASS_MERGE_DISSOLUTION_H_
#define CQ_IRPASS_MERGE_DISSOLUTION_H_

namespace cq {

class WidthDispatch;
class ControlledSymbols;
struct TaintSet;
struct ControlRegion;

// Dissolve `region.Merge`.
//   * `[modified, original]` `br` case: RAUW the merge `φ` to the in-place
//     handle (the incoming value from `region.Pred`, the original/unmodified
//     arm) and erase the `φ`. Must run AFTER controlled substitution (which
//     RAUW'd the modified arm to the handle) and BEFORE CFG linearization
//     erases the arm/merge blocks (so no use dangles, §1.6).
//   * `[classical, classical]` `select` case: emit the controlled-add
//     reduction (host `sub` + `cqrt_alloc_<W>` + `add_<W>_hl_controlled`),
//     RAUW the select result, erase. Uses `region.Flag` (minted by ControlFlag)
//     as the control wire; `wd`/`csyms` mint the runtime/template symbols.
void dissolveMerge(ControlRegion &region, WidthDispatch &wd,
                   ControlledSymbols &csyms, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_DISSOLUTION_H_
