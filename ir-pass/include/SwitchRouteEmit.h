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
// N-way PRELOAD + XOR-DELTA controlled-copy merge over the shared base `p` = the
// merge default-edge incoming (`p != q`): `alloc out(0); cqrt_copy_<W>(p, out)`,
// then per content case the chain HOISTED onto the original `p`, the Q+Q delta
// `d_i = R_i(p) ^ p`, the eq-flag `f_i = (q == c_i)` and ONE
// `cqrt_copy_<W>_controlled(f_i, d_i, out)`; strip + free the flags. NO route, NO
// work rail, NO `cqrt_x` bracket and NO reverse-play in the emitter — the
// eq-flags are mutually exclusive and the hoisted chain is reversed by the
// whole-DAG spine (the swap route was RETIRED here by bd
// test_C_libtooling-3qlq Inc 2; see `SwitchValueEmit.cpp`'s file header for the
// retired stream and for what is deliberately left allocated).
// Mutates the module IR and `taint`. The shape is detection-guaranteed; any residual
// mismatch bails LOUDLY (never a silent skip of quantum-controlled flow — Prime
// Directive). Declared here (one header, three `.cpp` — IMPLEMENTATION-4.5 §1);
// defined in `SwitchValueEmit.cpp`.
void emitSwitchValueRegion(const ControlRegion &R, WidthDispatch &wd,
                           ControlledSymbols &csyms, TaintSet &taint);

// Lower an accepted all-`ConstantInt` data-mux switch region
// (`SwitchCls == DataMux`) — the preload + per-case XOR-delta controlled copy
// (NO route, NO ¬-bracket, NO reverse-play; the N-way generalization of the 4.4
// `select` controlled-XOR merge). `%out = cqrt_alloc_<W>(v_d)` preloads the
// default literal; per content case `%d_i = cqrt_alloc_<W>(v_i ^ v_d)` is the
// compile-time XOR-delta and `cqrt_copy_<W>_controlled(f_i, d_i, out)` writes it
// iff `q == c_i` (distinct literals ⇒ at most one flag set ⇒ `out = v_k`, or the
// preload `v_d` when none match). Mutates the module IR and `taint`. The shape is
// detection-guaranteed; any residual mismatch bails LOUDLY (never a silent skip of
// quantum-controlled flow — Prime Directive). Declared here (one header, three
// `.cpp` — IMPLEMENTATION-4.5 §1); defined in `SwitchDataMuxEmit.cpp`.
void emitSwitchDataMuxRegion(const ControlRegion &R, WidthDispatch &wd,
                             ControlledSymbols &csyms, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SWITCH_ROUTE_EMIT_H_
