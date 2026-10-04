/* 3qlq Inc 1: migrated to register-free cq_phi -- every oracle / reflection arm's `q = cq_phi(q, PI)` -> `cq_phi(PI)`.

   FINDING (PRD S1, measured 2026-09-05 at HEAD 52d7764): the PRE-3qlq golden of
   this slice encoded a CONTROLLED TENSORED Rz, which is the IDENTITY on q --
   `cqrt_rz_<W>` is "Rz on each qubit", so the marked phase is (-1)^popcount(target)
   (= +1 for |5>) and a per-qubit diagonal gate FIXES |0..0>, so the |0> reflection
   can never put -1 there. Any claim in the prose below that the oracle marks |5>,
   or that the reflection reflects about |0>, was TRUE OF THE SOURCE and FALSE OF
   THE EMITTED CIRCUIT. It becomes true only from 3qlq Inc 1 on, where the phase is
   a BRANCH phase by kickback (rz_i1 on the minted flag), not a register Rz. The
   older prose is left verbatim rather than silently corrected; read it with this.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_grover_loop_offset_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_offset.c (bd test_C_libtooling-8h7d.5).

   Same body, twice, no loop, so the in-place `cqrt_addc_i32` stream it produces
   is the one round 1 / the straight-line M-C fence already ship. The `cmp`
   against the rolled golden is ctest entry e2e-grover-loop-offset-twin-identical. */

#define CQ_PI 3.14159265358979323846

volatile int cq_off = 3;

#define CQ_OFFSET_ITER                       \
    if (q == 5) { cq_phi(CQ_PI); }           \
    cq_theta(&q, -0.5);                      \
    q += cq_off;                             \
    cq_theta(&q, 0.5);

int slice(void) {
    int q = 0;

    cq_theta(&q, 0.5);
    q += cq_off;

    CQ_OFFSET_ITER
    CQ_OFFSET_ITER

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
