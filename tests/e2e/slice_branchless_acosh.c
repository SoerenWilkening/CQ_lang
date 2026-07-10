/* slice_branchless_acosh.c — bd 3c6m.18 / L2-closure: a source-injected
   transcendental (Rule 18), landed by the L1 branchless-authored body spine. A
   BRANCHLESS soft-acosh is authored inline, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_acosh).

   openlibm's acosh branches on x into three ranges to avoid BOTH the near-1
   cancellation of x*x-1 AND the large-x overflow of x*x. This body dissolves both
   with one overflow-safe, cancellation-free identity:

       acosh(x) = log(x + sqrt(x*x-1)) = log1p( (x-1) + sqrt(x-1)*sqrt(x+1) )

   sqrt(x*x-1) as sqrt(x-1)*sqrt(x+1) HALVES each factor's exponent, so the product
   keeps THE SQRT finite through DBL_MAX and there is no `x*x-1` cancellation near
   1 (x-1 exact by Sterbenz); log1p keeps the near-1 accuracy. The corpus twin
   (tools/library_coverage/branchless/acosh.c) CALLS log1p (resolved by the census
   closure-link to branchless/log1p.c and inlined); here the same branchless log1p
   kernel is inlined directly as the static `blog1p` helper. sqrt is the hardware
   keep-set leaf; ZERO selects.

   Domain: 1 <= x <= DBL_MAX/2 (~8.99e307). x<1 UNSPECIFIED (sqrt of negative -> NaN);
   x>DBL_MAX/2 UNSPECIFIED (the sum (x-1)+s ~ 2x overflows, branchless log1p -> NaN;
   same last-octave edge as asinh). acosh(1)=0. NaN-free on [1, 8.99e307]. Worst
   <=4.0 true-ulp (observed ~3.97) vs host long-double acoshl (near-1 zone; 0.47 in the tail; the
   branchless log1p leaf, ~2 ulp, dominates — a host-log1p sweep understates it).

   The corpus twins are tools/library_coverage/branchless/{acosh,log1p}.c (same
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

static double bacosh(double x) {
    double t = x - 1.0;                                  /* exact (Sterbenz) near 1 */
    double s = __builtin_sqrt(t) * __builtin_sqrt(x + 1.0); /* = sqrt(x*x-1), no OVF */
    return blog1p(t + s);                               /* = log(x + sqrt(x*x-1))  */
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bacosh(q));
}
int main(void) { (void) slice(); return 0; }
