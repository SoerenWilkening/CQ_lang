/* slice_libm_real_log.c — bd 3c6m.14 / L6 Inc 2: the REAL openlibm log body
   (e_log.c, fdlibm-derived, BSD-licensed; verbatim algorithm with the
   math_private.h word macros expanded to the __builtin_memcpy idiom clang
   -O1 folds to the same bitcast IR). The census cell log.f64: a 3-deep
   tainted nest (subnormal scale-up, the |f|<2**-20 fast path with its own
   k==0 split, and the i>0 polynomial split), integer bit-twiddling on the
   extracted words feeding fp compares, an fdiv, and a 4-incoming return
   merge. PredMux (PredMuxFlatten.cpp) flattens the whole DAG to
   edge-predicated select chains; the shipped select/conjunction substrate
   lowers those; this slice is the LINK-layer proof (Rule 2) that every
   emitted symbol resolves and the trace is stable.

   q = theta-tainted, so no guard const-folds away: the full nest survives
   clang -O1 exactly as in the census IR. */
#include <stdint.h>

static const double
ln2_hi  =  6.93147180369123816490e-01,  /* 3fe62e42 fee00000 */
ln2_lo  =  1.90821492927058770002e-10,  /* 3dea39ef 35793c76 */
two54   =  1.80143985094819840000e+16,  /* 43500000 00000000 */
Lg1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
Lg2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
Lg3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
Lg4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
Lg5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
Lg6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
Lg7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

static const double zero = 0.0;

__attribute__((always_inline)) static inline double olm_log(double x) {
    double hfsq, f, s, z, R, w, t1, t2, dk;
    int32_t k, hx, i, j;
    uint32_t lx;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* EXTRACT_WORDS */
    hx = (int32_t)(bits >> 32);
    lx = (uint32_t)bits;

    k = 0;
    if (hx < 0x00100000) {                               /* x < 2**-1022 */
        if (((hx & 0x7fffffff) | lx) == 0)
            return -two54 / zero;                        /* log(+-0)=-inf */
        if (hx < 0) return (x - x) / zero;               /* log(-#) = NaN */
        k -= 54; x *= two54;             /* subnormal number, scale up x */
        __builtin_memcpy(&bits, &x, 8);                  /* GET_HIGH_WORD */
        hx = (int32_t)(bits >> 32);
    }
    if (hx >= 0x7ff00000) return x + x;
    k += (hx >> 20) - 1023;
    hx &= 0x000fffff;
    i = (hx + 0x95f64) & 0x100000;
    __builtin_memcpy(&bits, &x, 8);                      /* SET_HIGH_WORD */
    bits = (bits & 0xffffffffULL) |
           ((uint64_t)(uint32_t)(hx | (i ^ 0x3ff00000)) << 32);
    __builtin_memcpy(&x, &bits, 8);                      /* normalize x or x/2 */
    k += (i >> 20);
    f = x - 1.0;
    if ((0x000fffff & (2 + hx)) < 3) {   /* -2**-20 <= f < 2**-20 */
        if (f == zero) {
            if (k == 0) {
                return zero;
            } else {
                dk = (double)k;
                return dk * ln2_hi + dk * ln2_lo;
            }
        }
        R = f * f * (0.5 - 0.33333333333333333 * f);
        if (k == 0) return f - R;
        else { dk = (double)k;
               return dk * ln2_hi - ((R - dk * ln2_lo) - f); }
    }
    s = f / (2.0 + f);
    dk = (double)k;
    z = s * s;
    i = hx - 0x6147a;
    w = z * z;
    j = 0x6b851 - hx;
    t1 = w * (Lg2 + w * (Lg4 + w * Lg6));
    t2 = z * (Lg1 + w * (Lg3 + w * (Lg5 + w * Lg7)));
    i |= j;
    R = t2 + t1;
    if (i > 0) {
        hfsq = 0.5 * f * f;
        if (k == 0) return f - (hfsq - s * (hfsq + R));
        else return dk * ln2_hi - ((hfsq - (s * (hfsq + R) + dk * ln2_lo)) - f);
    } else {
        if (k == 0) return f - s * (f - R);
        else return dk * ln2_hi - ((s * (f - R) - dk * ln2_lo) - f);
    }
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_log(q));
}
int main(void) { (void) slice(); return 0; }
