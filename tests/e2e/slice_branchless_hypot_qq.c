/* slice_branchless_hypot_qq.c — bd 3c6m.33 / 3c6m.48: the (q,q) taint mask of hypot,
   BOTH args tainted (two distinct cq_theta qubits — the general hypot(q0,q1) two-qubit
   case). The census (3c6m.48) certifies COMPILES only if every mask lowers; both |q0|
   and |q1| are tainted fabs, fmax/fmin route two handles, and lo/hi is a handle/handle
   fdiv. Same bhypot body (== corpus twin tools/library_coverage/branchless/hypot.c) —
   keep textually in sync. A PURE value-embedding (0 controlled rotations, 2 ry + 1
   measure) backing the census `combinations` entry. Domain/accuracy identical to
   slice_branchless_hypot.c. */
static double bhypot(double x, double y) {
    double ax = __builtin_fabs(x);
    double ay = __builtin_fabs(y);
    double hi = __builtin_fmax(ax, ay);                /* larger magnitude        */
    double lo = __builtin_fmin(ax, ay);                /* smaller magnitude       */
    double r  = lo / hi;                               /* r in [0,1], no overflow */
    return hi * __builtin_sqrt(1.0 + r * r);           /* overflow-safe hypot     */
}
double slice(void) {
    double q0 = cq_theta(0.5, 0.5);
    double q1 = cq_theta(0.5, 0.5);
    return cq_measure(bhypot(q0, q1));                 /* (q,q): both tainted     */
}
int main(void) { (void) slice(); return 0; }
