/* branchless/log.c — bd 3c6m.10 (libm L1): the AUTHORED branchless soft-log body
   the census injects for `log` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model).
   This file SHADOWS openlibm's branchy e_log.c in the census symbol index —
   same algorithm core (musl/openlibm minimax on s = f/(2+f)), with the
   special-case BRANCHES removed and the range reduction done as the canonical
   boundary-shift bit trick on the full 64-bit word (pure i64 add/ashr/and —
   ZERO selects, zero control flow).

   The e2e golden twin is tests/e2e/slice_branchless_log.c (same body, inlined
   at the slice level) — keep the two in sync.

   EXACT for the reduction: x == m * 2^k with m in [sqrt(2)/2, sqrt(2)) carrying
   the original mantissa, for every finite NORMAL x > 0. Accuracy ~1 ulp on that
   domain (musl's own Lg1..Lg7 + two-constant ln2 split). x <= 0 / inf / NaN /
   subnormal are UNSPECIFIED — those are exactly the data-dependent branches a
   branchless injected body deliberately omits.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c` with NO
   -fno-builtin — a "no-builtins" definition attribute would make the probe
   caller's no-builtin-log set a non-superset and the O2 inliner then refuses
   to inline the body (TLI areInlineCompatible, InlineCallerSupersetNoBuiltin). */
double log(double x) {
    long long bits;
    __builtin_memcpy(&bits, &x, 8);                    /* bitcast f64->i64 (EXTRACT_WORDS) */
    bits += 0x3FF0000000000000LL - 0x3FE6A09E667F3BCDLL; /* shift boundary to sqrt(2)/2   */
    int k = (int)(bits >> 52) - 1023;                  /* exponent, sqrt(2)-centered       */
    long long mbits = (bits & 0x000FFFFFFFFFFFFFLL) + 0x3FE6A09E667F3BCDLL;
    double m;
    __builtin_memcpy(&m, &mbits, 8);                   /* bitcast i64->f64: m in [√2/2,√2) */
    double f    = m - 1.0;
    double s    = f / (2.0 + f);
    double z    = s * s;
    double w    = z * z;
    double t1   = w * (3.999999999940941908e-01        /* musl Lg2/Lg4/Lg6                 */
                  + w * (2.222219843214978396e-01
                  + w *  1.531383769920937332e-01));
    double t2   = z * (6.666666666666735130e-01        /* musl Lg1/Lg3/Lg5/Lg7             */
                  + w * (2.857142874366239149e-01
                  + w * (1.818357216161805012e-01
                  + w *  1.479819860511658591e-01)));
    double r    = t2 + t1;
    double hfsq = 0.5 * f * f;
    double dk   = (double)k;
    return s * (hfsq + r) + dk * 1.90821492927058770002e-10
           - hfsq + f + dk * 6.93147180369123816490e-01; /* two-constant ln2 split         */
}
