/* slice_control_inplace_ry_stateprep_negated.c — CONTROLLED STATE PREP whose arm
   is the FALSE successor, and THE ALLOC-POSITION WITNESS (PRD §14.1, bd
   test_C_libtooling-drbq Inc 4).

   `clang -O1` canonicalizes `if (q != 5)` to `icmp eq` with the successors
   SWAPPED (Rule 9), so the gate arm is the FALSE edge and the emitter brackets
   the controlled gate in the self-inverse `cqrt_x(f)` pair — the same bracket
   `emitRoute` puts around a negated route, so the two spellings of "fires on ¬f"
   cannot drift.

   ⚠ THIS IS THE ONLY PLACE THE ALLOC'S POSITION IS VISIBLE, AND THE POSITION IS
   A FIXED DESIGN DECISION RATHER THAN AN ACCIDENT. `lowerRotations` sets its
   insert point at the (hoisted) theta, and the emitter hoisted the theta BETWEEN
   the two brackets — so `cqrt_alloc_i32(0)` lands INSIDE the `cqrt_x` pair.
   Hoisting it to the top of the pred instead is ALSO correct physics (a
   fresh-rail alloc acts on a wire nothing else names, so it commutes with every
   gate that does not name its handle), but it would MOVE THIS GOLDEN. The
   position is therefore fixed here, and the §14.8 reduction is written to it.

   Note the alloc is not "inside a controlled region" in any physical sense: an
   allocation is unconditional in the emitted stream, and the `cqrt_x` pair
   flips the FLAG rail, not the prepped one. */
int slice(void) {
    int q = 3; cq_theta(&q, 0.3);
    int r = 0;
    if (q != 5) {                  /* -O1: `icmp eq` + swapped successors       */
        r = 0; cq_theta(&r, 0.9);
    }
    return (int) cq_measure(r) + (int) cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
