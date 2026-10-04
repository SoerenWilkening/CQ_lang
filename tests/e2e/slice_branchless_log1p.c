/* slice_branchless_log1p.c — bd 3c6m.10 / L1: a source-injected transcendental
   (Rule 18), landed by the L1 branchless-authored body spine. A BRANCHLESS
   soft-log1p is authored inline, so clang -O1 inlines it to stock reversible
   OPCODES and the taint pass lowers those (no per-fn cq_template_log1p).

   openlibm's log1p is a thicket of data-dependent range-reduction branches to
   preserve accuracy near 0 where `1+x` cancels. This branchless body dissolves
   ALL of them with an EXACT compensated sum:

     1. Knuth 2Sum computes 1 + x == u + c EXACTLY (branchless) — c is the
        rounding error `1+x` drops, the very bits log1p must not lose near 0.
     2. log(u) is the branchless musl soft-log (slice_branchless_log's core —
        boundary-shift bit trick, ZERO selects).
     3. log(1+x) = log(u+c) ~= log(u) + c/u.

   Result: NO selects, NO control flow. Round-trips BOTH p119.7 bitcast
   directions (f64->i64 EXTRACT_WORDS and i64->f64 INSERT_WORDS).

   Domain: finite x > -1 with 1+x normal. x<=-1 / inf / NaN / overflowing 1+x /
   the signed zero of a -0.0 input (returns +0.0) give unspecified results — the
   branchy special cases this body omits. Accuracy <=2 ulp vs host libm over a
   20M-point sweep incl. the near-0 region (true worst ~1.44 ulp; the vs-host
   figure includes host-libm's own error), all boundary probes exact.

   The corpus twin is tools/library_coverage/branchless/log1p.c (same body) —
   keep the two textually in sync. */
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
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(blog1p(q));
}
int main(void) { (void) slice(); return 0; }
