/* slice_branchless_expm1.c — bd 3c6m.10 / L1: a source-injected transcendental
   (Rule 18), landed by the L1 branchless-authored body spine. A BRANCHLESS
   soft-expm1 is authored inline, so clang -O1 inlines it to stock reversible
   OPCODES and the taint pass lowers those (no per-fn cq_template_expm1).

   openlibm's expm1 branches per range-reduction quotient k to compute
   2^k*e^r - 1 without cancellation. This branchless body keeps openlibm's
   ACCURATE primary kernel (the Q1..Q5 rational R(r) giving expm1(r)=e^r-1 to
   <1 ulp) and replaces the whole k-case reconstruction thicket with the single
   cancellation-free identity

       expm1(x) = 2^n*(1 + expm1(r)) - 1 = 2*(2^(n-1)*Pr + (2^(n-1) - 0.5)),

   Pr = expm1(r). The "-1" is folded into the scale (never `exp(x) - 1`) so there
   is no catastrophic cancellation for any n; for n==0 the result is expm1(r)
   directly. The reconstruction uses the HALF scale 2^(n-1) so the exponent field
   never overflows to +Inf at n==1024 (x in [709.44, 709.78], expm1 finite up to
   DBL_MAX) — the branchless equivalent of openlibm's k==1024 case. The ONLY
   non-straight-line construct is exp's round-bias fp select `(xn<0)?-0.5:0.5`
   (the kjd1 accept shape, identical to slice_branchless_exp) — NO
   tables/control/scratch. It exercises the p119.6 fp-select->fptosi merge AND
   the p119.7 cq_template_bitcast_i64_to_f64 for the 2^(n-1) scale.

   Domain: finite x in [-708, 709.78]. Overflow / underflow / inf / NaN / the
   signed zero of a -0.0 input give unspecified results — the branchy special
   cases this body omits. Accuracy <=2 ulp vs host libm over a 40M-point sweep
   incl. the near-0 region (true worst ~2.25 ulp at the n=+-1 reduction boundary,
   the region openlibm special-cases), all boundary probes exact.

   The corpus twin is tools/library_coverage/branchless/expm1.c (same body) —
   keep the two textually in sync. */
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
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bexpm1(q));
}
int main(void) { (void) slice(); return 0; }
