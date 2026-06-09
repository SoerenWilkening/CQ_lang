/* slice_control_phase_diamond.c — Phase 4.1 e2e smoke (WI-4): the RSSA
   swap-routed PHASE-arm diamond, the only test layer that LINKS and so proves
   every symbol the swap-route emitter mints resolves and signature-matches
   against the runtime (Rule 2, Rule 16).

   SOURCE INTENT (one-content-arm diamond, multi-gate PHASE arm — §5a):
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       if (q > 5) { q = cq_phi(q, a); q = cq_phi(q, b); }   // cq_phi == Rz, PHASE
       measure q

   The tainted `if (q > 5)` is NOT classical control over quantum state: the
   swap-route lowering mints the flag from the tainted icmp, CSWAPs q into a |0>
   work rail, runs the two arm Rz gates VERBATIM and UNCONTROLLED on the rail,
   CSWAPs the result back (the phi is the adjoint of the split, same flag), frees
   the |0> rail (Rz|0>=|0>, a clean reset — not a hidden measurement), then strips
   the boolean with icmp_inv(q) — ZERO controlled gates, NO `phi i32`, NO added
   measure (IMPLEMENTATION §5a, swap_route_if_diamond.ll is the pinned contract).

   The runtime is trace-only and the diamond is flattened to straight-line code,
   so every emitted gate fires unconditionally; the trace is fully deterministic
   regardless of q's value. cq_theta/cq_phi/cq_measure resolve from CQ.h,
   force-included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);          /* taint q -> handle (alloc i32(3), ry_i32) */
    if (q > 5) {                   /* tainted condition -> swap-route the arm    */
        q = cq_phi(q, 0.25);       /* arm gate 1 (Rz) — VERBATIM on the rail     */
        q = cq_phi(q, 0.75);       /* arm gate 2 (Rz) — VERBATIM on the rail     */
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
