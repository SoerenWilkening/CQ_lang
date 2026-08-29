/* slice_control_grover_loop_derived.c — bd test_C_libtooling-8h7d.5 (Phase 7.3
   Increment 3) e2e: THE CUSTOMER PROGRAM. Two Grover iterations as a `for` loop,
   with a DERIVED oracle condition.

   This is example/grover/grover_oracle_uncompute.c, in the house slice style. At
   HEAD 7ba8b2d it exited 1 with
       cq opcode lowering: operand predates a non-diagonal gate
   on the `sitofp` of the loop-header phi — the register the oracle reads is
   re-bound every trip, but the position proof could not say so and read the
   body's own S-dagger Ry as a staler.

   ITS GOLDEN IS BYTE-IDENTICAL to slice_control_grover_loop_derived_unrolled's
   (ctest entry e2e-grover-loop-derived-twin-identical), and for THIS program that
   is a much stronger statement than for the direct-oracle pair, because the
   derived condition brings the uncompute spine into it:

     * `sqrt(a + 3.)` builds THREE template rails, each entangled with the
       register. If they are still allocated when the S-dagger `cqrt_ry` fires,
       the rotation is dephased — a realizable unitary, but not the author's.
     * Getting them discharged INSIDE the iteration needed four `canRepeat`
       fences and three `provablyBefore` readings in Uncomputation.cpp to be
       re-asked PER ACTIVATION, each gated on an affirmative `IterationLocalBlocks`
       mark. Before that work the rolled form leaked three rails per trip and
       warned twice where its twin warned not at all — the trace differed from the
       twin's by exactly the six missing discharge lines.

   So the byte-diff here is not a formality: it is the evidence that the rolled
   loop and the cleared straight-line stream are the same circuit.

   WATCH WHAT clang -O1 DOES (Rule 9): `<= 3.5` is emitted as `fcmp ugt` with the
   gate arm as the FALSE successor, so the route is `cqrt_x`-bracketed; and the
   `a == 0` arm arrives as `cq_phi(0, PI)` because the register was
   value-propagated to the literal inside the arm.

   STRICT stage 2b (no `--allow-unproven`). */

#include <math.h>

int slice(void) {
    int a = 0;

    a = cq_theta(a, 0.5);                                /* S */

    for (int i = 0; i < 2; ++i) {
        if (sqrt(a + 3.) <= 3.5) {                       /* O: derived oracle */
            a = cq_phi(a, M_PI);
        }
        a = cq_theta(a, -0.5);                           /* S-dagger */
        if (a == 0) {                                    /* R0 */
            a = cq_phi(a, M_PI);
        }
        a = cq_theta(a, 0.5);                            /* S */
    }

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
