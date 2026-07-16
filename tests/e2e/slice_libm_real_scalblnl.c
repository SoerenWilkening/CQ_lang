/* slice_libm_real_scalblnl.c — bd 3c6m.51 Inc 3: the REAL openlibm scalblnl
   body (census cell scalblnl.f80). openlibm s_scalbln.c scalblnl clamps the
   `long n` into int range and forwards to scalbnl; olm_scalbnl is copied
   VERBATIM from the verified model slice slice_libm_real_scalbnl.c. This is
   the LINK-layer proof (Rule 2) that every emitted symbol resolves and the
   trace is stable, with the real openlibm source injected (Rule 18).

   The probe pins the census cell scalblnl.f80: x = theta-tainted, n = 2
   (classical long), so the clamp const-folds and the body is the scalbnl
   census IR. */
#include <stdint.h>
#include <limits.h>

/* The exact amd64 x86_fp80 bit-pattern union (openlibm amd64_fpmath.h). */
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
};

/* openlibm s_copysignl.c copysignl (verbatim). */
__attribute__((always_inline)) static inline long double
olm_copysignl(long double x, long double y) {
    union IEEEl2bits ux, uy;
    ux.e = x;
    uy.e = y;
    ux.bits.sign = uy.bits.sign;
    return (ux.e);
}

/* openlibm s_copysign.c copysign (double) — word macros expanded to the
   __builtin_memcpy idiom (the verified slice_libm_real_scalbn.c body). */
__attribute__((always_inline)) static inline double
olm_copysign(double x, double y) {
    uint64_t bx, by;
    __builtin_memcpy(&bx, &x, 8);
    __builtin_memcpy(&by, &y, 8);
    bx = (bx & 0x7fffffffffffffffULL) | (by & 0x8000000000000000ULL);
    __builtin_memcpy(&x, &bx, 8);
    return x;
}

static const long double
huge = 0x1p16000L,
tiny = 0x1p-16000L;

/* openlibm s_scalbnl.c scalbnl (verbatim). */
__attribute__((always_inline)) static inline long double
olm_scalbnl(long double x, int n) {
    union IEEEl2bits u;
    int k;
    u.e = x;
    k = u.bits.exp;                             /* extract exponent */
    if (k==0) {                                 /* 0 or subnormal x */
        if ((u.bits.manh|u.bits.manl)==0) return x;   /* +-0 */
        u.e *= 0x1p+128;
        k = u.bits.exp - 128;
        if (n< -50000) return tiny*x;           /*underflow*/
    }
    if (k==0x7fff) return x+x;                  /* NaN or Inf */
    k = k+n;
    if (k >= 0x7fff) return huge*olm_copysignl(huge,x); /* overflow  */
    if (k > 0)                                  /* normal result */
        {u.bits.exp = k; return u.e;}
    if (k <= -128) {
        if (n > 50000)                          /* in case integer overflow in n+k */
            return huge*olm_copysign(huge,x);   /*overflow*/
        else return tiny*olm_copysign(tiny,x);  /*underflow*/
    }
    k += 128;                                   /* subnormal result */
    u.bits.exp = k;
    return u.e*0x1p-128;
}

/* openlibm s_scalbln.c scalblnl (verbatim). */
__attribute__((always_inline)) static inline long double
olm_scalblnl(long double x, long n) {
    int in;

    in = (int)n;
    if (in != n) {
        if (n > 0)
            in = INT_MAX;
        else
            in = INT_MIN;
    }
    return (olm_scalbnl(x, in));
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_scalblnl(q, 2L));
}

int main(void) {
    (void) slice();
    return 0;
}
