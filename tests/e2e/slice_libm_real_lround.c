/* slice_libm_real_lround.c — bd 3c6m.14 / L6 Inc 1: the REAL openlibm lround
   body (s_lround.c → round (s_round.c) → floor (s_floor.c) inlined, fdlibm-
   derived, BSD-licensed; word macros expanded to the __builtin_memcpy idiom).
   The double/long instantiation makes INRANGE() compile-time TRUE, so
   lround(x) = (long)round(x) with no fenv path — exactly the census cell
   lround.f64. The inlined chain is the deepest Increment-1 shape: a ~5-level
   nest with two mirrored floor sub-DAGs, 6-predecessor merges carrying TWO
   phis each (hi/lo words muxed under shared edge predicates), fcmp conditions
   (the huge+x inexact-raise idiom), fneg, and the post-merge fptosi. PredMux
   flattens the whole DAG; the select/conjunction substrate lowers it; this
   slice is the LINK-layer proof (Rule 2). */
#include <stdint.h>

static const double fl_huge = 1.0e300;

__attribute__((always_inline)) static inline double olm_floor(double x) {
    int32_t i0, i1, j0;
    uint32_t i, j;
    uint64_t bits;
    __builtin_memcpy(&bits, &x, 8);                      /* EXTRACT_WORDS */
    i0 = (int32_t)(bits >> 32);
    i1 = (int32_t)bits;
    j0 = ((i0 >> 20) & 0x7ff) - 0x3ff;
    if (j0 < 20) {
        if (j0 < 0) {                                    /* |x| < 1 */
            if (fl_huge + x > 0.0) {                     /* raise inexact */
                if (i0 >= 0) { i0 = i1 = 0; }
                else if (((i0 & 0x7fffffff) | i1) != 0) { i0 = 0xbff00000; i1 = 0; }
            }
        } else {
            i = (0x000fffff) >> j0;
            if (((i0 & i) | i1) == 0) return x;          /* x is integral */
            if (fl_huge + x > 0.0) {                     /* raise inexact */
                if (i0 < 0) i0 += (0x00100000) >> j0;
                i0 &= (~i); i1 = 0;
            }
        }
    } else if (j0 > 51) {
        if (j0 == 0x400) return x + x;                   /* inf or NaN */
        else return x;                                   /* x is integral */
    } else {
        i = ((uint32_t)(0xffffffff)) >> (j0 - 20);
        if ((i1 & i) == 0) return x;                     /* x is integral */
        if (fl_huge + x > 0.0) {                         /* raise inexact */
            if (i0 < 0) {
                if (j0 == 20) i0 += 1;
                else {
                    j = i1 + (1 << (52 - j0));
                    if (j < (uint32_t)i1) i0 += 1;       /* got a carry */
                    i1 = j;
                }
            }
            i1 &= (~i);
        }
    }
    bits = ((uint64_t)(uint32_t)i0 << 32) | (uint32_t)i1; /* INSERT_WORDS */
    __builtin_memcpy(&x, &bits, 8);
    return x;
}

__attribute__((always_inline)) static inline double olm_round(double x) {
    double t;
    uint32_t hx;
    uint64_t bits;
    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    hx = (uint32_t)(bits >> 32);
    if ((hx & 0x7fffffff) == 0x7ff00000)
        return (x + x);
    if (!(hx & 0x80000000)) {
        t = olm_floor(x);
        if (t - x <= -0.5)
            t += 1;
        return (t);
    } else {
        t = olm_floor(-x);
        if (t + x <= -0.5)
            t += 1;
        return (-t);
    }
}

__attribute__((always_inline)) static inline long olm_lround(double x) {
    /* openlibm s_lround.c: INRANGE(x) = (dtype_max - DTYPE_MAX != 0.5 ||
       (x > dtype_min && x < dtype_max)). For the double/long instantiation
       the FIRST disjunct is a compile-time constant: dtype_max =
       (double)(LONG_MAX + 0.5) rounds to 2^63 and (double)LONG_MAX also
       rounds to 2^63, so the difference is 0.0 != 0.5 == TRUE and the ||
       short-circuits — INRANGE is compile-time TRUE and the
       feraiseexcept/saturate branch is dead (the openlibm header comment's
       "or TRUE otherwise" case). Empirically confirmed: the census-inlined
       s_lround.c IR (scratchpad ir8/lround_inl.ll) contains no range compare
       and no fenv call — round + fptosi only, exactly this body. */
    return (long)olm_round(x);
}

long slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_lround(q));
}
int main(void) { (void) slice(); return 0; }
