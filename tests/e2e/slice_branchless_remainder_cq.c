/* slice_branchless_remainder_cq.c — bd 3c6m.41 / 3c6m.48: the (c,q) taint mask of
   remainder. Each mask is a DISTINCT unitary (3c6m.48). slice_branchless_remainder.c
   pins (q,c) [x tainted, y=0.5 const, x/0.5 `_hl`]; THIS slice pins (c,q): x = 0.5
   CONSTANT, y = q TAINTED, so the quotient is `0.5 / y` — the `cq_template_fdiv_f64_lh`
   template. Same bremainder body (== corpus twin
   tools/library_coverage/branchless/remainder.c) — keep textually in sync. A PURE
   value-embedding (0 controlled rotations, 1 ry + 1 measure) backing the census
   `combinations` entry. Domain/accuracy identical to slice_branchless_remainder.c. */
static double bremainder(double x, double y) {
    return x - __builtin_rint(x / y) * y;              /* nearest-division rem    */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bremainder(0.5, q));             /* (c,q): x const, y tainted */
}
int main(void) { (void) slice(); return 0; }
