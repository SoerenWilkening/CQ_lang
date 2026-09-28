/* slice_spec_predicted_classical_round2.c — bd test_C_libtooling-3zr4, end to end
   (6-TU, run_slice_multi.sh; library TUs spec_reading_{h,g,f2,f3}_lib.c and
   spec_round2_lib.c).

   `y` is a 6.5 classical-call-arm merge `%out` (`if (q > 5) y = ext_f(7);`), so it is
   tainted only in ROUND 2 and `h(y, m)` is a ROUND-2 Phase-6 site, while `g2(t, q)` is
   a ROUND-1 site that reads its result. `h` READS `y` (through `g`) and returns the
   CLASSICAL `m + 1`. On the oracle (main 9a230646) the round-2 drain tainted `t`
   conservatively, `g2`'s mask grew to `11`, its clone was built with `t` in a HANDLE
   slot, `specialize()` then scrubbed `t`, and bd l3oi's clone-reader clause declined
   (`classical call result used as a quantum register`). Since bd cepm every drain —
   the round-2 one included — asks `predictReturnTainted`, so `t` is never tainted,
   `g2`'s mask stays `10`, and `t` rides its clone's literal slot.

   The CORRECT circuit is the hand-inlined twin's (slice_spec_predicted_classical_
   round2_twin.c: `g(y); int t = m + 1;`); `e2e-spec-predicted-classical-round2-twin-
   identical` pins the two goldens BYTE-IDENTICAL.

   `m` = argc + 4 = 5 under the harness; `noinline` keeps `-O1` from folding it (bd
   46oo). */
int h(int a, int k);
int ext_f(int a);
int g2(int a, int b);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int y = 0;
    if (q > 5) y = ext_f(7);
    int t = h(y, m);
    int u = g2(t, q);
    return cq_measure(u) + cq_measure(q) + cq_measure(y);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
