/* slice_branchless_hypot_cq.c — bd 3c6m.33 / 3c6m.48: the (c,q) taint mask of hypot.
   The census (3c6m.48) certifies COMPILES per taint mask. slice_branchless_hypot.c pins
   (q,c) [x tainted, y=0.5 const]; THIS slice pins (c,q): x = 0.5 CONSTANT, y = q TAINTED.
   Because hypot is SYMMETRIC and fmax/fmin COMMUTE, clang canonicalizes this to the SAME
   lowered stream as (q,c) — the golden is byte-identical to
   slice_branchless_hypot.expected.log. That coincidence is expected (a symmetric fn);
   this slice still independently LINKS the (c,q) mask (arg1-tainting lowers), the linked
   proof the census `combinations` entry needs. Same bhypot body (== corpus twin
   tools/library_coverage/branchless/hypot.c) — keep textually in sync. A PURE
   value-embedding (0 controlled rotations, 1 ry + 1 measure). Domain/accuracy identical
   to slice_branchless_hypot.c. */
static double bhypot(double x, double y) {
    double ax = __builtin_fabs(x);
    double ay = __builtin_fabs(y);
    double hi = __builtin_fmax(ax, ay);                /* larger magnitude        */
    double lo = __builtin_fmin(ax, ay);                /* smaller magnitude       */
    double r  = lo / hi;                               /* r in [0,1], no overflow */
    return hi * __builtin_sqrt(1.0 + r * r);           /* overflow-safe hypot     */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bhypot(0.5, q));                 /* (c,q): x const, y tainted */
}
int main(void) { (void) slice(); return 0; }
