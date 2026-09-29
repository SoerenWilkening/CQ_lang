/* slice_spec_musttail_rhk5_window_twin.c — the HAND-INLINED TWIN of slice_spec_musttail_rhk5_window.c
   (bd ev3m, probe `ev9T`): `t = q + k`, `return z + 1`, single TU, no specializer
   (`e2e-spec-musttail-rhk5-window-twin-equivalent`). */
__attribute__((noinline)) int f(int m, int k) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int t = q + k;
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    q = cq_theta(q, 0.7);
    int z = cq_measure(q) + cq_measure(t);
    return z + 1;
}

int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    return f(m, m) - 1;
}
