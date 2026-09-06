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
/* slice_control_grover_loop_leading_gate.c — bd test_C_libtooling-8h7d.5,
   Rule-13 ROUND 4, finding F-4. The rolled loop whose body puts a
   BASIS-RELABELLING GATE BEFORE the tainted region.

   Every loop slice shipped before this one puts the region FIRST in the body:
   `if (…) { … } a = cq_theta(a, -0.5);`. That is one cell of a matrix, and it is
   the cell where the finding is invisible. Move ONE gate to the front of the body
   and the M-B interior partition stops discharging the oracle's ancilla chain:

       for (i < 2) {
           a = cq_theta(a, 0.25);        <-- the LEADING Ry: the whole finding
           if ((a & 3) == 1) { cq_phi(PI); }
           a = cq_theta(a, -0.5);
       }

   WHY. The interior partition proves clause (d1) — "the borrowed parent holds, at
   every emitted `_unc`, the value it held when the forward gate ran" — over the
   window between the first recovered gate and the discharge point. The mutation
   of the parent it must place here is the NEXT iteration's leading `cqrt_ry`,
   which sits textually BEFORE that first gate, so it does not dominate anything
   the shipped legs asked about and every leg failed. The component was abandoned:
   `cq_template_and_i32_hl(%h, 3)` was minted, never `_unc`-reversed, never freed,
   and the trailing S-dagger `cqrt_ry` then fired over a LIVE, ENTANGLED record of
   its own register — Rule 8's dirty-entangled-rail dephasing, i.e. a different
   unitary from the one this source asks for.

   AND NOTHING IN THE 285-ENTRY SUITE SAW IT. `opt` exited 0, `opt -verify` was
   clean, STRICT stage 2b reported zero violations (it counts `cqrt_alloc` mints,
   and this rail is TEMPLATE-minted — see tools/free_pairing_check.py's header),
   and with a leading Ry rather than a leading Rz there was not even an M-A
   warning. The ONLY witness is the hand-unrolled twin, which discharges the
   chain, which is why this pair ships with the byte-diff gate
   e2e-grover-loop-leading-gate-twin-identical and why the whole prefix × region ×
   suffix matrix is now a ctest entry (tools/loop_twin_matrix.py).

   Integer-only on purpose: the `& 3` mask keeps the derived condition to two
   template rails, so the missing discharge is two trace lines rather than eight
   and a reader can see it at a glance.

   STRICT stage 2b (no `--allow-unproven`). */

int slice(void) {
    int a = 0;

    a = cq_theta(a, 0.5);                                /* S */

    for (int i = 0; i < 2; ++i) {
        a = cq_theta(a, 0.25);                           /* the LEADING gate */
        if ((a & 3) == 1) {                              /* derived oracle */
            cq_phi(3.14159265358979323846);
        }
        a = cq_theta(a, -0.5);                           /* S-dagger */
    }

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
