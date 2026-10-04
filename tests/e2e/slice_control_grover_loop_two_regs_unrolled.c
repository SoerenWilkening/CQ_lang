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
/* slice_control_grover_loop_two_regs_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_two_regs.c: the identical body written out twice with
   no loop at all. Its golden must be BYTE-IDENTICAL to the rolled slice's
   (ctest entry e2e-grover-loop-two-regs-twin-identical), which is the strongest
   witness available to a project with no simulator (Rule 2): it says the rolled
   two-register form emits the same unitary, gate for gate and handle for handle,
   as a straight-line stream. Do not regenerate one golden without the other. */
#define CQ_PI 3.14159265358979323846
int slice(void) {
    int a = 0, b = 0;
    cq_theta(&a, 0.5);
    cq_theta(&b, 0.25);

    if (a == 5) { cq_phi(CQ_PI); }
    if (b == 3) { cq_phi(CQ_PI); }
    cq_theta(&a, -0.5);
    cq_theta(&b, -0.25);
    cq_theta(&a, 0.5);
    cq_theta(&b, 0.25);

    if (a == 5) { cq_phi(CQ_PI); }
    if (b == 3) { cq_phi(CQ_PI); }
    cq_theta(&a, -0.5);
    cq_theta(&b, -0.25);
    cq_theta(&a, 0.5);
    cq_theta(&b, 0.25);

    return cq_measure(a) + cq_measure(b);
}
int main(void) { (void) slice(); return 0; }
