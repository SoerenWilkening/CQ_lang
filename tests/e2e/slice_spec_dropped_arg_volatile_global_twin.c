/* slice_spec_dropped_arg_volatile_global_twin.c — the HAND-INLINED, fenv-intended TWIN
   of slice_spec_dropped_arg_volatile_global.c (bd test_C_libtooling-vsfp ROUND 3, Rule-13
   r2B `k19F`): `h`'s classical return written directly (`int r = m + 1;`), the volatile
   read gone, single TU, no specializer. `p` keeps its one reader, the oracle's condition,
   so the spine uncomputes and frees its rail before the second Ry. Its golden must stay
   byte-identical to the 2-TU slice's
   (`e2e-spec-dropped-arg-volatile-global-twin-identical`). */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int r = m + 1;
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    q = cq_theta(q, 0.7);
    return r + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
