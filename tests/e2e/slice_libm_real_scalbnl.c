/* slice_libm_real_scalbnl.c — bd 3c6m.51 Inc 3: the REAL openlibm scalbnl body
   (s_scalbnl.c + s_copysignl.c + s_copysign.c, fdlibm-derived, BSD-licensed)
   over x86_fp80 `long double` — the FIRST long-double RMW slice. scalbnl is the
   multi-block fp80 union: one `union IEEEl2bits u` threaded across five basic
   blocks (an fp80 re-seed `u.e *= 0x1p+128` in the subnormal arm + TWO offset-8
   field-insert PACK arms `u.bits.exp = k; return u.e`, joined by a 5-way
   x86_fp80 return merge), plus the inlined copysignl's own two unions in the
   overflow arm. SROA cannot promote any of them at ANY opt level (the offset-8
   exponent word straddles the undefined padding bytes [10,16)).

   promoteFp80Union (multi-block since Inc 3) canonicalizes every union access
   to a full-width x86_fp80 load/store on a fresh promotable alloca (the i80
   extract/field-insert kept local) and lets LLVM's own PromoteMemToReg build
   the merge phis; the §4.1 per-bit padding-taint walk proves the store-backs'
   diverged bits land only in the dropped >= 80 padding range. PredMux then
   flattens the tainted exponent control and the kjd1 fp-select copy family
   lowers the f80 merges — the same downstream that carries scalbn.f64. This
   slice is the LINK-layer proof (Rule 2) that every emitted i80/f80 symbol
   resolves and the trace is stable.

   The probe pins the census cell scalbnl.f80: x = theta-tainted, n = 2
   (classical), so the |n|>50000 guards (and with them the double-copysign
   underflow arm, range-folded by clang) const-fold exactly as in the census
   IR. */
#include <stdint.h>

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

/* openlibm s_copysign.c copysign (double) — the GET/SET_HIGH_WORD word macros
   expanded to the __builtin_memcpy idiom (same body as the verified
   slice_libm_real_scalbn.c olm_copysign). */
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

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_scalbnl(q, 2));
}

int main(void) {
    (void) slice();
    return 0;
}
