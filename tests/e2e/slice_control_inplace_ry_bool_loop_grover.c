/* slice_control_inplace_ry_bool_loop_grover.c — bd `test_C_libtooling-wx8g`:
   THE SENTENCE, COMPILED. `CLAUDE.md` records the l4x4.c over-decline's cost as
   TOTAL with these words — *"Grover as a rolled loop with a bool-controlled
   rotation or prep compiles in NO spelling on ANY binary"*. This is that
   program: one bool-controlled Ry on the register plus the S†/S reflection
   pair, per trip, rolled.

       bool b = 0; cq_theta(&b, .5);
       int  r = 7; cq_theta(&r, .25);
       for (k < K) { if (b) cq_theta(&r, .9);
                     cq_theta(&r, -.5); cq_theta(&r, .5); }

   The S†/S pair is what `slice_control_inplace_ry_loop_grover.c` uses on the
   COMPARE spelling, and it is load-bearing for the same reason there: it is a
   POST-REGION non-diagonal gate on the rotated register, so it exercises R6's
   per-activation certificate (`recordLivePerActivation`) rather than the flat
   `provablyBefore`.

   ⚠ THE CONDITION HERE IS THE `_Bool` ITSELF, so — unlike the compare slice —
   there is NO flag mint, NO `_unc` strip and NO `cqrt_free` anywhere in the
   stream. That absence IS the argument that retired the carve-out's second
   stated reason (the C-1 per-trip-chain leak family): a rail condition mints
   nothing for a rolled body to fail to discharge.

   Twin: slice_control_inplace_ry_bool_loop_grover_unrolled.expected.log, ctest
   `e2e-inplace-ry-bool-loop-grover-twin-identical`. STRICT stage 2b. */

#ifndef CQ_K
#define CQ_K 2
#endif

int slice(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int r = 7; cq_theta(&r, 0.25);
    for (int k = 0; k < CQ_K; ++k) {
        if (b) cq_theta(&r, 0.9);
        cq_theta(&r, -0.5);
        cq_theta(&r, 0.5);
    }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
