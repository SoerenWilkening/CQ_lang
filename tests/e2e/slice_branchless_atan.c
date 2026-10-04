/* slice_branchless_atan.c — bd 3c6m.21 / L1: a source-injected transcendental
   (Rule 18), landed by the L1 branchless-authored body spine. A BRANCHLESS
   soft-atan is authored inline, so clang -O1 inlines it to stock reversible
   OPCODES and the taint pass lowers those (no per-fn cq_template_atan).

   openlibm's atan selects one of five |x| segments with a table of atan(k/8)
   breakpoints. This body uses Cephes's THREE-segment argument reduction rendered
   fully branchless — the reduced arg xr = N/D is ONE unconditional division with
   N,D assembled from CONSTANT-operand selects (so clang keeps them `select`s, not
   branches: a division on a bare select arm would be SimplifyCFG-branch-ified
   back into tainted control flow), and the base angle is likewise a
   constant-operand select. Then Cephes's degree-4/5 rational R(z) on z=xr² as
   straight-line fmuladd + fdiv, and atan(|x|) = xr + xr·z·R(z) + base. The sign
   rides a final copysign (atan is odd) — the hardware keep-set leaf, exactly like
   slice_branchless_cbrt's fabs. It exercises the p119.6 fp-select controlled-copy
   merge (5 selects) plus the fabs/copysign keep-set leaves.

   Domain: all finite x (NaN-free through DBL_MAX). ±0 → ±0 (copysign preserves
   the sign); ±∞/NaN are UNSPECIFIED — concretely atan(±∞) returns NaN (0·∞ in the
   big-segment N=a·|x|+b), not ±π/2; the branchy special cases this body omits.
   Cephes's MOREBITS low-order correction is omitted (a no-op once folded into the
   double base angle). Accuracy ≤1.15 ulp vs host libm over a
   40M-point sweep on [-30,30] incl. dense scans across both reduction breakpoints
   (0.66, 2.4142) and the |x|→∞ tail.

   The corpus twin is tools/library_coverage/branchless/atan.c (same body) —
   keep the two textually in sync. */
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

    double y = big ? PIO2 : (mid ? PIO4 : 0.0);   /* MOREBITS omitted (see header) */

    double z = xr * xr;
    double pnum = (((P0 * z + P1) * z + P2) * z + P3) * z + P4;
    double pden = ((((z + Q0) * z + Q1) * z + Q2) * z + Q3) * z + Q4;
    double r = z * pnum / pden;
    double res = xr * r + xr + y;
    return __builtin_copysign(res, x);
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(batan(q));
}
int main(void) { (void) slice(); return 0; }
