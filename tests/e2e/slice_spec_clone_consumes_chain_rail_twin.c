/* slice_spec_clone_consumes_chain_rail_twin.c — the HAND-INLINED TWIN of
   slice_spec_clone_consumes_chain_rail.c (bd test_C_libtooling-rhk5): `h(m, p)` written
   as `p + 1`. The chain rails `3q` and `3q ^ q` are uncomputed and freed before the
   second Ry. Compared by `e2e-spec-clone-consumes-chain-rail-twin-equivalent`. */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int u = p ^ q;
    int s = p + 1;
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
