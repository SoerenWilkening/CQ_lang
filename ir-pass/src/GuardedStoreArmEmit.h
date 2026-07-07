// GuardedStoreArmEmit.h — iw81.7: the guarded Shadow store (a tainted-index
// memory STORE UNDER tainted control) — the composition of the two deepest hazard
// domains (memory × control). PRD: docs/prd/phase-07-expressiveness/
// PRD-iw81.7-guarded-store.md. Bennett.jl ground truth: `emit_shadow_store_guarded!`
// / `soft_mux_store_guarded_NxW` (each store CNOT lifted to a Toffoli(pred, ...)).
//
// A tainted-condition `br`-diamond whose ONE content arm is SIDE-EFFECT-ONLY — a
// bounded-alloca tainted-index Shadow `store` (a gep chain + one `store`, NO merge
// φ; a store mints no SSA value) — the sibling being the empty straight-to-merge
// edge. This is NOT swap-routable: memory has no per-arm work rail, and
// swap-routing runs the store uncontrolled on both branches → `arr[0]=0` on the
// inactive branch (the verify-clean-invisible "store on the wrong branch"
// miscompile). The store must be GENUINELY CONTROLLED.
//
// Recognized (`classifyGuardedStoreArm`) BEFORE the generic `classifyArms` (a
// store arm is neither a phase spine nor a value chain, so it would decline). Once
// a store arm is found this step OWNS the shape (every precondition miss is a LOUD
// decline, never NotApplicable — Rule 1). Mechanism (`emitGuardedStoreArmRegion`):
// mint the path-predicate flag from the PRE-store condition handle → RECORD
// (store→flag) in `taint.GuardedStores` → FLATTEN the diamond (splice the arm's
// gep+store into `Pred`, rewire `Pred` straight to the merge, erase the arm +
// dead compare) → DO NOT strip the flag. `lowerShadowMemory` (later) emits the
// GUARDED store `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` for the
// recorded store; the whole-DAG LIFO uncompute reverses it via `..._controlled_unc`
// (the flag rides through as arg 0) and then strips+frees the flag (the flag-mint
// compare is a reversible DAG ancestor, §6.0 compare `_unc`). The flag is left LIVE
// so the guarded `_unc` is gated by the SAME pred value (an ungated / pre-stripped
// `_unc` over-pops the inactive branch — a dephasing silent miscompile).

#ifndef CQ_IRPASS_GUARDED_STORE_ARM_EMIT_H_
#define CQ_IRPASS_GUARDED_STORE_ARM_EMIT_H_

namespace llvm {
class BranchInst;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Outcome of the guarded-store recognizer, tried by
// `ControlDetect::handleBranchRegion` in the Diamond/IfElse arm BEFORE
// `classifyArms`:
//   * Accept        — exactly one arm is a side-effect-only bounded-alloca
//                     tainted-index Shadow store (a depth-1 diamond arm, no merge
//                     φ), the condition is a lowerable HL compare, and the store
//                     does not clobber a cell the condition reads (§3c). The caller
//                     pushes the `GuardedStoreArm` region for
//                     `emitGuardedStoreArmRegion`. NO diagnostic; `R` is populated
//                     (Pred/Arm/MergeBB/Condition/ArmNegated).
//   * Declined      — structurally a store-arm diamond (so this step OWNS it) but a
//                     precondition failed (non-HL/Q+Q/unsupported-width condition; a
//                     merge φ / mixed arm; a §3c clobber; the condition read as
//                     data). A loud, source-located diagnostic fired; lower nothing.
//   * NotApplicable — no side-effect-only store arm at all. The caller falls
//                     through to `classifyClassicalCallArm` / `classifyArms`. `R`
//                     is untouched.
enum class GuardedStoreDisp { Accept, Declined, NotApplicable };

// Recognize `BI` (a tainted-condition conditional `br`) as a guarded-store arm.
// Pure analysis — NO IR is mutated (Rule 9); writes `R` only on Accept.
GuardedStoreDisp classifyGuardedStoreArm(llvm::BranchInst *BI, TaintSet &Taint,
                                         ControlRegion &R);

// Lower one accepted `GuardedStoreArm` region (dispatched from
// `SwapRouteEmit::lowerControlRegions`). Mutates the module IR and `taint`.
void emitGuardedStoreArmRegion(const ControlRegion &R, WidthDispatch &wd,
                               TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_GUARDED_STORE_ARM_EMIT_H_
