/* slice_control_multiexit_musttail_alloca.c — bd test_C_libtooling-dm7f.5, review
   round 1 F1 (probe p4). The musttail early return of slice_control_multiexit_musttail.c
   in a function that keeps an ALLOCA at -O1 (`buf`'s address reaches `sum2`): clang
   closes `buf`'s lifetime with `llvm.lifetime.end` before the plain `ret` and emits none
   before the `musttail` one. `unifyTaintedReturns` sinks that marker into the merged
   return block, exactly where the plain-return twin
   (slice_control_multiexit_musttail_alloca_twin.c) has it, so the two goldens are
   byte-identical (`e2e-control-multiexit-musttail-alloca-twin-identical`). Before the
   fix this module declined `value-arm swap-route` while its twin compiled. `f`'s quantum
   result is unused by `main` (bd 6gqw). `m` comes from argv (argc + 4, bd 46oo). */
__attribute__((noinline)) int k(int u, int a) { return a + 100; }
__attribute__((noinline)) int sum2(const int *p) { return p[0] + p[1]; }

__attribute__((noinline)) int f(int u, int a) {
    int buf[2] = {a, u};
    int s = sum2(buf);
    int q = u; cq_theta(&q, 0.5);
    if (q > 3) __attribute__((musttail)) return k(u, s);
    return 5;
}

int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    f(m, m);
    return 0;
}
