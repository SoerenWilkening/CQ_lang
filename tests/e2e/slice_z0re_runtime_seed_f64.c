/* slice_z0re_runtime_seed_f64.c — a RUNTIME f64 state-prep seed (the r1B d88e
   probe zxdT, bd z0re's f64 member).

     double t = m + 1.0; double r = t; if (q2 > 3) r = cq_theta(t, .2);

   Expected stream: the dead `q = cq_theta(m, .5)` rail is reverse-played and KEPT
   (bd 5c5b, libcqops vmz9: `ry(h0, -.5)` restores its runtime birth value 2.5,
   not |0>, so a `cqrt_free(h0)` would be a dirty reset); then the flag from the
   i32 `q2 > 3`; `cqrt_alloc_f64(t)` with the RUNTIME double;
   `cqrt_ry_f64_controlled` under the flag; strip; free the flag; measure.
   The literal-fp precautionary decline (notes §9 item 24) is about an `fcmp oeq`
   edge pinning a LITERAL seed and is untouched; this condition is an integer
   compare and the seed is SSA-identical to the straight-through value.
   bd test_C_libtooling-z0re — OWNER RULING 2026-09-28, option (a): a RUNTIME
   state-prep seed (PRD §14.11 Q2, bd drbq.14) and an UNTAINTED Ry-stem angle-select
   base are admitted on the DIRECT path, so the hand-inlined twin and the
   spec-classical side door ACCEPT with the same circuit. The runtime value is
   `argc`-derived (the harness runs the slice with no arguments, so argc = 1) — a
   value `clang -O1` cannot fold, never a literal passed through a noinline call
   (bd 46oo: `-O1` const-propagates a literal argument). */
__attribute__((noinline)) int slice(double m, int n) {
    double q = cq_theta(m, 0.5);
    (void) q;
    double t = m + 1.0;
    int q2 = cq_theta(n, 0.3);
    double r = t;
    if (q2 > 3) r = cq_theta(t, 0.2);
    return (int) cq_measure(r) + cq_measure(q2);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 1.5, argc + 6);
    return 0;
}
