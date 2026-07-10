/* slice_branchless_acos.c — bd 3c6m.17 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-acos is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_acos).

   openlibm's acos branches on |x| with a nested `if` ladder (e_acos.c:71 — the
   L6-nested-ctrl blocker). This body dissolves it with acos(x) = π/2 − asin(x) and
   calls the branchless `asin` leaf (== branchless/asin.c), which itself closes to the
   branchless `atan` leaf (branchless/atan.c) — the two-level L2-closure spine, both
   inlined here as static `basin`/`batan` helpers. All range/NaN care lives in asin's
   fmax clamp (keeping 1−x² off zero at |x|→1); acos is one subtraction on top, so it
   too is finite and NaN-free on [−1,1].

   Domain: [−1,1] — acos(1)=0, acos(0)=π/2, acos(−1)=π; range [0,π]. |x|>1 UNSPECIFIED
   (inherits asin's out-of-domain behaviour: |x|>1 → finite 0 or π out to |x| ≈
   1.8e158, beyond which asin → NaN). Accuracy: asin's, plus the exactly-representable π/2 constant;
   trace-only runtime, so classical ulp is a sanity check, not a gate.

   The corpus twins are tools/library_coverage/branchless/{acos,asin,atan}.c (same
   bodies; basin == branchless/asin.c, batan == branchless/atan.c) — keep the four
   textually in sync. */

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
    int mid = ax > 0.66;

    double a = big ? 0.0 : 1.0;
    double b = mid ? -1.0 : 0.0;
    double c = mid ? 1.0 : 0.0;
    double d = big ? 0.0 : 1.0;
    double N = a * ax + b;
    double D = c * ax + d;
    double xr = N / D;

    double y = big ? PIO2 : (mid ? PIO4 : 0.0);

    double z = xr * xr;
    double pnum = (((P0 * z + P1) * z + P2) * z + P3) * z + P4;
    double pden = ((((z + Q0) * z + Q1) * z + Q2) * z + Q3) * z + Q4;
    double r = z * pnum / pden;
    double res = xr * r + xr + y;
    return __builtin_copysign(res, x);
}

/* the branchless asin kernel, inlined (== tools/library_coverage/branchless/asin.c) */
static double basin(double x) {
    const double TINY = 1e-300;
    double s = __builtin_sqrt(__builtin_fmax(1.0 - x * x, TINY));
    return batan(x / s);
}

static double bacos(double x) {
    return 1.57079632679489661923 - basin(x);            /* π/2 − asin(x)           */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bacos(q));
}
int main(void) { (void) slice(); return 0; }
