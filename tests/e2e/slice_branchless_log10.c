/* slice_branchless_log10.c — bd 3c6m.35 / L1: log10 by SOURCE INJECTION (Rule 18),
   landed by the branchless-authored body spine. Structurally identical to
   slice_branchless_log2.c (openlibm's shared e_log.c/k_log.h core with the
   leading special-case branch ladder — src/e_log10.c:50, the L6-nested-ctrl
   census blocker — removed and the {k,1+f} decomposition done branchless via the
   full-64-bit boundary-shift bit trick). Only the final combining differs:
   openlibm e_log10.c scales log(m)=hi+lo by 1/ln10 (ivln10 hi/lo) and adds
   k*log10(2) (log10_2 hi/lo) in extra precision:
       log10(x) = (f - hfsq + k_log1p(f)) / ln10 + k*log10(2)
   All straight-line fadd/fsub/fmul/fdiv (+ fmuladd keep-set contraction), zero
   control flow; both p119.7 bitcast directions, twice.

   ~1 ulp on finite NORMAL x>0; x<=0 / inf / NaN / subnormal give unspecified
   results (the omitted branches). Corpus twin:
   tools/library_coverage/branchless/log10.c — keep the two in sync.

   Golden-reading note: since bd `ni15` the runtime prints fp literals as HEX
   FLOAT (%a), so full-precision immediates (log10_2lo 3.694e-13, ivln10lo
   2.508e-11) render as their exact bit pattern. Under the old %f they printed
   `0.000000`, indistinguishable from a genuine zero. */
static double blog10(double x) {
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
    double val_hi = hi * 4.34294481878168880939e-01;    /* ivln10hi                          */
    double y2     = y * 3.01029995663611771306e-01;     /* log10_2hi                         */
    double val_lo = y * 3.69423907715893078616e-13      /* log10_2lo                         */
                  + (lo + hi) * 2.50829467116452752298e-11  /* ivln10lo                      */
                  + lo * 4.34294481878168880939e-01;     /* ivln10hi                          */
    double ww = y2 + val_hi;                            /* Dekker two-sum of k*log10_2 + val */
    val_lo += (y2 - ww) + val_hi;
    val_hi = ww;
    return val_lo + val_hi;
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(blog10(q));
}
int main(void) { (void) slice(); return 0; }
