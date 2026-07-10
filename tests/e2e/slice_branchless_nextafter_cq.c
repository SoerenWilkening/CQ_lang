/* slice_branchless_nextafter_cq.c — bd 3c6m.39 / 3c6m.48: the (c,q) taint mask of
   nextafter. Each mask is a DISTINCT unitary (3c6m.48). slice_branchless_nextafter.c
   pins (q,c) [x=q tainted, y=0.5 const]; THIS slice pins (c,q): x = 0.5 CONSTANT, y = q
   TAINTED. bits(x), sign(x) const-fold (x classical -> neg=0, step=+dir); the tainted
   part is dir = (q>0.5) - (q<0.5) driving bits(0.5) + dir. Same bnextafter body (==
   corpus twin tools/library_coverage/branchless/nextafter.c) — keep textually in sync.
   A PURE value-embedding (0 selects -> 0 controlled rotations, 1 ry + 1 measure) backing
   the census `combinations` entry. Domain/accuracy identical to
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
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bnextafter(0.5, q));            /* (c,q): x const, y tainted */
}
int main(void) { (void) slice(); return 0; }
