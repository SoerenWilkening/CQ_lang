/* 3qlq Inc 1: migrated to register-free cq_phi -- the three switch PHASE arms lose their register argument.
   NOTE: the S5 const-fold re-anchor scrub this slice's prose describes is RETIRED
   by PRD S6.2 P5 -- a register-free cq_phi has no arg-0 to fold.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_switch_phase.c — Phase 4.5 e2e smoke (WI-6,
   test_C_libtooling-bkpz.6): the RSSA swap-routed homogeneous-PHASE switch, the
   only test layer that LINKS and so the ONLY proof that the N-way phase switch
   emitter's symbol set (the eq-flag template cq_template_icmp_eq_i32_hl + its
   `_inv` strip, cqrt_cswap, the |0> rail alloc/free, the verbatim arm rz)
   resolves and signature-matches against libcq_runtime (Rule 2, Rule 16) —
   verify-clean and "runs without crashing" prove neither.

   SOURCE INTENT (homogeneous PHASE-arm switch, N=3 cases, empty default — the
   §4A / IMPLEMENTATION-4.5 ACCEPT shape, control_swap_switch_phase.ll is the
   pinned IR contract):
       q : tainted quantum handle (scrutinee, cq_theta == Ry, the sole source)
       switch (q) { case 0: cq_phi(.1); case 1: cq_phi(.2);
                    case 2: cq_phi(.3); }   // PHASE arms (cq_phi == Rz)
       measure q

   N>=3 deliberately: the byte-diff then exercises the N-way folded-gate scrub +
   N-way flatten (the §5 const-fold re-anchor BLOCKER's only downstream backstop).
   Each arm body is an opaque cq_phi CALL, so clang -O1 keeps the real `switch`
   (it cannot fold call-bearing arms to a select/lookup-table). -O1 ALSO const-
   folds each arm gate's arg-0 handle to its case literal — `cq_phi(i32 c_i, θ_i)`,
   NOT `cq_phi(i32 q, θ_i)` (the §5 re-anchor signature). The lowering re-anchors
   BY PHYSICS (cqrt_rz reads only arg-1/the angle; the folded arg-0 const is
   discarded and the folded gate is scrubbed+erased before RotationLowering — a
   surviving folded gate would RAUW to its const and degenerate the merge into a
   wrong data-mux, verify-clean-invisible with NO downstream backstop).

   Per content case i: mint the eq-flag f_i=(q==c_i) -> alloc a |0> work rail ->
   cqrt_cswap q into the rail under f_i -> replay θ_i VERBATIM/UNCONTROLLED on the
   rail -> cqrt_cswap back (join = adjoint of the split, same f_i) -> free the |0>
   rail (Rz|0>=|0>, a clean reset, NOT a hidden measurement) -> strip f_i with
   icmp_eq_inv(q) (q==q0, q is never routed) -> free f_i. ZERO controlled gates
   beyond the route cswaps; q (NOT the phi) is measured; RAUW merge->q.

   EXACTLY SIX frees (3 rails + 3 flags) — a SEVENTH would be a spurious uncompute
   free, a hidden measurement that collapses q (Rule 6). The runtime is trace-only
   and the diamond is flattened to straight-line code, so every emitted gate fires
   unconditionally regardless of q's value; cqrt_measure returns 0 (no simulation).
   The golden pins the trace captured from REAL linked output (templates BEFORE
   runtime — load-bearing link order). cq_theta/cq_phi/cq_measure resolve from
   CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);          /* taint q -> scrutinee handle (alloc, ry)   */
    switch (q) {                   /* tainted switch -> N-way swap-route phase   */
        case 0: cq_phi(0.1); break;   /* arm 0 (Rz) — VERBATIM on rail 0 */
        case 1: cq_phi(0.2); break;   /* arm 1 (Rz) — VERBATIM on rail 1 */
        case 2: cq_phi(0.3); break;   /* arm 2 (Rz) — VERBATIM on rail 2 */
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
