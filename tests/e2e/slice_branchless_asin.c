/* slice_branchless_asin.c — bd 3c6m.19 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-asin is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_asin).

   openlibm's asin branches on |x| with a nested `if` ladder (e_asin.c:77 — the
   L6-nested-ctrl blocker). This body dissolves it with asin(x) = atan(x/√(1−x²)) and
   calls the branchless `atan` leaf (== branchless/atan.c), inlined here as the static
   `batan` helper (Cephes 3-segment branchless reduction — ONE unconditional division,
   constant-operand fp selects, p119.6 controlled-copy merge). atan is odd and carries
   the sign, so asin needs no extra copysign.

   *** THE fmax CLAMP KILLS THE |x|→1 NaN. *** 1−x² is clamped to a tiny positive
   floor, s = √(fmax(1−x², 1e-300)); at x=1 the argument becomes 1e150 (a large finite
   value in atan's big segment → atan≈π/2, finite), never the +∞ that would make the
   branchless atan leaf return NaN. So asin is FINITE and NaN-free across [−1,1].

   Domain: [−1,1] — asin(0)=0, asin(±1)=±π/2, odd. |x|>1 UNSPECIFIED (asin is complex;
   |x|>1 → finite ≈±π/2 out to |x| ≈ 1.8e158, beyond which the argument x/√TINY
   overflows and atan → NaN). Accuracy: the branchless atan
   leaf's ≤1.15 ulp, degrading as x→±1 (asin is intrinsically ill-conditioned there);
   trace-only runtime, so classical ulp is a sanity check, not a gate.

   The corpus twins are tools/library_coverage/branchless/{asin,atan}.c (same bodies;
   batan == branchless/atan.c) — keep the three textually in sync. */

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

static double basin(double x) {
    const double TINY = 1e-300;
    double s = __builtin_sqrt(__builtin_fmax(1.0 - x * x, TINY));
    return batan(x / s);
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(basin(q));
}
int main(void) { (void) slice(); return 0; }
