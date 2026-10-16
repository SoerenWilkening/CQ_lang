/* slice_loop_acc_nested_counter.c — bd test_C_libtooling-01po.19.18, the SEEDED
   QUANTUM ACCUMULATOR (ir-pass/include/LoopAccumulator.h) under nested loops.

   `c` is loop-carried with the classical seed 0 and is updated each trip by the
   quantum source `a ^ i`: the register is minted once (`cqrt_alloc_i32(0) -> h1`)
   and each trip's step is the in-place `cqrt_add_i32(src, h1)`; the source
   `a ^ i` is a per-trip template rail reversed and freed IN ITS TRIP (`_unc`,
   `cqrt_free`). The inner v-loop's phase regions read the register through the
   compare flag (minted, `cqrt_rz_i1`, stripped, freed).

   ANALYTIC CHECK (corrected R11 round 2 rA2-F2: `cqrt_ry_i32` rotates EVERY qubit
   of `a`, backend.md §11.3; the first text used a low-bit-only replay). Each bit of
   `a` is 1 independently with probability sin^2(.5) = 0.229849. On each basis
   branch c = (a^0) + (a^1) + (a^2) (mod 2^32): a = 0 -> 3, a = 1 -> 4, in general
   determined by a; the compare kicks are diagonal, so the measured pair (c, a)
   has exactly a's product distribution. Every `cqrt_free` frees a |0> rail (the 6 compare
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
