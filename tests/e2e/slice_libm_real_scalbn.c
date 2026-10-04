/* slice_libm_real_scalbn.c — bd 3c6m.14 / L6 Inc 1: the REAL openlibm scalbn
   body (s_scalbn.c, fdlibm-derived, BSD-licensed; verbatim algorithm with the
   math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast IR). UNLIKE slice_branchless_scalbn.c (the L1
   authored substitute that dissolves the branches), this body carries the full
   nested tainted control the census flags — pre-pass @slice is 11 blocks / 5
   conditional br (the k==0 subnormal arm with its nested +-0 test, the NaN/Inf
   test, the overflow test, the normal/subnormal split), with a cross-arm DAG
   join carrying 3 phis and a 5-way return merge. PredMux (PredMuxFlatten.cpp)
   flattens it to edge-predicated select chains; the shipped select/conjunction
   substrate lowers those; this slice is the LINK-layer proof (Rule 2) that
   every emitted symbol resolves and the trace is stable.

   The probe pins the census cell scalbn.f64: x = theta-tainted, n = 2
   (classical), so the |n|>50000 guards const-fold exactly as in the census IR.

   KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution — bd tkju):
   the overflow/underflow arms' copysign is a HARDWARE KEEP. At the ship floor (plain
   clang -O1, builtins ON) the named call folds to @llvm.copysign.f64 before
   codegen and cq-lowering rewrites that to cq_template_copysign_f64_lh (the
   literal `huge` + the tainted handle), and __builtin_copysign emits exactly
   that construct. A keep has no injectable body, so vendoring openlibm's
   s_copysign.c bit-op ladder here misrepresented the ship floor; that shim
   (olm_copysign) is deleted. MEASURED: its 4 template calls (one each of
   bitcast_f64_to_i64 / and_i64_hl / or_i64_hl / bitcast_i64_to_f64) collapse
   to the single copysign template — trace 253 -> 250 lines. */
#include <stdint.h>
static const double two54  = 1.80143985094819840000e+16; /* 0x43500000, 0x00000000 */
static const double twom54 = 5.55111512312578270212e-17; /* 0x3C900000, 0x00000000 */
static const double huge   = 1.0e+300;
static const double tiny   = 1.0e-300;

__attribute__((always_inline)) static inline double olm_scalbn(double x, int n) {
    int32_t k, hx, lx;
    uint64_t bits;
    __builtin_memcpy(&bits, &x, 8);                      /* EXTRACT_WORDS */
    hx = (int32_t)(bits >> 32);
    lx = (int32_t)bits;
    k = (hx & 0x7ff00000) >> 20;                         /* extract exponent */
    if (k == 0) {                                        /* 0 or subnormal x */
        if ((lx | (hx & 0x7fffffff)) == 0) return x;     /* +-0 */
        x *= two54;
        __builtin_memcpy(&bits, &x, 8);                  /* GET_HIGH_WORD */
        hx = (int32_t)(bits >> 32);
        k = ((hx & 0x7ff00000) >> 20) - 54;
        if (n < -50000) return tiny * x;                 /* underflow */
    }
    if (k == 0x7ff) return x + x;                        /* NaN or Inf */
    k = k + n;
    if (k > 0x7fe) return huge * __builtin_copysign(huge, x);  /* overflow */
    if (k > 0) {                                         /* normal result */
        __builtin_memcpy(&bits, &x, 8);                  /* SET_HIGH_WORD */
        bits = (bits & 0xffffffffULL) |
               ((uint64_t)(uint32_t)((hx & 0x800fffff) | (k << 20)) << 32);
        __builtin_memcpy(&x, &bits, 8);
        return x;
    }
    if (k <= -54) {
        if (n > 50000)                                   /* n+k overflowed */
            return huge * __builtin_copysign(huge, x);         /* overflow */
        else
            return tiny * __builtin_copysign(tiny, x);         /* underflow */
    }
    k += 54;                                             /* subnormal result */
    __builtin_memcpy(&bits, &x, 8);                      /* SET_HIGH_WORD */
    bits = (bits & 0xffffffffULL) |
           ((uint64_t)(uint32_t)((hx & 0x800fffff) | (k << 20)) << 32);
    __builtin_memcpy(&x, &bits, 8);
    return x * twom54;
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_scalbn(q, 2));
}
int main(void) { (void) slice(); return 0; }
