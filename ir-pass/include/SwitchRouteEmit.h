// SwitchRouteEmit.h — the mutating swap-route emitter for an accepted tainted
// `switch` region (swap-route 4.5; PRD Part V §20; IMPLEMENTATION-4.5 §4/§5).
// Dispatched from `SwapRouteEmit::lowerControlRegions` on a `SwitchRegion`,
// keyed by the per-content-class discriminator `ControlRegion::SwitchCls`.
//
// WI-2 lands the PHASE class — `emitSwitchPhaseRegion`. A homogeneous phase
// switch `switch(q){ case c_i: q = cq_phi(q,θ_i) }` (each arm a const-folded
// phase gate over its case literal, empty default) lowers to the coherent,
// ZERO-controlled-gate N-way routed stream, emitted into the switch block
// before the `switch` terminator. Per content case `i` (routed base = the
// scrutinee `q`):
//   1. mint eq-flag       cq_template_icmp_eq_<W>_hl(q, c_i)        (CompareLowering)
//   2. |0> work rail      cqrt_alloc_<W>(0)                          (WidthDispatch)
//   3. route-in           cqrt_cswap(f_i, q, rail_i)   (eq-flags are positive-
//                         polarity / mutually exclusive — NO ¬-bracket)
//   4. replay VERBATIM    cqrt_rz_<W>(rail_i, θ_i)  — the folded gate's ARG-1
//                         (angle) ONLY; arg-0 (the case literal) is discarded.
//                         This is the §5 re-anchor BY PHYSICS (no RAUW of arg-0).
//   5. route-back         the SAME cswap (join = adjoint of the split)
//   6. rail free          cqrt_free(rail_i)  — the rail is |0> for free (Rz|0>=|0>)
//   7. flag strip         cq_template_icmp_eq_<W>_hl_inv(q, c_i)   (q == q0)
//   8. flag free          cqrt_free(f_i)
// After the N-loop: RAUW the merge phi → q; then the §5 SCRUB — scrub+erase each
// folded `cq_phi(c_i,θ_i)` from `taint` BEFORE `lowerRotations` runs, so its
// untainted arg-0 never triggers the RAUW-to-const data-mux degeneration (the
// BLOCKER, no downstream backstop, IMPLEMENTATION-4.5 §5); then flatten the
// N-way CFG (`flattenSwitchRegion`). `q` is never freed (the live result).
//
// Runs AFTER `detectControlRegions` and BEFORE `lowerRotations`, exactly like
// the 4.1 phase diamond emitter (`emitRegion`), so the per-case scrub is ordered
// between detect and rotations in BOTH orchestrator entry points (no orchestrator
// edit — twin-pipeline trap avoided). NO new ABI symbol, NO new diagnostic
// string. (Value (WI-3) / data-mux (WI-4) emitter entry points will be declared
// here too — one header, three `.cpp`.)

#ifndef CQ_IRPASS_SWITCH_ROUTE_EMIT_H_
#define CQ_IRPASS_SWITCH_ROUTE_EMIT_H_

namespace cq {

class ControlledSymbols;
class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Lower an accepted homogeneous PHASE switch region (`SwitchCls == Phase`).
// Mutates the module IR and `taint` (scrubs every erased instruction). The shape
// is detection-guaranteed; any residual mismatch bails LOUDLY (never a silent
// skip of quantum-controlled flow — Prime Directive).
void emitSwitchPhaseRegion(const ControlRegion &R, WidthDispatch &wd,
                           ControlledSymbols &csyms, TaintSet &taint);

// Lower an accepted homogeneous VALUE switch region (`SwitchCls == Value`) — the
// N-way method-B (route + verbatim chain replay + one copy-out + LIFO reverse-play
// over the shared routed base `p` = the merge default-edge incoming, `p != q`).
// Mutates the module IR and `taint`. The shape is detection-guaranteed; any residual
// mismatch bails LOUDLY (never a silent skip of quantum-controlled flow — Prime
// Directive). Declared here (one header, three `.cpp` — IMPLEMENTATION-4.5 §1);
// defined in `SwitchValueEmit.cpp`.
void emitSwitchValueRegion(const ControlRegion &R, WidthDispatch &wd,
                           ControlledSymbols &csyms, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SWITCH_ROUTE_EMIT_H_
