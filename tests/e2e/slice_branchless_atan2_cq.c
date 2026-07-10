/* slice_branchless_atan2_cq.c — bd 3c6m.48 / the (c,q) taint mask of atan2. The
   census (3c6m.48) certifies a multi-arg fn's COMPILES only if EVERY tainted-double
   combination lowers; each mask is a DISTINCT unitary. slice_branchless_atan2.c
   pins the (q,c) mask (y tainted, x=0.5 const — the x>0 half-plane, quadrant offset
   const-folds to +0.0). THIS slice pins the (c,q) mask: y=0.5 CONSTANT, x = q TAINTED.

   Two lowering paths the (q,c) golden never exercised:
     * y/x = 0.5/q is a LITERAL / HANDLE division → the `cq_template_fdiv_f64_lh`
       template (the (q,c) mask only ever emits `_hl`/`_qq` divisions).
     * the quadrant offset (x<0)?(y<0?-PI:PI):0 now has a TAINTED condition x<0
       (q<0): y<0 = 0.5<0 folds to false, so the offset is the tainted-condition
       const-select (q<0)?PI:0 — an x-TAINTED fp-DATA select controlled-copy merge
       (kjd1), where (q,c) had a fully const-folded (classical-x) offset.

   Same batan/batan2 body as slice_branchless_atan2.c (== corpus twins
   tools/library_coverage/branchless/{atan2,atan}.c) — keep all textually in sync.
   The trace is a PURE value-embedding (0 controlled rotations, balanced flag frees,
   1 ry + 1 measure); it is the linked proof that atan2's (c,q) mask lowers, backing
   the census `combinations` entry. Domain/accuracy identical to the atan2 slice; the
   x=0 axis is UNSPECIFIED (y/x=±inf → branchless atan → NaN). */

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
    double q = cq_theta(0.5, 0.5);
    return cq_measure(batan2(0.5, q));                   /* (c,q): y const, x tainted */
}
int main(void) { (void) slice(); return 0; }
