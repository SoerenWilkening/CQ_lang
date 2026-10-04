/* slice_volatile_arm_fold_cascade_twin.c — the fenv-intended TWIN of
   slice_volatile_arm_fold_cascade.c (bd test_C_libtooling-vsfp ROUND 4 / bd 1xp9, r3B `u5T`):
   the same program with the two unobservable `volatile` lines removed. Its golden must stay
   byte-identical to the subject's (`e2e-volatile-arm-fold-cascade-twin-identical`). */
__attribute__((noinline)) int slice(int m) {
    _Bool a = m > 5, b = m < 2;
    int q = m & 7; cq_theta(&q, 0.5);
    _Bool p;
    if (m > 3) {
        p = a;
    } else {
        p = b;
    }
    (void)p;
    return cq_measure(q) + a + b;
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
