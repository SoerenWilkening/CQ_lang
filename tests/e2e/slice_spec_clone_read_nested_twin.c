/* slice_spec_clone_read_nested_twin.c — the HAND-INLINED TWIN of
   slice_spec_clone_read_nested.c (bd test_C_libtooling-rhk5): `h(m, q)` written as
   `(q * 5) ^ q`. Compared by `e2e-spec-clone-read-nested-twin-equivalent`. */
__attribute__((noinline)) int slice(int m) {
    int q = m & 7; cq_theta(&q, 0.5);
    int p = q * 3;
    int u = p ^ q;
    int s = (q * 5) ^ q;
    if (u == 10)
        cq_phi(3.14159);
    int ms = cq_measure(s);
    cq_theta(&q, 0.7);
    return ms + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
