/* slice_branchless_remainder_qq.c — bd 3c6m.41 / 3c6m.48: the (q,q) taint mask of
   remainder, BOTH args tainted (two distinct cq_theta qubits — the general
   remainder(q0,q1) two-qubit case). The census (3c6m.48) certifies COMPILES only if
   every mask lowers; this pins the quotient `q0 / q1` as the handle/handle
   `cq_template_fdiv_f64`, rint, then `q0 - rint*q1` with a handle/handle fmul. Same
   bremainder body (== corpus twin tools/library_coverage/branchless/remainder.c) —
   keep textually in sync. A PURE value-embedding (0 controlled rotations, 2 ry + 1
   measure) backing the census `combinations` entry. Domain/accuracy identical to
   slice_branchless_remainder.c. */
static double bremainder(double x, double y) {
    return x - __builtin_rint(x / y) * y;              /* nearest-division rem    */
}
double slice(void) {
    double q0 = 0.5; cq_theta(&q0, 0.5);
    double q1 = 0.5; cq_theta(&q1, 0.5);
    return cq_measure(bremainder(q0, q1));             /* (q,q): both tainted     */
}
int main(void) { (void) slice(); return 0; }
