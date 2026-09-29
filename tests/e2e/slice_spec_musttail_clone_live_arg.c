/* slice_spec_musttail_clone_live_arg.c — bd test_C_libtooling-m5pn (commit C of the nlfd/ev3m
   track; 2-TU, run_slice_multi.sh; library TU spec_musttail_clone_live_arg_lib.c). Probe `mtl`.

   `h` forwards its first argument through `__attribute__((musttail))` to `h2`, which READS it, and
   `r = h(p, m)` is measured. `h2`'s clone returns a quantum rail, so `h`'s clone's Bennett wrap
   copies it out AFTER the inner call; the `musttail` marker `CloneFunction` copied into `h`'s clone
   was then no longer followed by `ret` and the verifier ABORTED the whole run (exit 134 on `main`
   9a230646, measured). `stripStaleClassicalAttrs` now demotes a `musttail` call inside a clone to
   a plain call: the stream is byte-identical to the plain-`tail` spelling's, and — since bd rhk5
   (9ad22639) no longer lets a clone call inside a derived chain's discharge window keep `p = q * 3`
   entangled — it is the hand-inlined twin's circuit: `e2e-spec-musttail-clone-live-arg-twin-
   equivalent` (tools/trace_twin_equiv.py; byte identity is impossible for a quantum-returning clone,
   see that tool's header). `m` comes from argv (argc + 4, bd 46oo). */
int h(int a, int k);

int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int r = h(p, m);
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    q = cq_theta(q, 0.7);
    return cq_measure(q) + cq_measure(r);
}
