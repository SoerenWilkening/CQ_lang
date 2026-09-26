/* slice_volatile_arm_fold_cascade.c — bd test_C_libtooling-vsfp ROUND 4 / bd
   test_C_libtooling-1xp9 (single TU; Rule-13 r3B F-XB-1, probe `u5`). A CRASH regression slice.

   Two cascaded diamonds on CLASSICAL conditions; the second branch's condition `p` is an `i1`
   phi in the first diamond's merge. The fenv store erasure empties both arms, and
   `deleteDeadCones` folds both in one pass: fold 1 leaves `p` single-entry, merging the first
   merge block into its predecessor ERASES it, and bd vsfp rounds 2-3 then read it as a raw
   condition seed — SIGSEGV (exit 139) on a program the ORACLE compiles. Round 4 holds the seeds
   as `WeakTrackingVH`, which follow the phi to its replacement.

   Under the fenv ruling (and the owner's 2026-09-26 reachability ruling: a function-local
   volatile nothing outside the program can reach) this program MEANS
   slice_volatile_arm_fold_cascade_twin.c, and `e2e-volatile-arm-fold-cascade-twin-identical`
   pins this golden byte-identical to the twin's.

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, m = 5); `noinline`
   keeps `clang -O1` from folding it (bd 46oo). */
__attribute__((noinline)) int slice(int m) {
    _Bool a = m > 5, b = m < 2;
    int q = cq_theta(m & 7, 0.5);
    _Bool p;
    if (m > 3) {
        volatile int z = 1;
        p = a;
    } else {
        p = b;
    }
    if (p) {
        volatile int w = 2;
    }
    return cq_measure(q) + a + b;
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
