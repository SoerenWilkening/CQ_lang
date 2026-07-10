/* slice_branchless_atan2_qq.c — bd 3c6m.48 / the (q,q) taint mask of atan2. The
   census (3c6m.48) certifies a multi-arg fn's COMPILES only if EVERY tainted-double
   combination lowers; each mask is a DISTINCT unitary. This slice pins the FULLY
   tainted mask: BOTH y = q0 and x = q1 are tainted, from TWO DISTINCT cq_theta
   sources (the general atan2(q0,q1) case — two independent qubits, not an aliased
   single qubit).

   The paths the (q,c) and (c,q) masks never jointly exercised:
     * y/x = q0/q1 is a HANDLE / HANDLE division → the `cq_template_fdiv_f64` (qq)
       template with two distinct tainted operands.
     * the quadrant offset (x<0)?(y<0?-PI:PI):0 now has BOTH conditions tainted
       (q1<0 and q0<0) → a NESTED tainted-condition const-select: the inner
       (q0<0)?-PI:PI merge feeds the outer (q1<0)?inner:0 merge. Both are
       fp-DATA select controlled-copy merges (kjd1) over the {-PI,+PI,0} literals.

   Same batan/batan2 body as slice_branchless_atan2.c (== corpus twins
   tools/library_coverage/branchless/{atan2,atan}.c) — keep all textually in sync.
   The trace is a PURE value-embedding (0 controlled rotations, balanced flag frees,
   2 ry from the two sources + 1 measure); it is the linked proof that atan2's (q,q)
   mask lowers, backing the census `combinations` entry. Both qubits feed the single
   measured result. Domain/accuracy identical to the atan2 slice; the x=0 axis is
   UNSPECIFIED (y/x=±inf → branchless atan → NaN). */

/* the branchless atan kernel, inlined (== tools/library_coverage/branchless/atan.c) */
static double batan(double x) {
    const double T3P8 = 2.41421356237309504880;
    const double PIO2 = 1.57079632679489661923;
    const double PIO4 = 0.78539816339744830962;
    const double P0 = -8.750608600031904122785e-1;
    const double P1 = -1.615753718733365076637e1;
    const double P2 = -7.500855792314704667340e1;
    const double P3 = -1.228866684490136173410e2;
    const double P4 = -6.485021904942025371773e1;
    const double Q0 =  2.485846490142306297962e1;
    const double Q1 =  1.650270098316988542046e2;
    const double Q2 =  4.328810604912902668951e2;
    const double Q3 =  4.853903996359136964868e2;
    const double Q4 =  1.945506571482613964425e2;

    double ax = __builtin_fabs(x);
    int big = ax > T3P8;
    int mid = ax > 0.66;                                 /* big implies mid       */

    double a = big ? 0.0 : 1.0;
    double b = mid ? -1.0 : 0.0;
    double c = mid ? 1.0 : 0.0;
    double d = big ? 0.0 : 1.0;
    double N = a * ax + b;
    double D = c * ax + d;
    double xr = N / D;                                   /* ONE division          */

    double y = big ? PIO2 : (mid ? PIO4 : 0.0);

    double z = xr * xr;
    double pnum = (((P0 * z + P1) * z + P2) * z + P3) * z + P4;
    double pden = ((((z + Q0) * z + Q1) * z + Q2) * z + Q3) * z + Q4;
    double r = z * pnum / pden;
    double res = xr * r + xr + y;
    return __builtin_copysign(res, x);
}

static double batan2(double y, double x) {
    const double PI = 3.14159265358979311600;            /* nearest double to pi   */
    double off = (x < 0.0) ? (y < 0.0 ? -PI : PI) : 0.0; /* constant-operand select */
    return batan(y / x) + off;                           /* one division -> atan    */
}
double slice(void) {
    double q0 = cq_theta(0.5, 0.5);
    double q1 = cq_theta(0.5, 0.5);
    return cq_measure(batan2(q0, q1));                   /* (q,q): both tainted   */
}
int main(void) { (void) slice(); return 0; }
