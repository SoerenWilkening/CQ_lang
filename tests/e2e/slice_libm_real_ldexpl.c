/* slice_libm_real_ldexpl.c — bd 3c6m.51 Inc 3 (keep-set repair bd tkju): the
   REAL openlibm ldexpl body (census cell ldexpl.f80). openlibm defines ldexpl
   via openlibm_strong_reference(scalbnl, ldexpl) in src/s_scalbnl.c — ldexpl IS
   the scalbnl body, byte-for-byte. So olm_scalbnl is copied VERBATIM from the
   verified model slice slice_libm_real_scalbnl.c, and olm_ldexpl is the
   strong-reference alias forwarding to it (the slice_libm_real_ldexp.c f64
   precedent). This is the LINK-layer proof (Rule 2) that every emitted symbol
   resolves and the trace is stable, with the real openlibm source injected
   (Rule 18).

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution; bd tkju):
   scalbnl's overflow/underflow arms call copysignl (1 site, f80) and copysign
   (2 sites, f64), all 3 spelled __builtin_copysign[l]. Both are HARDWARE KEEPS
   — at the ship floor (plain clang -O1, builtins ON) they fold to
   @llvm.copysign.f80 / .f64 before codegen and cq-lowering rewrites that to
   cq_template_copysign_<W> — so a keep has no injectable body and openlibm's
   software s_copysignl.c / s_copysign.c are NOT vendored. Dropping the earlier
   vendored bodies moved the trace 258 -> 250 lines: the copysignl union RMW
   collapsed to 1 cq_template_copysign_f80_lh, and the f64 sites fold out
   entirely (zero f64 templates in the trace, before and after).

   The probe pins the census cell ldexpl.f80: x = theta-tainted, n = 2
   (classical). */
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


static const long double
huge = 0x1p16000L,
tiny = 0x1p-16000L;

/* openlibm s_scalbnl.c scalbnl (verbatim, bar the 3 copysign call sites spelled
   as the keep builtins — see KEEP-SET above). */
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
    if (k >= 0x7fff) return huge*__builtin_copysignl(huge,x); /* overflow  */
    if (k > 0)                                  /* normal result */
        {u.bits.exp = k; return u.e;}
    if (k <= -128) {
        if (n > 50000)                          /* in case integer overflow in n+k */
            return huge*__builtin_copysign(huge,x);   /*overflow*/
        else return tiny*__builtin_copysign(tiny,x);  /*underflow*/
    }
    k += 128;                                   /* subnormal result */
    u.bits.exp = k;
    return u.e*0x1p-128;
}

/* openlibm: openlibm_strong_reference(scalbnl, ldexpl) — ldexpl aliases scalbnl */
__attribute__((always_inline)) static inline long double
olm_ldexpl(long double x, int n) {
    return olm_scalbnl(x, n);
}

long double slice(void) {
    long double q = 0.5L; cq_theta(&q, 0.5);
    return cq_measure(olm_ldexpl(q, 2));
}

int main(void) {
    (void) slice();
    return 0;
}
