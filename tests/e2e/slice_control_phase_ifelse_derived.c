/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, th)` -> `cq_phi(th)` at every site (branch phase by kickback).
   FLAG (PRD S6.3): the tainted arm now holds 2 cq_phi calls, which the Inc-1
   decline partition refuses ("an arm with N>1 cq_phi calls"). Expected
   post-increment class is a DECLINE, not an accept -- an owner call, not this
   migration's: the kickback needs no angle sum (two rz_i1 on the SAME flag are
   exact), so the N>1 refusal is a scoping choice, not a physics one.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_phase_ifelse_derived.c — Phase 4.1 follow-on e2e smoke
   (test_C_libtooling-9hh): a two-arm PHASE if/else after an UNCONDITIONAL
   pre-region cq_phi (pre-3qlq, its result was the DERIVED routed base). The
   only test layer that LINKS, so it proves the accept emits exactly the
   symbol set the runtime resolves (Rule 2, Rule 16).

   SOURCE INTENT (unconditional pre-region phase + two-arm phase if/else —
   §5b):
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       cq_phi(0.9);                          // UNCONDITIONAL pre-region Rz
       if (q > 5) { cq_phi(0.25); cq_phi(0.125); }  // then arm (flag)
       else       { cq_phi(0.75); }                 // else arm (¬flag, X-bracket)
       measure q

   The arms are deliberately ASYMMETRIC (two gates vs one): with ONE gate per
   arm, clang -O1 SimplifyCFG sinks the two calls into ONE `cq_phi` on a
   tainted-condition ANGLE SELECT (`select i1, double a, double b`) — a
   different shape, pinned by slice_control_phase_angle_select.c (Rule 9:
   never assume the CFG survives -O1). Unequal gate counts cannot be
   hoisted/sunk, so the genuine if/else diamond reaches the pass.

   The pre-region cq_phi is UNCONTROLLED, so it is a global phase and is
   DELETED: the trace has no Rz for 0.9. The arms lower by kickback on ONE
   flag f = icmp_sgt(q,5) minted into a fresh |0> ancilla: the then arm's
   two Rz fire UNCONTROLLED on f as cqrt_rz_i1, the else arm's Rz fires on
   ¬f (cqrt_x-bracketed), then the compare `_unc` strips f back to |0> and
   ONE cqrt_free releases it (a clean reset, not a hidden measurement).
   ZERO controlled gates, NO cswap, NO `phi i32`, NO added measure; the
   user's measure reads q (h0).

   The runtime is trace-only and the region is flattened to straight-line code,
   so every emitted gate fires unconditionally; the trace is fully deterministic
   regardless of q's value. cq_theta/cq_phi/cq_measure resolve from CQ.h,
   force-included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);             /* taint q -> handle (alloc i32(3), ry_i32)  */
    cq_phi(0.9);            /* pre-region Rz — global phase, deleted     */
    if (q > 5) {                   /* tainted condition -> kickback on one flag */
        cq_phi(0.25);       /* then gate 1 (Rz) — cqrt_rz_i1 on the flag */
        cq_phi(0.125);      /* then gate 2 (Rz) — cqrt_rz_i1 on the flag */
    } else {
        cq_phi(0.75);       /* else gate (Rz) — rz_i1 on ¬flag (X-bracket) */
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
