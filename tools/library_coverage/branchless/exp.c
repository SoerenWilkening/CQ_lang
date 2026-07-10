/* branchless/exp.c — bd 3c6m.10 (libm L1): the AUTHORED branchless soft-exp body
   the census injects for `exp` (Rule 18 source injection). This is EXACTLY the
   proven 3c6m.7 body from tests/e2e/slice_branchless_exp.c (the e2e golden
   twin — keep the two in sync), promoted into the L1 authored corpus so the
   census measures it instead of openlibm's branchy+table e_exp.c.

   Select-based range reduction (ONE fp-data select for the round bias — the
   kjd1 accept shape), Horner exp(r) on the reduced range, 2^n scale via
   INSERT_WORDS. Accuracy is the 3c6m.7 truncated-Taylor level (~1e-7 relative
   on the reduced range); overflow/underflow/NaN are UNSPECIFIED — the branchy
   special cases a branchless injected body deliberately omits.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO
   -fno-builtin (see branchless/log.c for the inliner-compatibility reason). */
double exp(double x) {
    double xn   = x * 1.4426950408889634;                 /* x / ln2                        */
    double half = (xn < 0.0) ? -0.5 : 0.5;                /* branchless round bias (select) */
    int    n    = (int)(xn + half);                       /* fptosi on select-derived fp    */
    double r    = x - (double)n * 0.6931471805599453;     /* reduced arg (sitofp back)      */
    double p    = 1.0 + r*(1.0 + r*(0.5 + r*(0.1666666666666
                     + r*(0.0416666666 + r*0.008333333)))); /* Horner exp(r) on reduced range */
    long long bits = (long long)(n + 1023) << 52;         /* 2^n exponent field             */
    double scale;
    __builtin_memcpy(&scale, &bits, 8);                   /* bitcast i64->f64 (INSERT_WORDS) */
    return p * scale;
}
