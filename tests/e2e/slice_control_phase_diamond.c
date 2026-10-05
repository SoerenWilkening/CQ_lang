/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, th)` -> `cq_phi(th)` at every site (branch phase by kickback).
   FLAG (PRD S6.3): the tainted arm now holds 2 cq_phi calls, which the Inc-1
   decline partition refuses ("an arm with N>1 cq_phi calls"). Expected
   post-increment class is a DECLINE, not an accept -- an owner call, not this
   migration's: the kickback needs no angle sum (two rz_i1 on the SAME flag are
   exact), so the N>1 refusal is a scoping choice, not a physics one.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_phase_diamond.c — Phase 4.1 e2e smoke (WI-4): the PHASE-arm
   diamond lowered by kickback, the only test layer that LINKS and so proves
   every symbol the kickback emitter mints resolves and signature-matches
   against the runtime (Rule 2, Rule 16).

   SOURCE INTENT (one-content-arm diamond, multi-gate PHASE arm — §5a):
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       if (q > 5) { cq_phi(a); cq_phi(b); }   // cq_phi == Rz, PHASE
       measure q

   The tainted `if (q > 5)` is NOT classical control over quantum state: the
   lowering mints the flag h1 = icmp_sgt(q, 5) into a fresh |0> ancilla, fires
   the two arm Rz gates VERBATIM and UNCONTROLLED on the flag as cqrt_rz_i1
   (the phase kicks back onto the q > 5 branch), strips the flag back to |0>
   with the compare's `_unc`, then frees it (a clean reset of a |0> rail, not a
   hidden measurement) — ZERO controlled gates, NO `phi i32`, NO cswap, NO added
   measure (control_swap_diamond.ll pins the same stream in lit).

   The runtime is trace-only and the diamond is flattened to straight-line code,
   so every emitted gate fires unconditionally; the trace is fully deterministic
   regardless of q's value. cq_theta/cq_phi/cq_measure resolve from CQ.h,
   force-included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);             /* taint q -> handle (alloc i32(3), ry_i32) */
    if (q > 5) {                   /* tainted condition -> kickback phase arm    */
        cq_phi(0.25);       /* arm gate 1 (Rz) — cqrt_rz_i1 on the flag   */
        cq_phi(0.75);       /* arm gate 2 (Rz) — cqrt_rz_i1 on the flag   */
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
