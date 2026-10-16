/* slice_loop_acc_nested_counter.c — bd test_C_libtooling-01po.19.18, the SEEDED
   QUANTUM ACCUMULATOR (ir-pass/include/LoopAccumulator.h) under nested loops.

   `c` is loop-carried with the classical seed 0 and is updated each trip by the
   quantum source `a ^ i`: the register is minted once (`cqrt_alloc_i32(0) -> h1`)
   and each trip's step is the in-place `cqrt_add_i32(src, h1)`; the source
   `a ^ i` is a per-trip template rail reversed and freed IN ITS TRIP (`_unc`,
   `cqrt_free`). The inner v-loop's phase regions read the register through the
   compare flag (minted, `cqrt_rz_i1`, stripped, freed).

   ANALYTIC CHECK (scratch state-vector replay of THIS golden; no simulator in
   the repo, owner decision 2026-06-10). `a` = cos(.5)|0> + sin(.5)|1> on its low
   bit. Branch a=0: c = 0, 0, 1 at the three trips' compares, then 0^0, 0^1, 0^2
   added -> c = 3. Branch a=1: c = 0, 1, 1, adding 1^0, 1^1, 1^2 -> c = 4. On
   every trip, on each branch, exactly one of the two compares is true, so the
   trip's two kicks (e^{+i.15} on a true flag, e^{-i.15} on a false one) multiply
   to 1 on both branches: no relative phase. Final state
   0.877583|a=0,c=3> + 0.479426|a=1,c=4> (= cos .5, sin .5; replayed amplitudes
   real and positive), P = 0.770151 / 0.229849. Every `cqrt_free` frees a |0> rail (the 6 compare
   flags and the 3 xor rails, 9 of 9). The register h1 is MEASURED, never freed
   (R5); h0 (the user's `a`) stays allocated. The trace-only runtime measures 0,
   so the program prints `0 0`. */
#include <stdio.h>
int main(void) {
    int a = 0;
    cq_theta(&a, 1.0);
    int c = 0;
    for (int i = 0; i < 3; i++) {
        for (int v = 0; v < 2; v++)
            if (c == v) cq_phi(0.3);
        c += a ^ i;
    }
    printf("%d %d\n", cq_measure(c), cq_measure(a));
    return 0;
}
