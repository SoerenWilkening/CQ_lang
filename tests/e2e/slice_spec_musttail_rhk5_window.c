/* slice_spec_musttail_rhk5_window.c — bd test_C_libtooling-ev3m (2-TU, run_slice_multi.sh; library
   TU spec_musttail_rhk5_window_lib.c). Probe `ev9`.

   A clone call `t = g(q, k)` sits between `p = q * 3` and `p`'s phase consumer, and the function ENDS
   in `__attribute__((musttail)) return h2(p, z)` with `h2` ignoring `p`. On `main` 9a230646 the drop
   refused the `musttail` site, the call kept reading `p`, and `main` DECLINED at the 3jru return
   refusal; after bd ev3m the slot is `0`, the program compiles exactly like its plain-`tail`
   spelling — which, on that oracle, was bd rhk5's warned wrong unitary (`p` dirty across the Ry).
   bd rhk5 (9ad22639) fixed that class, so the stream is now the hand-inlined twin's circuit
   (`e2e-spec-musttail-rhk5-window-twin-equivalent`). `f`'s result is `z + 1` with `z` the sum of two
   trace-runtime measurements (0), so `main` returns `f(…) - 1` to exit 0 under the harness's
   `pipefail`. `m` comes from argv (argc + 4, bd 46oo). */
int g(int a, int k);
int h2(int a, int k);

__attribute__((noinline)) int f(int m, int k) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int t = g(q, k);
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    q = cq_theta(q, 0.7);
    int z = cq_measure(q) + cq_measure(t);
    __attribute__((musttail)) return h2(p, z);
}

int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    return f(m, m) - 1;
}
