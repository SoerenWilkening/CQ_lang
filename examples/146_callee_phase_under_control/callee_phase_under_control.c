/* Rule 12: cq_phi deletion is scope-dependent. g()'s phase is unconditional INSIDE g, but g is called under a quantum
 * predicate, so it is a relative phase on that predicate: rz_i1(pred, p). h()'s phase is under a CLASSICAL condition
 * inside h, called under the same quantum predicate: rz_i1(pred, p) when f, nothing when !f. The top-level phase in
 * the entry is a global phase and is deleted. */
__attribute__((noinline)) static void g(double p) { cq_phi(p); }
__attribute__((noinline)) static void h(int f, double p) { if (f) cq_phi(p); }
int callee_phase_under_control(int x0, double tx, int k, double p, int f) {
    int x = x0;
    cq_theta(&x, tx);
    if (x > k) g(p);
    if (x > k) h(f, p);
    cq_phi(p);
    cq_theta(&x, -tx);
    return cq_measure(x);
}
