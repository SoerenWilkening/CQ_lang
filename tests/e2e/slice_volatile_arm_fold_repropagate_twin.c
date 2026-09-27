/* slice_volatile_arm_fold_repropagate_twin.c — the fenv-intended TWIN of
   slice_volatile_arm_fold_repropagate.c (bd test_C_libtooling-vsfp ROUND 3 / bd otam,
   Rule-13 r2A `stale3cT`): the same program with the write-only `volatile` line removed.
   Its golden must stay byte-identical to the subject's
   (`e2e-volatile-arm-fold-repropagate-twin-identical`). */
__attribute__((noinline)) static int f(int x) { return x * 2 + 1; }

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m & 7, 0.5);
    int r;
    if (q > 3) {
        r = 5;
    } else {
        r = 9;
    }
    return cq_measure(f(r));
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
