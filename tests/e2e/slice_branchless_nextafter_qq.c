/* slice_branchless_nextafter_qq.c — bd 3c6m.39 / 3c6m.48: the (q,q) taint mask of
   nextafter, BOTH args tainted (two distinct cq_theta qubits — the general
   nextafter(q0,q1) two-qubit case). The census (3c6m.48) certifies COMPILES only if
   every mask lowers; here y>x and y<x are handle/handle fcmp, sign(x) is a tainted bit
   shift, and bits(x)+step is a tainted integer add. Same bnextafter body (== corpus twin
   tools/library_coverage/branchless/nextafter.c) — keep textually in sync. A PURE
   value-embedding (0 selects -> 0 controlled rotations, 2 ry + 1 measure) backing the
   census `combinations` entry. Domain/accuracy identical to
   slice_branchless_nextafter.c. */

static double bnextafter(double x, double y) {
    unsigned long long ix;
    __builtin_memcpy(&ix, &x, 8);                      /* bitcast f64->i64        */
    long long up  = (long long)(y > x);                /* fcmp ogt -> zext (0/1)  */
    long long dn  = (long long)(y < x);                /* fcmp olt -> zext (0/1)  */
    long long dir = up - dn;                           /* +1 / -1 / 0 (value dir) */
    long long neg = (long long)(ix >> 63);             /* sign bit: 1 if x < 0    */
    long long step = dir * (1 - 2 * neg);              /* bit-pattern delta       */
    ix = ix + (unsigned long long)step;                /* one ULP toward y        */
    double out;
    __builtin_memcpy(&out, &ix, 8);                    /* bitcast i64->f64        */
    return out;
}
double slice(void) {
    double q0 = 0.5; cq_theta(&q0, 0.5);
    double q1 = 0.5; cq_theta(&q1, 0.5);
    return cq_measure(bnextafter(q0, q1));            /* (q,q): both tainted     */
}
int main(void) { (void) slice(); return 0; }
