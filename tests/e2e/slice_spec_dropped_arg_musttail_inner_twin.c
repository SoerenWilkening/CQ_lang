/* slice_spec_dropped_arg_musttail_inner_twin.c — the HAND-INLINED, fenv-intended TWIN of
   slice_spec_dropped_arg_musttail_inner.c (bd test_C_libtooling-vsfp ROUND 6 / bd w7nm, r5 `mtT`):
   `h`'s classical return written directly (`int r = m + 1;`), single TU, no specializer. Its
   golden must stay byte-identical to the 2-TU slice's
   (`e2e-spec-dropped-arg-musttail-inner-twin-identical`). */
__attribute__((noinline)) int slice(int m) {
    int q = m & 7; cq_theta(&q, 0.5);
    int p = q * 3;
    int r = m + 1;
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    cq_theta(&q, 0.7);
    return r + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
