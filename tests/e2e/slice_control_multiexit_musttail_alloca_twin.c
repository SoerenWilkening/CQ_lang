/* slice_control_multiexit_musttail_alloca_twin.c — bd test_C_libtooling-dm7f.5, review
   round 1 F1. The plain-return TWIN of slice_control_multiexit_musttail_alloca.c (no
   `musttail`): one `ret` block holding the merge phi and `buf`'s `lifetime.end`. Its
   golden must stay byte-identical to the musttail spelling's
   (`e2e-control-multiexit-musttail-alloca-twin-identical`). */
__attribute__((noinline)) int k(int u, int a) { return a + 100; }
__attribute__((noinline)) int sum2(const int *p) { return p[0] + p[1]; }

__attribute__((noinline)) int f(int u, int a) {
    int buf[2] = {a, u};
    int s = sum2(buf);
    int q = u; cq_theta(&q, 0.5);
    if (q > 3) return k(u, s);
    return 5;
}

int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    f(m, m);
    return 0;
}
