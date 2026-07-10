/* slice_branchless_tanh.c — bd 3c6m.47 / L1: a source-injected transcendental
   (Rule 18), landed by the L1 branchless-authored body spine. A BRANCHLESS
   soft-tanh is authored inline, so clang -O1 inlines it to stock reversible
   OPCODES and the taint pass lowers those (no per-fn cq_template_tanh).

   openlibm's tanh branches on |x| into four ranges (tiny / |x|<1 / 1≤|x|<22 /
   |x|≥22) to pick a cancellation-free reconstruction. This body keeps openlibm's
   OWN |x|<1 kernel — the expm1 identity, accurate near 0 with no `exp(x)-1`
   cancellation — and makes it valid for ALL |x|:

       tanh(|x|) = -t / (t + 2),   t = expm1(-2|x|)  ∈ (-1, 0]

   exact algebra, well-conditioned everywhere. The corpus twin
   (tools/library_coverage/branchless/tanh.c) CALLS expm1 (resolved by the census
   closure-link to branchless/expm1.c and inlined, mirroring s_tanh.c); here the
   same branchless expm1 kernel is inlined directly as the static `bexpm1` helper.

   Saturation without a branch: fmin(|x|, 20). tanh is 1.0 to full double
   precision for |x| ≥ 20, so clamping |x| to 20 changes nothing below and pins
   ±1 above — AND keeps expm1's arg -2·min(|x|,20) ∈ [-40,0] in-domain (a raw
   -2|x| would drive expm1 out of its valid range and return garbage for large
   |x|; the clamp is load-bearing for correctness). fabs/fmin/copysign are the
   hardware keep-set leaves; the only non-straight-line construct is expm1's
   round-bias fp select (the kjd1 controlled-copy merge). It exercises the
   p119.6 fp-select->fptosi merge AND p119.7 bitcast_i64_to_f64 (via expm1).

   Domain: all finite x. ±0 → ±0 (copysign preserves the sign); inf lands right
   but is UNSPECIFIED. Verified |output| ≤ 1 for every input, NO in-domain NaN,
   correct ±1 saturation. Accuracy ≤3.1 ulp vs host libm (true worst ~3.05 ulp
   near |x|≈0.125) — inherited from the branchless expm1 kernel (≤1.66 ulp on
   [-1,0]) amplified ~1.9× by the reconstruction (an EXACT expm1 into -t/(t+2)
   leaves ~0.05 ulp); the honest cost of reusing expm1 over a bespoke tanh minimax.

   The corpus twins are tools/library_coverage/branchless/{tanh,expm1}.c (same
   bodies) — keep the three textually in sync. */

/* the branchless expm1 kernel, inlined (== tools/library_coverage/branchless/expm1.c) */
static double bexpm1(double x) {
    const double ln2_hi = 6.93147180369123816490e-01;
    const double ln2_lo = 1.90821492927058770002e-10;
    const double invln2 = 1.44269504088896338700e+00;
    const double Q1 = -3.33333333333331316428e-02;
    const double Q2 =  1.58730158725481460165e-03;
    const double Q3 = -7.93650757867487942473e-05;
    const double Q4 =  4.00821782732936239552e-06;
    const double Q5 = -2.01099218183624371326e-07;

    double xn   = x * invln2;
    double half = (xn < 0.0) ? -0.5 : 0.5;             /* branchless round bias   */
    int    n    = (int)(xn + half);
    double dn   = (double)n;
    double hi   = x - dn * ln2_hi;
    double lo   = dn * ln2_lo;
    double r    = hi - lo;
    double c    = (hi - r) - lo;                        /* r_true ~= r + c         */

    double hfx = 0.5 * r;
    double hxs = r * hfx;
    double R1  = 1.0 + hxs * (Q1 + hxs * (Q2 + hxs * (Q3 + hxs * (Q4 + hxs * Q5))));
    double t   = 3.0 - R1 * hfx;
    double e   = hxs * ((R1 - t) / (6.0 - r * t));
    double ec  = r * (e - c) - c;                       /* openlibm c-folded corr. */
    double Pr  = r - ec + hxs;                          /* = expm1(r)              */

    long long bits = (long long)(n - 1 + 1023) << 52;   /* HALF scale (no n=1024 Inf) */
    double scale2;
    __builtin_memcpy(&scale2, &bits, 8);                /* bitcast i64->f64: 2^(n-1) */
    return 2.0 * (scale2 * Pr + (scale2 - 0.5));
}

static double btanh(double x) {
    double ax  = __builtin_fabs(x);                      /* odd fn: work on |x|   */
    double axc = __builtin_fmin(ax, 20.0);               /* saturate ≥20; keep    */
                                                         /* expm1 arg ≥ -40       */
    double t   = bexpm1(-2.0 * axc);                     /* e^{-2|x|} - 1 ∈ (-1,0] */
    double z   = -t / (t + 2.0);                         /* = tanh(|x|)           */
    return __builtin_copysign(z, x);                     /* keep-set leaf; odd fn */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(btanh(q));
}
int main(void) { (void) slice(); return 0; }
