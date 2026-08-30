/* slice_control_grover_loop_range_oracle.c — bd test_C_libtooling-8h7d.5, Rule-13
   ROUND 4, finding OD-A. A TWO-SIDED RANGE oracle inside the loop — the canonical
   Grover marking predicate, and the one the owner's own shape reaches for:

       for (i < 2) {
           if (a > 5 && a < 20) { a = cq_phi(a, PI); }   <-- mark the range
           a = cq_theta(a, -0.5);
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

    a = cq_theta(a, 0.5);                                /* S */

    for (int i = 0; i < 2; ++i) {
        if (a > 5 && a < 20) {                           /* O: range oracle */
            a = cq_phi(a, 3.14159265358979323846);
        }
        a = cq_theta(a, -0.5);                           /* S-dagger */
    }

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
