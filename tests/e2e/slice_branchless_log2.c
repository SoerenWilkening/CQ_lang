/* slice_branchless_log2.c — bd 3c6m.37 / L1: log2 by SOURCE INJECTION (Rule 18),
   landed by the branchless-authored body spine. openlibm's e_log2.c is already
   branchless in its core; its ONLY control flow is the leading special-case
   ladder (x subnormal / x<=0 / inf / NaN / x==1 — src/e_log2.c:50, the
   L6-nested-ctrl census blocker). This body removes exactly those data-dependent
   branches: the {k, 1+f} decomposition is the canonical full-64-bit
   boundary-shift bit trick (== branchless/log.c, ZERO selects — carry through the
   exponent field IS the m>=sqrt(2) "branch"), then openlibm e_log2.c's VERBATIM
   base-2 combining/scaling:
       log2(x) = k + log2(m),  m in [sqrt(2)/2, sqrt(2)),  x == m*2^k exactly
   with log(m) = hi+lo in extra precision (SET_LOW_WORD clears hi's low 32 bits —
   a bitcast+and+bitcast round-trip through BOTH p119.7 directions) scaled by
   1/ln2 (ivln2 hi/lo) and k added by a Dekker two-sum. All straight-line
   fadd/fsub/fmul/fdiv (+ fmuladd keep-set contraction), zero control flow.

   Exact at powers of two (k integer-exact, m==1.0 => log2(m)==0). ~1 ulp on
   finite NORMAL x>0; x<=0 / inf / NaN / subnormal give unspecified results (the
   branches this authored body deliberately omits). Corpus twin:
   tools/library_coverage/branchless/log2.c — keep the two in sync.

   Golden-reading note: since bd `ni15` the trace runtime prints fp literals as
   HEX FLOAT (%a), so full-precision immediates like ivln2lo (1.675e-10) render
   as their exact bit pattern. Under the old %f they printed `0.000000`,
   indistinguishable from a genuine zero. */
static double blog2(double x) {
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
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(blog2(q));
}
int main(void) { (void) slice(); return 0; }
