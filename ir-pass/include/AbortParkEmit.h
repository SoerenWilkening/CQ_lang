// AbortParkEmit.h — Phase 7.2 Increment 3: the abort/exit park cascade
// (PRD-7.2 §2.8 / §2.11-B, IMPLEMENTATION-PLAN-7.2 §5).
//
// The ONE genuinely-new emission of Phase 7.2. A tainted-condition `br` whose
// one arm is a recognized NORETURN SINK (`@abort`/`@exit`/`@_exit`/`@_Exit`/
// `@quick_exit`/`@__assert_fail`/`@__assert_rtn`/`@llvm.trap`/`@llvm.ubsantrap`
// immediately followed by `unreachable`, carrying NO value and NO merge φ), the
// sibling being the ordinary uncontrolled remainder, is NOT a reconverging value
// exit — the sink arm has nothing to merge — so it structurally kills the
// §2.8↔§2.10 collision and cannot match `recoverRegion`'s accept shapes (its arm
// is `unreachable`-terminated ⇒ `uncondSucc==null` ⇒ `OffPattern`). It must
// therefore be recognized BEFORE that `OffPattern` decline pre-empts it (parallel
// to how `lowerControlledIOSinks` pre-peels the merge-φ-less void-I/O diamond).
//
// Mechanism (PRD-7.2 §2.8 / `bd memories abort-exit-park-cascade`): mint the
// abort flag from the pre-abort routed handle → `cqrt_cswap` that handle into a
// freshly-`cqrt_alloc`'d GRAVEYARD rail under the flag (so the would-abort
// component is moved aside, decoupled from the uncontrolled downstream) → record
// the flag on the 7.6 output tape (`cqrt_tape_write_i1`, the truncate-at-
// inspection marker) → run the sibling/downstream UNCONTROLLED (abort
// TERMINATES, so there is no coherent downstream and the branch-correlated
// tail-garbage of hazard (i) is never observed and never dephases — the same
// cost already accepted from swap-route arms; do NOT gate every downstream op on
// ¬flag — pointless + costly). The graveyard rail + flag are KEPT
// (`taint.GraveyardRails`, subtracted at BOTH uncompute spine sites), NEVER
// `cqrt_free`'d — a parked entangled rail freed dirty is a hidden measurement
// (Rule 6). NO flag strip (the park changed the routed handle, so `icmp_inv`
// would not zero the flag).
//
// The park `cqrt_cswap` is SELF-BRACKETED via `emitRoute` (the swap-route router)
// and is NEVER threaded through `emitInverseChain`: `cqrt_cswap` arg-0 is the FLAG
// slot, and the inverter would thread a handle there → a verify-clean WRONG
// UNITARY (EmitInverse.cpp:99-116, the swap-route seam).

#ifndef CQ_IRPASS_ABORT_PARK_EMIT_H_
#define CQ_IRPASS_ABORT_PARK_EMIT_H_

namespace llvm {
class BranchInst;
class CmpInst;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Outcome of the abort/exit-park recognizer, tried by
// `ControlDetect::handleBranchRegion` BEFORE `recoverRegion`'s `OffPattern`
// decline (so an `unreachable`-terminated sink arm is not pre-empted):
//   * Accept        — exactly one arm is a recognized noreturn sink ({sink call,
//                     `unreachable`}, single-pred, no value, no tainted arg), the
//                     condition is a lowerable HL compare over a value-class
//                     routed handle, and that handle is the SOLE tainted register
//                     live in the remainder. The caller pushes the `AbortPark`
//                     region for `emitAbortParkRegion`. NO diagnostic fired; `R`
//                     is populated (Pred/Arm/Condition/ArmNegated).
//   * Declined      — structurally an abort-sink arm (so this step OWNS it — never
//                     a silent skip, Rule 1) but a precondition failed: a
//                     non-HL / Q+Q / unsupported-width condition, a phase-class
//                     value escaping beside the park arm (§2.6 deferred
//                     interaction → `phase-class value escaping`), or another
//                     tainted register live in the remainder (unparked →
//                     conservative decline). A loud, source-located diagnostic
//                     fired; lower nothing. `R` is NOT populated.
//   * NotApplicable — not an abort/exit park at all (no `unreachable`-terminated
//                     recognized-sink arm). The caller falls through to the
//                     ordinary `recoverRegion` shape recovery. `R` is untouched.
enum class AbortParkDisp { Accept, Declined, NotApplicable };

// Recognize `BI` (a tainted-condition conditional `br`) as an abort/exit park.
// Pure analysis — NO IR is mutated (Rule 9); writes `R` only on Accept.
AbortParkDisp classifyAbortPark(llvm::BranchInst *BI, TaintSet &Taint,
                                ControlRegion &R);

// bd test_C_libtooling-dm7f.7 — is `Cmp` the condition of an abort/exit park:
// its ONLY user a conditional `br` on it, one of whose successors is the
// recognized noreturn-sink arm `classifyAbortPark` owns (`isNoreturnSinkArm`)?
// The SHAPE half only: whether the park is then accepted (remainder guard,
// widths, the HL operand) stays `classifyAbortPark`'s. Asked by `tryCaseA`'s
// CLOSURE, which lets a loop whose rail the park's compare reads before the loop
// collapse: the park tapes its flag and never strips it, so no adjoint of the
// compare runs after the loop's gates. Pure analysis.
bool isAbortParkCondition(const llvm::CmpInst *Cmp, const TaintSet &Taint);

// Lower one accepted `AbortPark` region (dispatched from
// `SwapRouteEmit::lowerControlRegions`). Mutates the module IR and `taint`.
void emitAbortParkRegion(const ControlRegion &R, WidthDispatch &wd,
                         ControlledSymbols &csyms, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_ABORT_PARK_EMIT_H_
