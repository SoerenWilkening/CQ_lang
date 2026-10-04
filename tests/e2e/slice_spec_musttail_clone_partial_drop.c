/* slice_spec_musttail_clone_partial_drop.c — bd test_C_libtooling-ev3m + bd m5pn (2-TU,
   run_slice_multi.sh; library TU spec_musttail_clone_partial_drop_lib.c). Probe `ev7`.

   `h(a, b, k)` forwards through `__attribute__((musttail))` to `h2`, which ignores `a` (a
   volatile-fold arm, dead at the drop's slot B) and READS `b`; `r = h(p, q, m)` is measured.
   The drop (bd ev3m) writes `0` into BOTH `musttail` slots for `a` — `h`'s call to `h2` and, one
   fixpoint turn later, `main`'s call to `h`; `h`'s clone then demotes its `musttail` call (bd
   m5pn: the Bennett wrap emits after it). On `main` 9a230646 the run ABORTED (exit 134). The
   stream is byte-identical to the plain-`tail` spelling's and — since bd rhk5 (9ad22639) — the
   hand-inlined twin's circuit (`e2e-spec-musttail-clone-partial-drop-twin-equivalent`).
   `m` comes from argv (argc + 4, bd 46oo). */
int h(int a, int b, int k);

int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    int q = m & 7; cq_theta(&q, 0.5);
    int p = q * 3;
    int r = h(p, q, m);
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    cq_theta(&q, 0.7);
    return cq_measure(q) + cq_measure(r);
}
