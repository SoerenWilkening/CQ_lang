/* slice_branchless_atan2.c — bd 3c6m.22 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-atan2 is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_atan2).

   openlibm's atan2 is a ladder of sign/zero/inf special cases around a single
   atan(y/x). This body computes the principal atan(y/x) once and adds the quadrant
   offset as a CONSTANT-operand select on the signs of x and y:

       atan2(y,x) = atan(y/x) + ( x<0 ? (y<0 ? -pi : +pi) : 0 )

   The offset arms are the literals {-pi,+pi,0}, so clang keeps them a `select` (an
   expensive-operand select would SimplifyCFG-branch-ify into tainted control flow —
   the atan N/D lesson). The corpus twin
   (tools/library_coverage/branchless/atan2.c) CALLS atan (resolved by the census
   closure-link to branchless/atan.c and inlined); here the same branchless atan
   kernel is inlined directly as the static `batan` helper.

   The probe fixes x = 0.5 (a positive CONSTANT), so the quadrant select const-folds
   to 0 and the body reduces to atan(y/0.5) = atan(2y) — the x>0 half-plane. The
   general quadrant logic is present and host-verified (long-double atan2l, all four
   quadrants, <=1.35 true-ulp, observed ~1.18); only the x>0 path is exercised by this trace, as the constant x
   dictates. The x=0 axis is UNSPECIFIED (y/x=+-inf -> branchless atan returns NaN).

   The corpus twins are tools/library_coverage/branchless/{atan2,atan}.c (same
   bodies) — keep the three textually in sync. */

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
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(batan2(q, 0.5));
}
int main(void) { (void) slice(); return 0; }
