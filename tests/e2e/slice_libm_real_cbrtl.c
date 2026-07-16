/* slice_libm_real_cbrtl.c — bd 3c6m.51 Inc 3 + bd etiq: the REAL openlibm
   cbrtl body (s_cbrtl.c, fdlibm-derived, BSD-licensed) over x86_fp80
   `long double`.

   The Inc-3 multi-block union promotion clears cbrtl's fp80-union axis (both
   unions u/v promote; no kMsgStore); the control axis cleared with bd etiq's
   volatile-const-LOCAL fold (the alloca sibling of
   foldVolatileConstGlobalLoads): the LDBL_MANT_DIG==64 rounding arm's
   `volatile double vd2/vd1` LOCALS — single constant store + dominated
   same-type volatile load each — fold to their constants and the alloca /
   store / lifetime markers are erased, so no volatile access survives into
   the tainted region (PredMux E4 admits none).
   Mechanical edits ONLY: license/includes dropped; cbrtl renamed to the
   always_inline olm_cbrtl; B1 uniquified to olm_cbrtl_B1; the math_private.h
   GET/SET_FLOAT_WORD macros expanded to the __builtin_memcpy idiom (fx/ft are
   genuine `float`, so the 4-byte copy is exact); u_int*_t spelled via stdint;
   the dead #ifdef __i386__ fpsetprec arms dropped (never compiled on x86_64,
   guarded by an #ifdef that is undefined here — same as the preprocessor
   would). Every constant/branch/expression is IDENTICAL to openlibm.

   cbrtl carries TWO fp80 unions (u and v, both with offset-8 field-insert
   packs), an fp80 re-seed `u.e *= 0x1.0p514` in the subnormal arm, two tainted
   switches (the exponent class and `k % 3`), and the volatile-double rounding
   constants of the LDBL_MANT_DIG==64 arm. */
#include <stdint.h>
#include <float.h>

typedef uint32_t u_int32_t;
typedef uint16_t u_int16_t;

/* The exact amd64 x86_fp80 bit-pattern union (openlibm amd64_fpmath.h),
   including the xbits view cbrtl reads/writes expsign through. */
union IEEEl2bits {
    long double e;
    struct {
        unsigned int manl : 32;
        unsigned int manh : 32;
        unsigned int exp  : 15;
        unsigned int sign : 1;
        unsigned int junkl : 16;
        unsigned int junkh : 32;
    } bits;
    struct {
        unsigned long man : 64;
        unsigned int expsign : 16;
        unsigned long junk : 48;
    } xbits;
};

/* openlibm math_private.h GET_FLOAT_WORD/SET_FLOAT_WORD — memcpy shim. */
#define GET_FLOAT_WORD(i,d) do { float gf_t = (d); __builtin_memcpy(&(i), &gf_t, 4); } while (0)
#define SET_FLOAT_WORD(d,i) do { uint32_t sf_t = (i); __builtin_memcpy(&(d), &sf_t, 4); } while (0)

#define BIAS (LDBL_MAX_EXP - 1)

static const unsigned
    olm_cbrtl_B1 = 709958130; /* B1 = (127-127.0/3-0.03306235651)*2**23 */

/* openlibm s_cbrtl.c cbrtl (verbatim body). */
__attribute__((always_inline)) static inline long double
olm_cbrtl(long double x)
{
    union IEEEl2bits u, v;
    long double r, s, t, w;
    double dr, dt, dx;
    float ft, fx;
    u_int32_t hx;
    u_int16_t expsign;
    int k;

    u.e = x;
    expsign = u.xbits.expsign;
    k = expsign & 0x7fff;

    /*
     * If x = +-Inf, then cbrt(x) = +-Inf.
     * If x = NaN, then cbrt(x) = NaN.
     */
    if (k == BIAS + LDBL_MAX_EXP)
        return (x + x);

    if (k == 0) {
        /* If x = +-0, then cbrt(x) = +-0. */
        if ((u.bits.manh | u.bits.manl) == 0) {
            return (x);
        }
        /* Adjust subnormal numbers. */
        u.e *= 0x1.0p514;
        k = u.bits.exp;
        k -= BIAS + 514;
    } else
        k -= BIAS;
    u.xbits.expsign = BIAS;
    v.e = 1;

    x = u.e;
    switch (k % 3) {
    case 1:
    case -2:
        x = 2*x;
        k--;
        break;
    case 2:
    case -1:
        x = 4*x;
        k -= 2;
        break;
    }
    v.xbits.expsign = (expsign & 0x8000) | (BIAS + k / 3);

    /*
     * The following is the guts of s_cbrtf, with the handling of
     * special values removed and extra care for accuracy not taken,
     * but with most of the extra accuracy not discarded.
     */

    /* ~5-bit estimate: */
    fx = x;
    GET_FLOAT_WORD(hx, fx);
    SET_FLOAT_WORD(ft, ((hx & 0x7fffffff) / 3 + olm_cbrtl_B1));

    /* ~16-bit estimate: */
    dx = x;
    dt = ft;
    dr = dt * dt * dt;
    dt = dt * (dx + dx + dr) / (dx + dr + dr);

    /* ~47-bit estimate: */
    dr = dt * dt * dt;
    dt = dt * (dx + dx + dr) / (dx + dr + dr);

    /*
     * dt is cbrtl(x) to ~47 bits (after x has been reduced to 1 <= x < 8).
     * Round it away from zero to 32 bits (32 so that t*t is exact, and
     * away from zero for technical reasons).
     */
    volatile double vd2 = 0x1.0p32;
    volatile double vd1 = 0x1.0p-31;
#define vd ((long double)vd2 + vd1)

    t = dt + vd - 0x1.0p32;

    /*
     * Final step Newton iteration to 64 or 113 bits with
     * error < 0.667 ulps
     */
    s = t*t;                /* t*t is exact */
    r = x/s;                /* error <= 0.5 ulps; |r| < |t| */
    w = t+t;                /* t+t is exact */
    r = (r-t)/(w+r);        /* r-t is exact; w+r ~= 3*t */
    t = t+t*r;              /* error <= 0.5 + 0.5/3 + epsilon */

    t *= v.e;
    return (t);
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_cbrtl(q));
}

int main(void) {
    (void) slice();
    return 0;
}
