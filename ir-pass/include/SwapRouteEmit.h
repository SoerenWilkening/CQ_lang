// SwapRouteEmit.h — the control-region emitters. The file name is history: the
// RSSA swap route it was named for (a |0> work rail plus a `cqrt_cswap`
// route-in/route-back) was retired by bd test_C_libtooling-3qlq (Inc 1 for
// phase arms, Inc 2 for value arms). `lowerControlRegions` dispatches every
// region `detectControlRegions` (ControlDetect) accepted, emitting into the pred
// block BEFORE the conditional `br`; `RegionFlatten` then splices the merge into
// the pred and deletes the dead arm/merge blocks. What each class emits now:
//   * PHASE arm (`PhaseKickback` / `PhaseKickbackNest`, register-free
//     `cq_phi(θ)`): KICKBACK — flag mint, one UNCONTROLLED `cqrt_rz_i1(f, θ)` per
//     arm gate (`cqrt_x`-bracketed for a ¬flag arm), the compare's `_unc` strip,
//     ONE `cqrt_free(f)`. A bare `_Bool` condition is its own flag (no mint, strip
//     or free; a ¬ arm is the diagonal `rz(−θ)`). `emitKickbackGroup` is the one
//     spelling of that gate group.
//   * VALUE arm (`ClassArm == Value`, `emitRegion` → `emitValueRegion`): the
//     CONTROLLED-COPY MERGE. The arm's proven pure linear chain is HOISTED into
//     the pred (`lowerOps` lowers it, the whole-DAG spine reverses it), a `select`
//     is built for the merge, and the 4.4 `emitSelectRegion` emits two
//     `cqrt_copy_<W>_controlled` into a fresh |0> rail (the ¬flag one
//     X-bracketed), the flag strip and ONE `cqrt_free`. A value arm's polarity
//     rides the `select`'s operand SLOT, not a bracket.
//   * IN-PLACE ROTATION arm / controlled state prep (`InPlaceRotation`): the
//     arm's `cq_theta` is hoisted and recorded in `taint.ControlledRotations`, and
//     `lowerRotations` mints `cqrt_ry_<W>_controlled(f, h, θ)`.
//   * select, angle-select, switch, classical-call, guarded-store and abort-park
//     regions go to their own emitters (see `lowerControlRegions`).
// Nothing in this file routes a register into a work rail. `cqrt_cswap` is
// minted only by `AbortParkEmit`, through `emitRoute` below.
//
// Every erased instruction (merge φ, arm `cq_phi`, arm links, dead icmp) is
// SCRUBBED from `taint`'s work lists (§6.1 — else a later
// `lowerRotations`/`uncompute` dereferences freed memory; ⚠ since bd 8e5r every
// `TaintSet` table drops a deleted key BY ITSELF (`ScrubOnDelete.h`), so this
// scrub is belt-and-braces, no longer the only defence — and the other
// IR-deleting sites, most of which never scrubbed, are covered too: 133 static
// sites, 29 dynamic unscrubbed producers).
//
// A ¬flag arm: `clang -O1` makes the gate arm the false successor for
// `if (u != k)`-style conditions (Rule 9); detection records the polarity in
// `ControlRegion::ArmNegated`.
//
// Runs AFTER `detectControlRegions` and BEFORE `lowerRotations` (§4): it
// references the still-present `@cq_theta` result `%q`; when `lowerRotations`
// later RAUWs `%q` to its `i32` alloc handle every emitter call updates
// automatically (the SSA-identity discipline, Rule 9). The only post-4.1 ABI
// addition is the `cqrt_copy_<W>` family (PRD Part II §8.1) — still emitted, by
// the 4.5 switch-value PRELOAD (SwitchValueEmit) though no longer by the
// retired diamond copy-out.

#ifndef CQ_IRPASS_SWAP_ROUTE_EMIT_H_
#define CQ_IRPASS_SWAP_ROUTE_EMIT_H_

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"

namespace llvm {
class BasicBlock;
class CallInst;
class DebugLoc;
class Module;
class Value;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct TaintSet;
struct ControlPlan;

// Emit every region in `plan.Regions` (populated by `detectControlRegions`),
// dispatched by `Kind` and arm class as above. Mutates the module IR and `taint`
// (scrubs every erased instruction). A plan with no regions is a no-op, so a
// classical-only / fully-declined module is untouched.
void lowerControlRegions(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                         const ControlPlan &plan);

// Shared primitives, de-anonymized from the .cpp. `collectArmPhis` returns an
// arm block's IN-BLOCK `@cq_phi_<sfx>` gates in FORWARD program order, bounded at
// the arm-block boundary (a pre-region phi is the live derived base, not an arm
// gate). It matches only that retired register form, whose every use is a loud
// reserved-name error in `resolveSources`, so on a module that reaches emission it
// finds no gates. `emitRoute` emits `cqrt_cswap(flag, q, rail)`, X-bracketed for a
// ¬flag (`Negated`/FALSE-successor) arm, and RETURNS that cswap. Its one caller is
// `AbortParkEmit` (the 7.2 park into a kept graveyard rail), which records no
// `TaintSet::RestoringRoute` group. The X brackets are on the FLAG, never on `Q`.
llvm::SmallVector<llvm::CallInst *, 4> collectArmPhis(
    llvm::Value *ArmIncoming, const llvm::BasicBlock *ArmBB);
llvm::CallInst *emitRoute(llvm::IRBuilder<> &B, const ControlledSymbols &csyms,
                          llvm::Value *Flag, llvm::Value *Q, llvm::Value *Rail,
                          bool Negated, const llvm::DebugLoc &DL);

}  // namespace cq

#endif  // CQ_IRPASS_SWAP_ROUTE_EMIT_H_
