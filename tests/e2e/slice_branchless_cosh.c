/* slice_branchless_cosh.c — bd 3c6m.26 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-cosh is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_cosh).

   openlibm's cosh branches on |x| into several ranges to avoid the large-|x|
   overflow of e^x while keeping cosh accurate near 1. This body keeps openlibm's
   OWN expm1 kernel and makes it valid for ALL |x| with the single overflow-safe
   identity (e = e^|x| = expm1(|x|) + 1):

       cosh(x) = 0.5 * ( e + 1/e ),   even fn (work on |x|)

   = 0.5*(e^|x| + e^-|x|). 1/e is bounded by 1 (no overflow at large |x|), valid to
   expm1's domain edge; near 0 the |x| terms cancel exactly (cosh's even symmetry),
   leaving the correct 1 + |x|^2/2. The corpus twin
   (tools/library_coverage/branchless/cosh.c) CALLS expm1 (resolved by the census
   closure-link to branchless/expm1.c and inlined, mirroring tanh->expm1); here the
   same branchless expm1 kernel is inlined directly as the static `bexpm1` helper.
   fabs is the hardware keep-set leaf; the only non-straight-line construct is
   expm1's round-bias fp select (the kjd1 accept shape).

   Domain: finite x with |x| <= ln(DBL_MAX) ~ 709.78 (expm1's range; cosh overflows
   near |x|>710.48 anyway). Beyond that, inf/NaN: UNSPECIFIED. cosh(+-0)=1. NaN-free
   on [-30,30] and the large band [700,709.7] (expm1's half-scale fix keeps the
   n=1024 band clean). Worst <=1.7 true-ulp (observed ~1.59) vs host long-double coshl (the branchless
   expm1 leaf, ~2 ulp, dominates; a host-expm1 sweep understates it).

   The corpus twins are tools/library_coverage/branchless/{cosh,expm1}.c (same
   bodies) — keep the three textually in sync (bexpm1 == branchless/expm1.c). */

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

static double bcosh(double x) {
    double e = bexpm1(__builtin_fabs(x)) + 1.0;          /* e^|x| (even fn)       */
    return 0.5 * (e + 1.0/e);                            /* = cosh(x), no OVF     */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bcosh(q));
}
int main(void) { (void) slice(); return 0; }
