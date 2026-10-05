// SwitchRouteEmit.h — the emitters for an accepted tainted `switch` region
// (4.5; PRD Part V §20; IMPLEMENTATION-4.5 §4/§5). The file name is history:
// nothing declared here routes (the swap route was retired by bd
// test_C_libtooling-3qlq). Dispatched from `SwapRouteEmit::lowerControlRegions`
// on a `SwitchRegion`, keyed by the per-content-class discriminator
// `ControlRegion::SwitchCls`.
//
// PHASE class — `emitSwitchPhaseRegion`. A homogeneous phase switch
// `switch(q){ case c_i: cq_phi(θ_i); }` (empty default, no merge φ) lowers by
// KICKBACK, emitted into the switch block before the `switch` terminator. Per
// content case `i`:
//   1. mint eq-flag   cq_template_icmp_eq_<W>_hl(q, c_i)            (CompareLowering)
//   2. phases         cqrt_rz_i1(f_i, θ_i) per arm `cq_phi`, in source order
//                     (eq-flags are positive-polarity — NO `cqrt_x` bracket)
//   3. flag strip     cq_template_icmp_eq_<W>_hl_unc(f_i, q, c_i)
//   4. flag free      cqrt_free(f_i)
// `q` is only ever a compare operand. The arm `cq_phi` calls are then scrubbed
// from `taint` and erased, and the N-way CFG is flattened (`flattenSwitchRegion`).
//
// Runs AFTER `detectControlRegions` and BEFORE `lowerRotations`, like every
// other control emitter, in BOTH orchestrator entry points. One header, three
// `.cpp`.

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
