/* slice_spec_predicted_classical_round2_twin.c — the HAND-INLINED twin of
   slice_spec_predicted_classical_round2.c (bd test_C_libtooling-3zr4): `h(y, m)`
   inlined to `g(y); int t = m + 1;` (5-TU, run_slice_multi.sh; library TUs
   spec_reading_{g,f2,f3}_lib.c and spec_round2_lib.c). It defines the correct circuit;
   `e2e-spec-predicted-classical-round2-twin-identical` pins the two goldens equal. */
void g(int a);
int ext_f(int a);
int g2(int a, int b);

__attribute__((noinline)) int slice(int m) {
    int q = m; cq_theta(&q, 0.5);
    int y = 0;
    if (q > 5) y = ext_f(7);
    g(y);
    int t = m + 1;
    int u = g2(t, q);
    return cq_measure(u) + cq_measure(q) + cq_measure(y);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
