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

#include "llvm/ADT/ArrayRef.h"

namespace llvm {
class Instruction;
class Value;
}  // namespace llvm

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

// WP10 (Family B2) — lower an `AngleSelectRegion`: a tainted-condition select
// over the classical rotation ANGLE (`region.Merge`) feeding only rotation-angle
// operands (`region.Shadow`). For each consuming `cq_phi`/`cq_theta` emit the
// unconditional base `Rz(handle, b)` plus a flag-controlled difference
// `Rz_controlled(flag, handle, a−b)` (Ry/Rz angle-additivity), erase the
// consumers and the select. Returns the uncompute anchor (the node after the
// last rotation) for the orchestrator's flag uncompute, or null on failure.
// `region.Flag` must already be minted (`lowerControlFlag`).
llvm::Instruction *reduceAngleSelect(ControlRegion &region, WidthDispatch &wd,
                                     TaintSet &taint);

// cwk fix (b) (test_C_libtooling-byx) — the `br`-diamond analog of
// `reduceAngleSelect`: lower a classical-angle merge `φ` (`region.AnglePhi`,
// consumed by `region.AngleConsumers`) as controlled-rotation-by-difference. Per
// consumer emit the unconditional base `Rz(handle, base)` plus a flag-controlled
// difference `Rz_controlled(flag, handle, arm − base)`, where the base is the
// `flag==0` φ edge (`ArmFalse`/`Arm`/`Pred` per shape). Runs AFTER
// `dissolveBranchPhi` (sibling gate-handle φ dissolved first) and BEFORE the flag
// uncompute; returns the uncompute anchor (after the last rotation) or null.
// `region.Flag` must already be minted (`lowerControlFlag`).
llvm::Instruction *reduceAngleDiamondPhi(ControlRegion &region, WidthDispatch &wd,
                                         TaintSet &taint);

// cwk fix (b) PR3 (test_C_libtooling-byx) — the gated-`switch` analog of
// `reduceAngleSelectChain`: lower a gated `SwitchRegion`'s classical-angle merge
// `φ`(s) (`region.AnglePhi`, consumed by `region.AngleConsumers`) as base +
// per-case controlled-difference. The base is the DEFAULT arm's `φ` incoming
// (`region.Arm`), applied unconditionally; each case `k` adds
// `Rz_controlled(CaseFlags[k], handle, a_k − base)`, REUSING the per-case
// eq-flags `lowerGatedSwitch` already minted for the arm gate bodies
// (`CaseFlags[k]` ↔ `region.SwitchArms[k]`). Runs AFTER the handle-φ dissolution
// and BEFORE the flag uncompute; returns the uncompute anchor (after the last
// rotation) or null. The cases are mutually exclusive, so the differences are
// independent — no per-case bracketing beyond the shared switch uncompute.
llvm::Instruction *reduceAngleSwitchPhi(ControlRegion &region,
                                        llvm::ArrayRef<llvm::Value *> CaseFlags,
                                        WidthDispatch &wd, TaintSet &taint);

// WP16 (PRD §8.4) — lower an angle-select CHAIN: the multi-angle generalization
// of `reduceAngleSelect` (angle `switch`/`if-else-if`). `-O1` sinks it to
// `rz(u, select(f_n, a_n, …select(f_1, a_1, a_default)))`. Walks the false-arm
// chain from `region.Merge` (the head select) and, per consuming rotation,
// emits the unconditional base `Rz(handle, a_default)` plus one
// flag-controlled difference `Rz_controlled(f_k, handle, a_k − a_default)` per
// case, each in its own compare compute/uncompute bracket. Detection validated
// the chain is mutually exclusive (`icmp eq` on one scrutinee, distinct
// constants), so this manages all per-case flags itself — NOT the single
// `region.Flag` — and the orchestrator routes here BEFORE `lowerControlFlag`.
void reduceAngleSelectChain(ControlRegion &region, WidthDispatch &wd,
                            TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_DISSOLUTION_H_
