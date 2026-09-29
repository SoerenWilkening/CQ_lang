/* slice_z0re_angle_select_runtime_base_exact.c — the Ry-stem angle select on an
   UNTAINTED RUNTIME base with angles whose difference is EXACT in binary64
   (A = .75, B = .25, A − B = .5), so its stream can be compared BYTE FOR BYTE with an
   independently cleared spelling (bd test_C_libtooling-z0re, Rule-13 r1B F-r1B-6).

     int t = m + 1; int r; if (q > 3) r = cq_theta(t, .75); else r = cq_theta(t, .25);

   `-O1` folds it to ONE `cq_theta(t, select(q > 3, .75, .25))`; z0re lowers it by
   difference: alloc(t); ry(h, .25); flag(q > 3); ry_controlled(f, h, .5); strip;
   free. The witness is slice_z0re_angle_select_runtime_base_exact_inplace.c — the
   same unitary written as an UNCONDITIONAL literal prep followed by an in-place
   controlled-Ry ARM on it (the drbq Inc-1 path, cleared code that predates z0re and
   produces its golden on the frozen ORACLE byte for byte) — pinned byte-identical by
   `e2e-z0re-angle-select-runtime-base-exact-inplace-identical`. The runtime value is
   `argc`-derived (m = argc + 4 = 5, t = 6). */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = m + 1;
    int r;
    r = cq_theta(t, (q > 3) ? 0.75 : 0.25);
    return cq_measure(r) + cq_measure(q);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
