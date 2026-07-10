/* slice_branchless_fdim_cq.c — bd 3c6m.16 / 3c6m.48: the (c,q) taint mask of fdim.
   The census (3c6m.48) certifies a multi-arg fn's COMPILES only if EVERY tainted-double
   combination lowers; each mask is a DISTINCT unitary. slice_branchless_fdim.c pins
   (q,c) [x tainted, y=0.5 const]; THIS slice pins (c,q): x = 0.5 CONSTANT, y = q TAINTED,
   so the difference is `0.5 - y` — the `cq_template_fsub_f64_lh` template (the (q,c)
   mask only emits `_hl`) then a keep-set fmax with 0. Same bfdim body (== corpus twin
   tools/library_coverage/branchless/fdim.c) — keep textually in sync. A PURE
   value-embedding (0 controlled rotations, 1 ry + 1 measure) backing the census
   `combinations` entry. Domain/accuracy identical to slice_branchless_fdim.c. */
static double bfdim(double x, double y) {
    return __builtin_fmax(x - y, 0.0);                 /* positive difference     */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bfdim(0.5, q));                  /* (c,q): x const, y tainted */
}
int main(void) { (void) slice(); return 0; }
