/* slice_libm_real_scalbnl.c — bd 3c6m.51 Inc 3 (keep-set repair bd tkju): the
   REAL openlibm scalbnl body (s_scalbnl.c, fdlibm-derived, BSD-licensed) over
   x86_fp80 `long double` — the FIRST long-double RMW slice. scalbnl is the
   multi-block fp80 union: one `union IEEEl2bits u` threaded across five basic
   blocks (an fp80 re-seed `u.e *= 0x1p+128` in the subnormal arm + TWO offset-8
   field-insert PACK arms `u.bits.exp = k; return u.e`, joined by a 5-way
   x86_fp80 return merge). SROA cannot promote it at ANY opt level (the offset-8
   exponent word straddles the undefined padding bytes [10,16)).

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution; bd tkju):
   the overflow arm calls copysignl (1 site, f80) and the k <= -128 arm calls
   copysign (2 sites, f64). Both are HARDWARE KEEPS: at the ship floor (plain
   clang -O1, builtins ON) they fold to @llvm.copysign.f80 / .f64 before codegen
   and cq-lowering rewrites that construct to cq_template_copysign_<W>. All 3
   sites are spelled __builtin_copysign[l]; openlibm's software s_copysignl.c /
   s_copysign.c are NOT vendored — a keep has no injectable body, so vendoring
   one models a program the ship floor never compiles. That earlier vendoring
   was live, not dead, code here: dropping it moved the trace 258 -> 250 lines,
   the copysignl union RMW (9 template calls — or_i80_hl and or_i64_hl entirely,
   plus one each of lshr_i80_hl / trunc_i80_to_i16 / zext_i16_to_i64 /
   and_i64_hl / zext_i64_to_i80 / shl_i80_hl / bitcast_i80_to_f80) collapsing to
   the single cq_template_copysign_f80_lh keep. The f64 copysign sites fold out
   entirely — zero f64 templates in the trace, before and after — so the
   vendored double body was dead text; only the f80 one was ever reached.

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
   (classical), so the |n|>50000 guards — and with them the two f64 copysign
   sites — const-fold exactly as in the census IR. */
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

long double slice(void) {
    long double q = 0.5L; cq_theta(&q, 0.5);
    return cq_measure(olm_scalbnl(q, 2));
}

int main(void) {
    (void) slice();
    return 0;
}
