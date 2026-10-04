/* slice_branchless_log.c — bd 3c6m.10 / L1: the SECOND transcendental compiled by
   SOURCE INJECTION (Rule 18), and the first landed by the L1 branchless-authored
   body spine. A BRANCHLESS soft-log body — musl/openlibm's exact core algorithm
   with the special-case branches removed — is authored inline, so clang -O1
   inlines it to stock reversible OPCODES and the taint pass lowers those (no
   per-fn cq_template_log).

   Unlike slice_branchless_exp, range reduction here needs ZERO selects: the
   canonical libm boundary-shift trick centers m into [sqrt(2)/2, sqrt(2)) with
   pure integer arithmetic on the bit pattern —
       bits += 0x3FF0000000000000 - bits(sqrt(2)/2)   (carry into the exponent
                                                        field IS the m>=sqrt(2)
                                                        "branch")
       k     = (bits >> 52) - 1023
       mbits = (bits & MANT_MASK) + bits(sqrt(2)/2)
   which is EXACT (x == m * 2^k, m carrying the original mantissa) for every
   finite normal x > 0. The decomposition round-trips through BOTH p119.7
   bitcasts (f64->i64 EXTRACT_WORDS and i64->f64 INSERT_WORDS).

   Then log(x) = k*ln2 + log(m) via musl's minimax R(z) on s = f/(2+f),
   f = m-1: all straight-line fadd/fsub/fmul/fdiv (+ fmuladd contraction into
   the hardware keep-set), ~1 ulp on the reduced range.

   Domain: finite NORMAL x > 0, exactly like the branchy special cases this
   authored body deliberately omits (x<=0 / inf / NaN / subnormal give
   unspecified results — openlibm handles those with the very data-dependent
   branches source injection is measured without).

   Golden-reading note: since bd `ni15` the trace runtime prints fp literals
   as HEX FLOAT (%a), so the dk*ln2_lo line renders as
   `fmul_f64_hl(h24, 0x1.a39ef35793c76p-33)` — the exact immediate
   0x3DEA39EF35793C76 (1.9082e-10). Under the old %f it printed `0.000000`,
   indistinguishable from a genuine zero. */
static double blog(double x) {
    long long bits;
    __builtin_memcpy(&bits, &x, 8);                    /* bitcast f64->i64 (EXTRACT_WORDS) */
    bits += 0x3FF0000000000000LL - 0x3FE6A09E667F3BCDLL; /* shift boundary to sqrt(2)/2   */
    int k = (int)(bits >> 52) - 1023;                  /* exponent, sqrt(2)-centered       */
    long long mbits = (bits & 0x000FFFFFFFFFFFFFLL) + 0x3FE6A09E667F3BCDLL;
    double m;
    __builtin_memcpy(&m, &mbits, 8);                   /* bitcast i64->f64: m in [√2/2,√2) */
    double f    = m - 1.0;
    double s    = f / (2.0 + f);                       /* fdiv QQ                          */
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
    double dk   = (double)k;                           /* sitofp i32->f64                  */
    return s * (hfsq + r) + dk * 1.90821492927058770002e-10
           - hfsq + f + dk * 6.93147180369123816490e-01; /* two-constant ln2 split         */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(blog(q));
}
int main(void) { (void) slice(); return 0; }
