/* branchless/log1p.c — bd 3c6m.10 (libm L1): the AUTHORED branchless soft-log1p
   body the census injects for `log1p` (Rule 18 source injection; owner
   body-source decision 2026-07-10 = hand-author per fn). This file SHADOWS
   openlibm's branchy s_log1p.c in the census symbol index.

   openlibm's log1p is a thicket of data-dependent range-reduction branches
   (s_log1p.c:110) to preserve accuracy near 0 where `1+x` cancels. This
   branchless body dissolves ALL of them with an EXACT compensated sum instead:

     1. Knuth 2Sum computes  1 + x == u + c  EXACTLY (branchless, 6 fadds) — c is
        the rounding error `1+x` drops, the very bits log1p must not lose near 0.
     2. log(u) is the branchless musl soft-log (the branchless/log.c core inlined
        — boundary-shift bit trick, ZERO selects) reduced on m in [sqrt2/2,sqrt2).
     3. log(1+x) = log(u+c) = log(u) + log1p(c/u) ~= log(u) + c/u  (the dropped
        second-order term is O((c/u)^2) ~ 2^-107, negligible).

   Result: NO selects, NO control flow — pure straight-line integer + fp opcodes.
   The e2e golden twin is tests/e2e/slice_branchless_log1p.c (same body, inlined
   at the slice level) — keep the two textually in sync.

   Domain: finite x > -1 with 1+x a normal (log(u) is the branchless log's
   domain). x <= -1 / inf / NaN / |x| so large 1+x overflows, and the signed
   zero of a -0.0 input (returns +0.0), are UNSPECIFIED (exactly the
   data-dependent branches this branchless body omits). Accuracy <=2 ulp vs host
   libm over a 20M-point sweep (true worst ~1.44 ulp; the vs-host figure includes
   host-libm's own error), including the near-0 region where naive log(1+x)
   loses all bits.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO
   -fno-builtin (see branchless/log.c for the inliner-compatibility reason). */
double log1p(double x) {
    /* Knuth 2Sum: 1 + x == u + c exactly (c is the rounding error of 1+x). */
    double u  = 1.0 + x;
    double bv = u - 1.0;
    double av = u - bv;
    double c  = (1.0 - av) + (x - bv);

    /* Branchless soft-log of u (musl core; boundary-shift bit trick, no selects). */
    long long bits;
    __builtin_memcpy(&bits, &u, 8);                    /* bitcast f64->i64        */
    bits += 0x3FF0000000000000LL - 0x3FE6A09E667F3BCDLL; /* shift boundary to √2/2 */
    int k = (int)(bits >> 52) - 1023;                  /* exponent, √2-centered   */
    long long mbits = (bits & 0x000FFFFFFFFFFFFFLL) + 0x3FE6A09E667F3BCDLL;
    double m;
    __builtin_memcpy(&m, &mbits, 8);                   /* bitcast i64->f64: m∈[√2/2,√2) */
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

    /* log(u + c) = log(u) + log1p(c/u) ~= log(u) + c/u. */
    return logu + c / u;
}
