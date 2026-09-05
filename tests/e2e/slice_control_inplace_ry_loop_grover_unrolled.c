/* 3qlq Inc 1: migrated to register-free cq_phi -- the Rz oracle arm loses its register; the controlled-Ry arm is untouched.

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
/* slice_control_inplace_ry_loop_grover_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_inplace_ry_loop_grover.c (two Grover iterations, no loop).

   IT IS THE ORACLE **AND** IT IS ITSELF NEW CAPABILITY, which makes it unlike the
   8h7d.5 twins: this program DECLINES on the pre-Increment-3 binary, at
   `ArmClassify`'s P1 fence, with no loop anywhere in it. Part 3b (the
   `SawRotationArm` disjunct) is what compiles it, and part 3a is what makes the
   rolled form agree with it byte for byte (ctest
   `e2e-inplace-ry-loop-grover-twin-identical`). */

#define CQ_PI 3.14159265358979323846

int slice(void) {
    int q = 0;
    int r = 7;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    if (q == 5) { cq_phi(CQ_PI); }
    if (q == 3) { r = cq_theta(r, 0.9); }
    q = cq_theta(q, -0.5);
    q = cq_theta(q, 0.5);

    if (q == 5) { cq_phi(CQ_PI); }
    if (q == 3) { r = cq_theta(r, 0.9); }
    q = cq_theta(q, -0.5);
    q = cq_theta(q, 0.5);

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
