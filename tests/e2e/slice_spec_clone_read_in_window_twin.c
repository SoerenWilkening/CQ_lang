/* slice_spec_clone_read_in_window_twin.c — the HAND-INLINED TWIN of
   slice_spec_clone_read_in_window.c (bd test_C_libtooling-rhk5): `h(m, q)` written as
   `q + 1`, single TU, no specializer. It defines the correct circuit: the derived
   chain `3q`, `3q ^ q` is uncomputed and freed before the second Ry. Its golden is
   compared with the 2-TU golden by `e2e-spec-clone-read-in-window-twin-equivalent`
   (tools/trace_twin_equiv.py — not a byte diff; see the subject's header). */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int u = p ^ q;
    int s = q + 1;
    if (u == 10)
        cq_phi(3.14159);
    int ms = cq_measure(s);
    q = cq_theta(q, 0.7);
    return ms + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
