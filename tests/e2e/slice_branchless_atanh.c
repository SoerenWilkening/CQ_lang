/* slice_branchless_atanh.c — bd 3c6m.23 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-atanh is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_atanh).

   openlibm's atanh branches on |x| into three ranges to pick a cancellation-free
   reconstruction. This body keeps openlibm's OWN 0.5<=|x|<1 kernel and makes it
   valid for ALL |x|<1 with the EXACT algebraic identity

       atanh(x) = 0.5 * ln((1+x)/(1-x)) = 0.5 * log1p( 2|x| / (1-|x|) ),  sign on x

   (1 + 2|x|/(1-|x|) = (1+|x|)/(1-|x|)). The corpus twin
   (tools/library_coverage/branchless/atanh.c) CALLS log1p (resolved by the census
   closure-link to branchless/log1p.c and inlined); here the same branchless log1p
   kernel is inlined directly as the static `blog1p` helper.

   *** WORK ON |x|, NOT x — load-bearing for correctness. *** With a signed x, for
   x -> -1+ the argument 2x/(1-x) -> -1+, and log1p is catastrophically
   ill-conditioned near -1 (a ~0.5-ulp rounding blows up to 52782 ulp at
   x=-0.999999). Working on ax=|x| makes the argument always >= 0 (well-conditioned)
   and the odd-fn sign is restored losslessly by copysign.

   Domain: |x| < 1. |x| >= 1 UNSPECIFIED (at x=+-1 the branchless log1p leaf returns
   NaN, not the mathematical +-inf; for |x|>1 it returns finite garbage). +-0 -> +-0.
   Worst <=2.5 true-ulp (observed ~2.45) vs host long-double atanhl (the branchless log1p leaf, ~2
   ulp, dominates; a host-log1p sweep understates it).

   The corpus twins are tools/library_coverage/branchless/{atanh,log1p}.c (same
   bodies) — keep the three textually in sync. */

/* the branchless log1p kernel, inlined (== tools/library_coverage/branchless/log1p.c) */
static double blog1p(double x) {
    double u  = 1.0 + x;
    double bv = u - 1.0;
    double av = u - bv;
    double c  = (1.0 - av) + (x - bv);                 /* 1+x == u+c exactly      */

    long long bits;
    __builtin_memcpy(&bits, &u, 8);                    /* bitcast f64->i64        */
    bits += 0x3FF0000000000000LL - 0x3FE6A09E667F3BCDLL;
    int k = (int)(bits >> 52) - 1023;
    long long mbits = (bits & 0x000FFFFFFFFFFFFFLL) + 0x3FE6A09E667F3BCDLL;
    double m;
    __builtin_memcpy(&m, &mbits, 8);                   /* bitcast i64->f64        */
    double f    = m - 1.0;
    double s    = f / (2.0 + f);
    double z    = s * s;
    double w    = z * z;
    double t1   = w * (3.999999999940941908e-01
                  + w * (2.222219843214978396e-01
                  + w *  1.531383769920937332e-01));
    double t2   = z * (6.666666666666735130e-01
                  + w * (2.857142874366239149e-01
                  + w * (1.818357216161805012e-01
                  + w *  1.479819860511658591e-01)));
    double r    = t2 + t1;
    double hfsq = 0.5 * f * f;
    double dk   = (double)k;
    double logu = s * (hfsq + r) + dk * 1.90821492927058770002e-10
                  - hfsq + f + dk * 6.93147180369123816490e-01;

    return logu + c / u;                               /* log(u) + c/u            */
}

static double batanh(double x) {
    double ax = __builtin_fabs(x);                       /* odd fn: work on |x|   */
    double t  = 2.0 * ax / (1.0 - ax);                   /* >= 0, log1p well-cond */
    return __builtin_copysign(0.5 * blog1p(t), x);       /* keep-set leaf; odd fn */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(batanh(q));
}
int main(void) { (void) slice(); return 0; }
