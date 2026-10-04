/* slice_spec_musttail_clone_partial_drop_twin.c — the HAND-INLINED TWIN of
   slice_spec_musttail_clone_partial_drop.c (bd ev3m + m5pn, probe `ev7T`): `r = m + q`, single TU,
   no specializer (`e2e-spec-musttail-clone-partial-drop-twin-equivalent`). */
int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    int q = m & 7; cq_theta(&q, 0.5);
    int p = q * 3;
    int r = m + q;
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    cq_theta(&q, 0.7);
    return cq_measure(q) + cq_measure(r);
}
