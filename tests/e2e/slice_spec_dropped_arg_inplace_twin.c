/* slice_spec_dropped_arg_inplace_twin.c — the HAND-INLINED TWIN of
   slice_spec_dropped_arg_inplace.c (bd test_C_libtooling-hgwx / vsfp): `h`'s
   classical return written directly (`int t = m + 1;`), single TU, no specializer.
   Its golden must stay byte-identical to the 2-TU slice's
   (`e2e-spec-dropped-arg-inplace-twin-identical`). */
__attribute__((noinline)) int slice(int m) {
    int q = m; cq_theta(&q, 0.5);
    int t = m + 1;
    int u = t + q;
    int r = u;
    if (m > 3) { r = u; cq_theta(&r, 0.2); }
    return cq_measure(r);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
