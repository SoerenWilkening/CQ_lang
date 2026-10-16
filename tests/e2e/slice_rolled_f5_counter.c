/* slice_rolled_f5_counter.c — CQ_FINDINGS F5 (bd test_C_libtooling-01po.19,
   01po.19.18 seeded accumulator, 01po.19.18.1 / 8h7d.25 rail-local nest): Dicke
   preparation by COUNTING, byte-identical below the comment to the reporter's
   f5.c, rolled over one quantum array and one quantum counter.

   Per outer trip i: for v = 0..2, `if (c == v)` mints a flag from the
   accumulator register (`cq_template_icmp_eq_i32_hl(h4, v)`), fires
   `cqrt_ry_i1_controlled(flag, q[i], 2 asin sqrt((2-v)/(4-i)))` (the classical
   ratio clamped to [0, 1] first), strips and frees the flag; then `c += q[i]` is
   `zext(q[i])` (two cast rails), the in-place `cqrt_add_i32(src, h4)`, and the
   two cast rails reversed and freed IN THE TRIP. `c` is minted once,
   `cqrt_alloc_i32(0) -> h4`.

   ANALYTIC CHECK (scratch state-vector replay of THIS golden; no simulator in the
   repo, owner decision 2026-06-10): the final state of q[0..3] is
   |D^4_2> = (|0011> + |0101> + |0110> + |1001> + |1010> + |1100>) / sqrt(6):
   exactly these six strings, each amplitude +0.408248, every other amplitude 0.
   The counter h4 holds 2 on every branch (the popcount of a weight-2 string), so
   it factors out. Every `cqrt_free` frees a |0> rail (20 of 20; stage 2b: 3 sites
   verified, 0 violations, 0 unproven; CENSUS: 2 rail-mint sites left allocated,
   the four cells and the counter, 0 template rails left dirty).
   The counter is DEAD after the loop and its sources are only measured, so it is
   left allocated and the pass warns (delegated ruling
   ruling-01po19-18-dead-accumulator-leak-warn-2026-10-16, option (a)).
   RETIREMENT TRIGGER: bd 8h7d.20's post-loop reverse loop returns h4 to |0>
   after the loop; this golden then gains its reverse trips and one free.
   The trace-only runtime measures 0, so the program prints 0000. */
#include <stdio.h>
#include <math.h>
#define N 4
#define K 2
int main(void) {
    bool q[N] = {0};
    int c = 0;
    for (int i = 0; i < N; i++) {
        for (int v = 0; v <= K; v++) {
            double p = (double)(K - v) / (N - i);
            if (p < 0) p = 0;
            if (p > 1) p = 1;
            if (c == v) cq_theta(&q[i], 2.0 * asin(sqrt(p)));
        }
        if (q[i]) c = c + 1;
    }
    for (int i = 0; i < N; i++) printf("%d", cq_measure(q[i]));
    printf("\n");
    return 0;
}
