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
/* slice_control_grover_loop_range_oracle_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_range_oracle.c (bd test_C_libtooling-8h7d.5, Rule-13
   round 4, finding OD-A).

   Same body, twice, no loop. Its golden is the reference the rolled form is
   byte-diffed against (ctest entry e2e-grover-loop-range-oracle-twin-identical).

   THIS SIDE COMPILED AT HEAD while the rolled form declined, which is what
   identified the decline as a compiler over-decline rather than a property of the
   program: `clang -O1` emits the SAME `add %a, -6; icmp ult %t, 14`
   canonicalization here, and outside a loop nothing mistakes that temp for the
   loop-carried rail because there is no loop-carried rail to mistake it for. */

#define CQ_RANGE_ORACLE_ITER                              \
    if (a > 5 && a < 20) {                                \
        cq_phi(3.14159265358979323846);                   \
    }                                                     \
    cq_theta(&a, -0.5);

int slice(void) {
    int a = 0;

    cq_theta(&a, 0.5);

    CQ_RANGE_ORACLE_ITER
    CQ_RANGE_ORACLE_ITER

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
