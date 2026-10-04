/* slice_branchless_fmod_cq.c — bd 3c6m.32 / 3c6m.48: the (c,q) taint mask of fmod.
   Each mask is a DISTINCT unitary (3c6m.48). slice_branchless_fmod.c pins (q,c) [x
   tainted, y=0.5 const, x/0.5 `_hl`]; THIS slice pins (c,q): x = 0.5 CONSTANT, y = q
   TAINTED, so the quotient is `0.5 / y` — the `cq_template_fdiv_f64_lh` template (the
   watched (c,q) fdiv_lh path). Same bfmod body (== corpus twin
   tools/library_coverage/branchless/fmod.c) — keep textually in sync. A PURE
   value-embedding (0 controlled rotations, 1 ry + 1 measure) backing the census
   `combinations` entry. Domain/accuracy identical to slice_branchless_fmod.c. */
static double bfmod(double x, double y) {
    return x - __builtin_trunc(x / y) * y;             /* truncated-division rem  */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bfmod(0.5, q));                  /* (c,q): x const, y tainted */
}
int main(void) { (void) slice(); return 0; }
