/* branchless/log2.c — bd 3c6m.37 (libm L1): the AUTHORED branchless soft-log2
   body the census injects for `log2` (Rule 18 source injection; NOT
   name-recognition). SHADOWS openlibm's branchy e_log2.c in the census symbol
   index.

   openlibm's e_log2.c is ALREADY branchless in its core (the k/f reduction, the
   k_log1p kernel, and the extra-precision base-2 combining/scaling). Its ONLY
   control flow is the leading special-case ladder (x subnormal / x<=0 / inf /
   NaN / x==1) — src/e_log2.c:50, the L6-nested-ctrl census blocker. This body
   REMOVES exactly those data-dependent branches and does the {k, 1+f}
   decomposition with the canonical full-64-bit boundary-shift bit trick (the
   proven branchless/log.c reduction: pure i64 add/ashr/and, carry through the
   exponent field IS the m>=sqrt(2) "branch"), then runs openlibm e_log2.c's
   VERBATIM combining:
       log2(x) = k + log2(m),  m in [sqrt(2)/2, sqrt(2)),  x == m*2^k exactly
   with log(m) = hi+lo split in extra precision (SET_LOW_WORD clears hi's low 32
   bits — a bitcast+and+bitcast round-trip, ZERO selects) scaled by 1/ln2
   (ivln2 hi/lo) and k added by Dekker two-sum. Exact at powers of two (k is
   integer-exact, m==1.0 => log2(m)==0). ~1 ulp on finite normal x>0; x<=0 /
   inf / NaN / subnormal are UNSPECIFIED (the omitted branches).

   The e2e golden twin is tests/e2e/slice_branchless_log2.c (same body, inlined
   at the slice level) — keep the two in sync. Compile like the openlibm corpus:
   plain `clang -g -O1` with NO -fno-builtin (a "no-builtins" definition attr
   would make the probe caller's no-builtin-log2 set a non-superset and the O2
   inliner then refuses to inline the body — TLI areInlineCompatible). */
double log2(double x) {
    long long bits;
    __builtin_memcpy(&bits, &x, 8);                     /* bitcast f64->i64 (EXTRACT_WORDS) */
    bits += 0x3FF0000000000000LL - 0x3FE6A09E667F3BCDLL; /* shift boundary to sqrt(2)/2      */
    int k = (int)(bits >> 52) - 1023;                   /* exponent, sqrt(2)-centered        */
    long long mbits = (bits & 0x000FFFFFFFFFFFFFLL) + 0x3FE6A09E667F3BCDLL;
    double m;
    __builtin_memcpy(&m, &mbits, 8);                    /* bitcast i64->f64: m in [√2/2,√2)  */
    double f  = m - 1.0;
    double s  = f / (2.0 + f);                          /* k_log1p(f) = s*(hfsq+R)           */
    double z  = s * s;
    double w  = z * z;
    double t1 = w * (3.999999999940941908e-01           /* musl/openlibm Lg2/Lg4/Lg6         */
              + w * (2.222219843214978396e-01
              + w *  1.531383769920937332e-01));
    double t2 = z * (6.666666666666735130e-01           /* Lg1/Lg3/Lg5/Lg7                   */
              + w * (2.857142874366239149e-01
              + w * (1.818357216161805012e-01
              + w *  1.479819860511658591e-01)));
    double R    = t2 + t1;
    double hfsq = 0.5 * f * f;
    double r    = s * (hfsq + R);
    /* openlibm e_log2.c combining/scaling in extra precision (VERBATIM):      */
    double hi = f - hfsq;
    long long hibits;
    __builtin_memcpy(&hibits, &hi, 8);
    hibits &= 0xFFFFFFFF00000000LL;                     /* SET_LOW_WORD(hi, 0)               */
    __builtin_memcpy(&hi, &hibits, 8);
    double lo = (f - hi) - hfsq + r;
    double y      = (double)k;                          /* sitofp i32->f64                   */
    double val_hi = hi * 1.44269504072144627571e+00;    /* ivln2hi                           */
    double val_lo = (lo + hi) * 1.67517131648865118353e-10  /* ivln2lo                       */
                  + lo * 1.44269504072144627571e+00;
    double ww = y + val_hi;                             /* Dekker two-sum of k + val_hi      */
    val_lo += (y - ww) + val_hi;
    val_hi = ww;
    return val_lo + val_hi;
}
