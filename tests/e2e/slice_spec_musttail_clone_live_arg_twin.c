/* slice_spec_musttail_clone_live_arg_twin.c — the HAND-INLINED TWIN of
   slice_spec_musttail_clone_live_arg.c (bd m5pn, probe `mtlT`): `h`'s body written directly
   (`r = m + p`), single TU, no specializer. Its golden and the slice's must be the same circuit
   (`e2e-spec-musttail-clone-live-arg-twin-equivalent`). */
int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int r = m + p;
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    q = cq_theta(q, 0.7);
    return cq_measure(q) + cq_measure(r);
}
