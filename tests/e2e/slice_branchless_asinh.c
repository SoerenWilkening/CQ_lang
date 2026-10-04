/* slice_branchless_asinh.c — bd 3c6m.20 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-asinh is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_asinh).

   openlibm's asinh branches on |x| into four ranges to avoid BOTH the near-0
   cancellation of log(1+small) AND the large-|x| overflow of x*x. This body
   dissolves both with ONE overflow-safe, cancellation-free identity:

       asinh(x) = log(|x| + sqrt(x*x+1)) = log1p( |x| + (sqrt(x*x+1) - 1) ),  sign x

   sqrt(x*x+1) has no real product factorization, so it is computed overflow-safe as
       s = fmin( sqrt(ax*ax+1),  ax*sqrt(1 + 1/(x*x)) )   == sqrt(x*x+1)
   (IEEE fmin drops the NaN/inf arm, so s is right at 0, tiny, mid, and the whole
   large tail — correct through ~9e307). The near-0 correction sqrt(x*x+1)-1 is
   computed as ax*(ax/(1+s)) with the DIVISION FIRST — overflow-safe AND preserving
   the x^2/2 term that a naive `s-1` (which rounds to 0 for ax<1.5e-8) would drop.
   The corpus twin (tools/library_coverage/branchless/asinh.c) CALLS log1p (resolved
   by the census closure-link to branchless/log1p.c and inlined); here the same
   branchless log1p kernel is inlined directly as the static `blog1p` helper.
   fmin/sqrt/fabs/copysign are the hardware keep-set leaves; ZERO selects.

   Domain: finite x with |x| <= DBL_MAX/2 (~8.99e307); above that the |x|+correction
   sum overflows and the branchless log1p leaf -> NaN (UNSPECIFIED). +-0 -> +-0.
   Near 0 the div-first correction preserves x^2/2 so asinh(x) ~ x (not the ~2e7-ulp
   collapse of a naive s-1). Worst <=2.1 true-ulp (observed ~2.05) vs host long-double asinhl (the
   branchless log1p leaf, ~2 ulp, dominates — a host-log1p sweep shows near-0 as
   bit-exact and understates the bound).

   The corpus twins are tools/library_coverage/branchless/{asinh,log1p}.c (same
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

static double basinh(double x) {
    double ax = __builtin_fabs(x);                       /* odd fn: work on |x|   */
    double s  = __builtin_fmin(__builtin_sqrt(ax*ax + 1.0),   /* = sqrt(x*x+1),   */
                               ax * __builtin_sqrt(1.0 + 1.0/(x*x))); /* overflow-safe */
    double A  = ax + ax*(ax/(1.0 + s));                  /* = |x| + (sqrt(x*x+1)-1) */
    return __builtin_copysign(blog1p(A), x);             /* keep-set leaf; odd fn   */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(basinh(q));
}
int main(void) { (void) slice(); return 0; }
