/* slice_libm_real_acos.c — bd 3c6m.60: the REAL openlibm acos body
   (src/e_acos.c, Sun/fdlibm-derived). The vendored region below is
   TOKEN-IDENTICAL to the corpus once the mechanical edits declared at the
   bottom of this header are reverse-applied (verified 2026-07-25 by scripted
   comment-strip + tokenize of both sides: equal token counts, zero hunks).

   This cell is the KEEP-SET HARNESS FIX made honest. e_acos.c contains ZERO
   loops in its own body, yet the census reported acos.f64 as a decline whose
   MEASURED diagnostic is `cq controlled lowering: loop under quantum control`
   (LoopLowering.cpp; the message means the TRIP COUNT is quantum-dependent —
   it says nothing about control inside a body). Cause: the corpus recipe built
   every openlibm .c with a blanket `-fno-builtin`, so the inner `sqrt(z)`
   resolved to openlibm's SOFTWARE __ieee754_sqrt and dragged in ITS
   subnormal-normalize loop (src/e_sqrt.c:118, `while(ix0==0)`) — that loop, in
   a DIFFERENT file, is the decline site; nothing in e_acos.c ever was. At the
   real ship floor — plain `clang -O1`, builtins ON — `sqrt` is a Rule-18
   HARDWARE KEEP: it folds to @llvm.sqrt.f64 before codegen and cq-lowering
   rewrites it to cq_template_sqrt_f64 (2 calls, one per sqrt-bearing arm).
   This slice pins that ship-floor route, so `__builtin_sqrt` is the deliberate
   spelling (identical construct, no libm declaration needed).

   Lowering exercised: the classification cascade over the tainted exponent word
   (|x|>=1 / |x|<0.5 / x<-0.5 / x>0.5) flattens through PredMux to the select
   substrate (6 `br i1` before the pass, 0 after); the Horner pS/qS polynomials
   ride the arithmetic templates; SET_LOW_WORD on `df` is a register bit-mask
   after SROA; and the four `pio2_lo` reads fold to the initializer. That last
   fold is `foldVolatileConstGlobalLoads` — bd 3c6m.14 Inc 3, QramLowering.cpp —
   because `pio2_lo` is a file-scope `static volatile double`, i.e. an internal
   GLOBAL (`load volatile double, ptr @pio2_lo` x4 pre-pass; zero `volatile`
   post-pass). It is NOT bd zco4 / promoteVolatileScalarLocals: that is the
   non-escaping-alloca sibling, and its decline set explicitly excludes a
   volatile global, so citing it here would send a reader to a ticket that by
   construction does not cover this cell. This slice is the LINK-layer proof
   (Rule 2) that every emitted symbol resolves and the trace is stable.

   MECHANICAL EDITS vs the corpus — the complete list; NO constant, branch,
   comparison operator, declaration order, signedness or expression is changed,
   and the `volatile` on pio2_lo is kept verbatim:
     - Sun Microsystems 1993 fdlibm license notice, the FBSDID line and the
       Method comment block DELETED (project convention for these slices; note
       the notice's own terms ask that it be preserved, so this file is NOT a
       redistributable copy of e_acos.c);
     - `cdefs-compat.h` / <float.h> / <openlibm_math.h> / "math_private.h"
       includes dropped, replaced by a single <stdint.h>;
     - `OLM_DLLEXPORT double __ieee754_acos` renamed/requalified to
       `__attribute__((always_inline)) static inline double olm_acos`;
     - the math_private.h word macros expanded to the __builtin_memcpy idiom
       clang -O1 folds to the same bitcast IR: GET_HIGH_WORD -> memcpy + `>>32`,
       GET_LOW_WORD -> memcpy + `(uint32_t)`, SET_LOW_WORD(df,0) -> memcpy +
       `&= 0xffffffff00000000ULL` + memcpy (the one added hex literal in the
       vendored region);
     - one added local `uint64_t bits;` — scratch for those three shims;
     - `u_int32_t lx` -> `uint32_t lx` (same signedness; drops sys/types.h);
     - both `sqrt(z)` calls -> `__builtin_sqrt(z)` (the keep-set route above);
     - the trailing `#if LDBL_MANT_DIG == 53 / openlibm_weak_reference(acos,
       acosl) / #endif` dropped — dead on this target (__LDBL_MANT_DIG__ == 64);
     - whitespace/tab reflow only.
   `slice()` and `main()` at the bottom are the CQ harness, not vendored code. */
#include <stdint.h>

static const double
one = 1.00000000000000000000e+00, /* 0x3FF00000, 0x00000000 */
pi  = 3.14159265358979311600e+00, /* 0x400921FB, 0x54442D18 */
pio2_hi = 1.57079632679489655800e+00; /* 0x3FF921FB, 0x54442D18 */
static volatile double
pio2_lo = 6.12323399573676603587e-17; /* 0x3C91A626, 0x33145C07 */
static const double
pS0 =  1.66666666666666657415e-01, /* 0x3FC55555, 0x55555555 */
pS1 = -3.25565818622400915405e-01, /* 0xBFD4D612, 0x03EB6F7D */
pS2 =  2.01212532134862925881e-01, /* 0x3FC9C155, 0x0E884455 */
pS3 = -4.00555345006794114027e-02, /* 0xBFA48228, 0xB5688F3B */
pS4 =  7.91534994289814532176e-04, /* 0x3F49EFE0, 0x7501B288 */
pS5 =  3.47933107596021167570e-05, /* 0x3F023DE1, 0x0DFDF709 */
qS1 = -2.40339491173441421878e+00, /* 0xC0033A27, 0x1C8A2D4B */
qS2 =  2.02094576023350569471e+00, /* 0x40002AE5, 0x9C598AC8 */
qS3 = -6.88283971605453293030e-01, /* 0xBFE6066C, 0x1B8D0159 */
qS4 =  7.70381505559019352791e-02; /* 0x3FB3B8C5, 0xB12E9282 */

/* openlibm src/e_acos.c __ieee754_acos, vendored verbatim modulo the mechanical
   edits enumerated in the file header — that list is the faithfulness contract;
   do not add an undeclared difference here. */
__attribute__((always_inline)) static inline double olm_acos(double x) {
    double z, p, q, r, w, s, c, df;
    int32_t hx, ix;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    hx = (int32_t)(bits >> 32);
    ix = hx & 0x7fffffff;
    if (ix >= 0x3ff00000) {             /* |x| >= 1 */
        uint32_t lx;
        __builtin_memcpy(&bits, &x, 8);                  /* GET_LOW_WORD */
        lx = (uint32_t)bits;
        if (((ix - 0x3ff00000) | lx) == 0) {             /* |x| == 1 */
            if (hx > 0) return 0.0;                      /* acos(1) = 0 */
            else return pi + 2.0 * pio2_lo;              /* acos(-1) = pi */
        }
        return (x - x) / (x - x);       /* acos(|x|>1) is NaN */
    }
    if (ix < 0x3fe00000) {              /* |x| < 0.5 */
        if (ix <= 0x3c600000) return pio2_hi + pio2_lo;  /* if |x| < 2**-57 */
        z = x * x;
        p = z * (pS0 + z * (pS1 + z * (pS2 + z * (pS3 + z * (pS4 + z * pS5)))));
        q = one + z * (qS1 + z * (qS2 + z * (qS3 + z * qS4)));
        r = p / q;
        return pio2_hi - (x - (pio2_lo - x * r));
    } else if (hx < 0) {                /* x < -0.5 */
        z = (one + x) * 0.5;
        p = z * (pS0 + z * (pS1 + z * (pS2 + z * (pS3 + z * (pS4 + z * pS5)))));
        q = one + z * (qS1 + z * (qS2 + z * (qS3 + z * qS4)));
        s = __builtin_sqrt(z);
        r = p / q;
        w = r * s - pio2_lo;
        return pi - 2.0 * (s + w);
    } else {                            /* x > 0.5 */
        z = (one - x) * 0.5;
        s = __builtin_sqrt(z);
        df = s;
        __builtin_memcpy(&bits, &df, 8);                 /* SET_LOW_WORD(df,0) */
        bits &= 0xffffffff00000000ULL;
        __builtin_memcpy(&df, &bits, 8);
        c = (z - df * df) / (s + df);
        p = z * (pS0 + z * (pS1 + z * (pS2 + z * (pS3 + z * (pS4 + z * pS5)))));
        q = one + z * (qS1 + z * (qS2 + z * (qS3 + z * qS4)));
        r = p / q;
        w = r * s + c;
        return 2.0 * (df + w);
    }
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_acos(q));
}
int main(void) { (void) slice(); return 0; }
