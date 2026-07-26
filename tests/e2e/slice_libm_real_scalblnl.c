/* slice_libm_real_scalblnl.c — bd 3c6m.51 Inc 3 (keep-set repair bd tkju): the
   REAL openlibm scalblnl body (census cell scalblnl.f80). openlibm s_scalbln.c
   scalblnl clamps the `long n` into int range and forwards to scalbnl;
   olm_scalbnl is copied VERBATIM from the verified model slice
   slice_libm_real_scalbnl.c. This is the LINK-layer proof (Rule 2) that every
   emitted symbol resolves and the trace is stable, with the real openlibm
   source injected (Rule 18).

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
