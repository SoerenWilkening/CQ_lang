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
/* slice_control_grover_loop_range_oracle.c — bd test_C_libtooling-8h7d.5, Rule-13
   ROUND 4, finding OD-A. A TWO-SIDED RANGE oracle inside the loop — the canonical
   Grover marking predicate, and the one the owner's own shape reaches for:

       for (i < 2) {
           if (a > 5 && a < 20) { cq_phi(PI); }   <-- mark the range
           cq_theta(&a, -0.5);
       }

   AT HEAD IT DECLINED, and its hand-unrolled twin compiled. `clang -O1`
   canonicalizes the range test to `%t = add %a, -6; icmp ult %t, 14`, so `%t`
   wears the dtzb IN-PLACE SHAPE (`V OP c`, add/xor, classical immediate) even
   though it is a derived-condition temp that will be lowered OUT of place (M-C's
   G5 refuses every site inside a loop body). Two guards read that shape as a
   fact:

     * the Rule-8 FAN-OUT guard counted `%t` beside the arm's real `cq_phi` and
       declined `cq loop lowering: loop-carried rail has multiple in-place
       consumers` — an over-decline of the owner's shape;
     * `markIfRailLocal`'s `onRail` peeled `%t` to the rail root and called it THE
       REGISTER, so `AnyLocal` stayed false, the body was never certified
       ITERATION-LOCAL, and the uncompute spine's acyclic backstop leaked the
       whole condition chain once per trip.

   Both now ask ONE predicate, `railValueConsumerDisposition`, which separates the
   SHAPE ("could be in place") from the DISPOSITION ("will be"). Only the
   PROVEN-out-of-place cell is dropped; the unproven straight-line cell still
   counts and still declines loudly
   (ir-pass/test/lowering_reject_inloop_control_rail_fanout.ll).

   WHY THE TWIN GATE IS THE POINT HERE. Fixing only the fan-out guard would have
   produced an ACCEPT whose trace differs from its twin's by the two missing
   discharge lines per trip — a green `opt`, a clean strict stage 2b, and a
   silently different circuit. The byte-diff against
   slice_control_grover_loop_range_oracle_unrolled is what makes "it lowers now" a
   claim about the UNITARY rather than about the exit code.

   STRICT stage 2b (no `--allow-unproven`). */

int slice(void) {
    int a = 0;

    cq_theta(&a, 0.5);                                   /* S */

    for (int i = 0; i < 2; ++i) {
        if (a > 5 && a < 20) {                           /* O: range oracle */
            cq_phi(3.14159265358979323846);
        }
        cq_theta(&a, -0.5);                              /* S-dagger */
    }

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
