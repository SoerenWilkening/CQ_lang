/* slice_libm_real_tanh.c — bd 3c6m.14 / L6 Inc 2: the REAL openlibm tanh
   body (s_tanh.c → expm1 (s_expm1.c, inlined TWICE — once per |x| branch),
   fdlibm-derived, BSD-licensed; verbatim algorithms with
   the math_private.h word macros expanded to the __builtin_memcpy idiom
   clang -O1 folds to the same bitcast IR). This is the Inc-2 MECHANISM cell:
   expm1's argument reduction computes `k = invln2*x + ((xsb==0)?0.5:-0.5)`
   (s_expm1.c:168), where clang -O1 routes `xsb==0` to the ternary through an
   i1 PHI at an internal merge. Inc 1 converted that phi to an i1 select
   chain, pushing the consuming select's condition off the 3c6m.12
   and/or-over-compare-leaves flag-mint grammar — the census tanh.f64 decline.
   Inc 2 converts a grammar-conforming i1 phi to boolean algebra
   (∨ᵢ EP(eᵢ)∧vᵢ) instead, so the muxed condition stays mintable
   (control_predmux_accept_i1phi_cond{,_fp}.ll pin the mechanism; this slice
   is the LINK-layer proof, Rule 2). Beyond the i1 phi, the doubly-inlined
   expm1 brings the deepest Inc-2 DAG: ~4-level nests with 5-way return
   merges, INSERT_WORDS twopk construction from the shifted k, and the
   filter/reduction/polynomial pipeline — all under the top-level |x| split.

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution; bd tkju):
     s_tanh.c's two fabs(x) sites (one in each arm of the |x|>=1 split) are
     __builtin_fabs. fabs is a HARDWARE KEEP — at the real ship floor (plain
     clang -O1, builtins ON) it folds to @llvm.fabs.f64 before codegen and
     cq-lowering rewrites that to cq_template_fabs_f64, 1 of which the
     committed golden carries. A keep has no injectable body, so the
     high-word-mask fabs shim this slice used to vendor MISREPRESENTED the ship
     floor. That shim already folded to @llvm.fabs at -O1 (measured), so
     deleting it left the lowered IR and the golden byte-identical — 8008 trace
     lines before and after; the i1-phi mechanism claim above is untouched by
     the rewrite (it lives in expm1's argument reduction, not in fabs). */
#include <stdint.h>

static const double one = 1.0, two = 2.0, tiny = 1.0e-300, huge = 1.0e300;

static const double
em1_o_threshold = 7.09782712893383973096e+02, /* 0x40862E42, 0xFEFA39EF */
em1_ln2_hi      = 6.93147180369123816490e-01, /* 0x3fe62e42, 0xfee00000 */
em1_ln2_lo      = 1.90821492927058770002e-10, /* 0x3dea39ef, 0x35793c76 */
em1_invln2      = 1.44269504088896338700e+00, /* 0x3ff71547, 0x652b82fe */
/* Scaled Q's: Qn_here = 2**n * Qn_above, for R(2*z) where z = hxs = x*x/2: */
Q1 = -3.33333333333331316428e-02, /* BFA11111 111110F4 */
Q2 =  1.58730158725481460165e-03, /* 3F5A01A0 19FE5585 */
Q3 = -7.93650757867487942473e-05, /* BF14CE19 9EAADBB7 */
Q4 =  4.00821782732936239552e-06, /* 3ED0CFCA 86E65239 */
Q5 = -2.01099218183624371326e-07; /* BE8AFDB7 6E09C32D */
__attribute__((always_inline)) static inline double olm_expm1(double x) {
    double y, hi, lo, c, t, e, hxs, hfx, r1, twopk;
    int32_t k, xsb;
    uint32_t hx;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    hx = (uint32_t)(bits >> 32);
    xsb = hx & 0x80000000;      /* sign bit of x */
    hx &= 0x7fffffff;           /* high word of |x| */

    /* filter out huge and non-finite argument */
    if (hx >= 0x4043687A) {                 /* if |x|>=56*ln2 */
        if (hx >= 0x40862E42) {             /* if |x|>=709.78... */
            if (hx >= 0x7ff00000) {
                uint32_t low;
                __builtin_memcpy(&bits, &x, 8);          /* GET_LOW_WORD */
                low = (uint32_t)bits;
                if (((hx & 0xfffff) | low) != 0)
                    return x + x;           /* NaN */
                else return (xsb == 0) ? x : -1.0; /* exp(+-inf)-1={inf,-1} */
            }
            if (x > em1_o_threshold) return huge * huge; /* overflow */
        }
        if (xsb != 0) {  /* x < -56*ln2, return -1.0 with inexact */
            if (x + tiny < 0.0)             /* raise inexact */
                return tiny - one;          /* return -1 */
        }
    }

    /* argument reduction */
    if (hx > 0x3fd62e42) {                  /* if  |x| > 0.5 ln2 */
        if (hx < 0x3FF0A2B2) {              /* and |x| < 1.5 ln2 */
            if (xsb == 0)
                { hi = x - em1_ln2_hi; lo =  em1_ln2_lo; k =  1; }
            else
                { hi = x + em1_ln2_hi; lo = -em1_ln2_lo; k = -1; }
        } else {
            k  = em1_invln2 * x + ((xsb == 0) ? 0.5 : -0.5);
            t  = k;
            hi = x - t * em1_ln2_hi;        /* t*ln2_hi is exact here */
            lo = t * em1_ln2_lo;
        }
        x = hi - lo;                        /* STRICT_ASSIGN */
        c = (hi - x) - lo;
    }
    else if (hx < 0x3c900000) {             /* when |x|<2**-54, return x */
        t = huge + x;   /* return x with inexact flags when x!=0 */
        return x - (t - (huge + x));
    }
    else k = 0;

    /* x is now in primary range */
    hfx = 0.5 * x;
    hxs = x * hfx;
    r1 = one + hxs * (Q1 + hxs * (Q2 + hxs * (Q3 + hxs * (Q4 + hxs * Q5))));
    t  = 3.0 - r1 * hfx;
    e  = hxs * ((r1 - t) / (6.0 - x * t));
    if (k == 0) return x - (x * e - hxs);   /* c is 0 */
    else {
        bits = (uint64_t)(uint32_t)(0x3ff00000 + (k << 20)) << 32;
        __builtin_memcpy(&twopk, &bits, 8); /* INSERT_WORDS: 2^k */
        e  = (x * (e - c) - c);
        e -= hxs;
        if (k == -1) return 0.5 * (x - e) - 0.5;
        if (k == 1) {
            if (x < -0.25) return -2.0 * (e - (x + 0.5));
            else           return one + 2.0 * (x - e);
        }
        if (k <= -2 || k > 56) {  /* suffice to return exp(x)-1 */
            y = one - (e - x);
            if (k == 1024) y = y * 2.0 * 0x1p1023;
            else y = y * twopk;
            return y - one;
        }
        t = one;
        if (k < 20) {
            __builtin_memcpy(&bits, &t, 8); /* SET_HIGH_WORD: t=1-2^-k */
            bits = (bits & 0xffffffffULL) |
                   ((uint64_t)(uint32_t)(0x3ff00000 - (0x200000 >> k)) << 32);
            __builtin_memcpy(&t, &bits, 8);
            y = t - (e - x);
            y = y * twopk;
        } else {
            __builtin_memcpy(&bits, &t, 8); /* SET_HIGH_WORD: 2^-k */
            bits = (bits & 0xffffffffULL) |
                   ((uint64_t)(uint32_t)((0x3ff - k) << 20) << 32);
            __builtin_memcpy(&t, &bits, 8);
            y = x - (e + t);
            y += one;
            y = y * twopk;
        }
    }
    return y;
}

__attribute__((always_inline)) static inline double olm_tanh(double x) {
    double t, z;
    int32_t jx, ix;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    jx = (int32_t)(bits >> 32);
    ix = jx & 0x7fffffff;

    /* x is INF or NaN */
    if (ix >= 0x7ff00000) {
        if (jx >= 0) return one / x + one;  /* tanh(+-inf)=+-1 */
        else         return one / x - one;  /* tanh(NaN) = NaN */
    }

    /* |x| < 22 */
    if (ix < 0x40360000) {          /* |x|<22 */
        if (ix < 0x3e300000) {      /* |x|<2**-28 */
            if (huge + x > one) return x; /* tanh(tiny) = tiny with inexact */
        }
        if (ix >= 0x3ff00000) {     /* |x|>=1 */
            t = olm_expm1(two * __builtin_fabs(x));
            z = one - two / (t + two);
        } else {
            t = olm_expm1(-two * __builtin_fabs(x));
            z = -t / (t + two);
        }
    /* |x| >= 22, return +-1 */
    } else {
        z = one - tiny;             /* raise inexact flag */
    }
    return (jx >= 0) ? z : -z;
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_tanh(q));
}
int main(void) { (void) slice(); return 0; }
