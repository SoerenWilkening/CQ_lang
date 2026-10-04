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
/* slice_control_grover_loop_leading_gate_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_leading_gate.c (bd test_C_libtooling-8h7d.5, Rule-13
   round 4).

   Same body, twice, no loop. Its golden is the reference the rolled form is
   byte-diffed against (ctest entry e2e-grover-loop-leading-gate-twin-identical).

   THIS SIDE ALWAYS COMPILED CORRECTLY, and that is exactly what makes it the
   witness: the straight-line stream discharges both condition rails between the
   flag strip and the flag free, so the two traces differing was never a question
   of what the source asks for — it was the rolled form emitting a different
   circuit. Before the fix the rolled golden was SHORTER than this one by the two
   `cq_template_and_i32_hl_unc` / `cqrt_free` lines per iteration. */

#define CQ_LEADING_GATE_ITER                              \
    cq_theta(&a, 0.25);                                   \
    if ((a & 3) == 1) {                                   \
        cq_phi(3.14159265358979323846);                   \
    }                                                     \
    cq_theta(&a, -0.5);

int slice(void) {
    int a = 0;

    cq_theta(&a, 0.5);

    CQ_LEADING_GATE_ITER
    CQ_LEADING_GATE_ITER

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
