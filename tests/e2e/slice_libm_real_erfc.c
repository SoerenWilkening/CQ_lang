/* slice_libm_real_erfc.c — bd 3c6m.53: the REAL openlibm erfc body
   (s_erf.c → __ieee754_exp (e_exp.c, inlined TWICE), fdlibm-derived,
   BSD-licensed; verbatim algorithm with the math_private.h word macros in the
   shim preamble). Census cell erfc.f64. erfc is the sibling of erf in
   s_erf.c (both call exp); this slice starts from the already-VERIFIED
   slice_libm_real_erf.c (olm_exp + all erf/erfc R/S/table constants) and
   ADDS olm_erfc verbatim from corpus s_erf.c, reusing the same constants plus
   half/two. LINK-layer proof (Rule 2), real-source injection (Rule 18).

   KEEP-SET CALLS (Rule 18 ship-floor fold, NOT a body substitution; bd tkju):
   the fabs sites of both vendored bodies are spelled __builtin_fabs. fabs is a
   HARDWARE KEEP — at the ship floor (plain clang -O1, builtins ON) it folds to
   @llvm.fabs.f64 before codegen and cq-lowering rewrites that to
   cq_template_fabs_f64: 2 in the golden, olm_erfc's two sites (olm_erf is
   unreachable from slice() and is dropped). A keep has no injectable body, so
   the four olm_fabs/olm_fabsf/olm_copysign/olm_copysignf software shims this
   slice used to vendor misrepresented the ship floor and are deleted — the
   fabs shim already folded to @llvm.fabs at -O1 and the other three were dead
   text, so the golden is byte-identical across the rewrite (8891 lines). */
#include <stdint.h>
typedef uint32_t u_int32_t;
typedef uint64_t u_int64_t;
/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define GET_HIGH_WORD(i,d)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)(__w>>32); }while(0)
#define GET_LOW_WORD(i,d)      do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)__w; }while(0)
#define SET_HIGH_WORD(d,v)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0x00000000ffffffffULL)|((uint64_t)(uint32_t)(v)<<32); __builtin_memcpy(&(d),&__w,8); }while(0)
#define SET_LOW_WORD(d,v)      do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0xffffffff00000000ULL)|(uint32_t)(v); __builtin_memcpy(&(d),&__w,8); }while(0)
#define INSERT_WORDS(d,hi,lo)  do{ uint64_t __w=((uint64_t)(uint32_t)(hi)<<32)|(uint32_t)(lo); __builtin_memcpy(&(d),&__w,8); }while(0)
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)
static const double
tiny = 1e-300,
half =  5.00000000000000000000e-01, /* 0x3FE00000, 0x00000000 */
one  = 1.00000000000000000000e+00, /* 0x3FF00000, 0x00000000 */
two  =  2.00000000000000000000e+00, /* 0x40000000, 0x00000000 */
erx  = 8.45062911510467529297e-01, /* 0x3FEB0AC1, 0x60000000 */
/* Coefficients for approximation to erf on [0,0.84375] */
efx  = 1.28379167095512586316e-01, /* 0x3FC06EBA, 0x8214DB69 */
efx8 = 1.02703333676410069053e+00, /* 0x3FF06EBA, 0x8214DB69 */
pp0  =  1.28379167095512558561e-01, /* 0x3FC06EBA, 0x8214DB68 */
pp1  = -3.25042107247001499370e-01, /* 0xBFD4CD7D, 0x691CB913 */
pp2  = -2.84817495755985104766e-02, /* 0xBF9D2A51, 0xDBD7194F */
pp3  = -5.77027029648944159157e-03, /* 0xBF77A291, 0x236668E4 */
pp4  = -2.37630166566501626084e-05, /* 0xBEF8EAD6, 0x120016AC */
qq1  =  3.97917223959155352819e-01, /* 0x3FD97779, 0xCDDADC09 */
qq2  =  6.50222499887672944485e-02, /* 0x3FB0A54C, 0x5536CEBA */
qq3  =  5.08130628187576562776e-03, /* 0x3F74D022, 0xC4D36B0F */
qq4  =  1.32494738004321644526e-04, /* 0x3F215DC9, 0x221C1A10 */
qq5  = -3.96022827877536812320e-06, /* 0xBED09C43, 0x42A26120 */
/* Coefficients for approximation to erf in [0.84375,1.25] */
pa0  = -2.36211856075265944077e-03, /* 0xBF6359B8, 0xBEF77538 */
pa1  =  4.14856118683748331666e-01, /* 0x3FDA8D00, 0xAD92B34D */
pa2  = -3.72207876035701323847e-01, /* 0xBFD7D240, 0xFBB8C3F1 */
pa3  =  3.18346619901161753674e-01, /* 0x3FD45FCA, 0x805120E4 */
pa4  = -1.10894694282396677476e-01, /* 0xBFBC6398, 0x3D3E28EC */
pa5  =  3.54783043256182359371e-02, /* 0x3FA22A36, 0x599795EB */
pa6  = -2.16637559486879084300e-03, /* 0xBF61BF38, 0x0A96073F */
qa1  =  1.06420880400844228286e-01, /* 0x3FBB3E66, 0x18EEE323 */
qa2  =  5.40397917702171048937e-01, /* 0x3FE14AF0, 0x92EB6F33 */
qa3  =  7.18286544141962662868e-02, /* 0x3FB2635C, 0xD99FE9A7 */
qa4  =  1.26171219808761642112e-01, /* 0x3FC02660, 0xE763351F */
qa5  =  1.36370839120290507362e-02, /* 0x3F8BEDC2, 0x6B51DD1C */
qa6  =  1.19844998467991074170e-02, /* 0x3F888B54, 0x5735151D */
/* Coefficients for approximation to erfc in [1.25,1/0.35] */
ra0  = -9.86494403484714822705e-03, /* 0xBF843412, 0x600D6435 */
ra1  = -6.93858572707181764372e-01, /* 0xBFE63416, 0xE4BA7360 */
ra2  = -1.05586262253232909814e+01, /* 0xC0251E04, 0x41B0E726 */
ra3  = -6.23753324503260060396e+01, /* 0xC04F300A, 0xE4CBA38D */
ra4  = -1.62396669462573470355e+02, /* 0xC0644CB1, 0x84282266 */
ra5  = -1.84605092906711035994e+02, /* 0xC067135C, 0xEBCCABB2 */
ra6  = -8.12874355063065934246e+01, /* 0xC0545265, 0x57E4D2F2 */
ra7  = -9.81432934416914548592e+00, /* 0xC023A0EF, 0xC69AC25C */
sa1  =  1.96512716674392571292e+01, /* 0x4033A6B9, 0xBD707687 */
sa2  =  1.37657754143519042600e+02, /* 0x4061350C, 0x526AE721 */
sa3  =  4.34565877475229228821e+02, /* 0x407B290D, 0xD58A1A71 */
sa4  =  6.45387271733267880336e+02, /* 0x40842B19, 0x21EC2868 */
sa5  =  4.29008140027567833386e+02, /* 0x407AD021, 0x57700314 */
sa6  =  1.08635005541779435134e+02, /* 0x405B28A3, 0xEE48AE2C */
sa7  =  6.57024977031928170135e+00, /* 0x401A47EF, 0x8E484A93 */
sa8  = -6.04244152148580987438e-02, /* 0xBFAEEFF2, 0xEE749A62 */
/* Coefficients for approximation to erfc in [1/.35,28] */
rb0  = -9.86494292470009928597e-03, /* 0xBF843412, 0x39E86F4A */
rb1  = -7.99283237680523006574e-01, /* 0xBFE993BA, 0x70C285DE */
rb2  = -1.77579549177547519889e+01, /* 0xC031C209, 0x555F995A */
rb3  = -1.60636384855821916062e+02, /* 0xC064145D, 0x43C5ED98 */
rb4  = -6.37566443368389627722e+02, /* 0xC083EC88, 0x1375F228 */
rb5  = -1.02509513161107724954e+03, /* 0xC0900461, 0x6A2E5992 */
rb6  = -4.83519191608651397019e+02, /* 0xC07E384E, 0x9BDC383F */
sb1  =  3.03380607434824582924e+01, /* 0x403E568B, 0x261D5190 */
sb2  =  3.25792512996573918826e+02, /* 0x40745CAE, 0x221B9F0A */
sb3  =  1.53672958608443695994e+03, /* 0x409802EB, 0x189D5118 */
sb4  =  3.19985821950859553908e+03, /* 0x40A8FFB7, 0x688C246A */
sb5  =  2.55305040643316442583e+03, /* 0x40A3F219, 0xCEDF3BE6 */
sb6  =  4.74528541206955367215e+02, /* 0x407DA874, 0xE79FE763 */
sb7  = -2.24409524465858183362e+01; /* 0xC03670E2, 0x42712D62 */

/* ---- e_exp.c, verbatim (see slice_libm_real_exp.c for the mechanism) ---- */
static const double
ex_one = 1.0,
halF[2] = {0.5, -0.5,},
ex_huge = 1.0e+300,
o_threshold =  7.09782712893383973096e+02,
u_threshold = -7.45133219101941108420e+02,
ln2HI[2] = { 6.93147180369123816490e-01, -6.93147180369123816490e-01,},
ln2LO[2] = { 1.90821492927058770002e-10, -1.90821492927058770002e-10,},
invln2 = 1.44269504088896338700e+00,
P1 =  1.66666666666666019037e-01,
P2 = -2.77777777770155933842e-03,
P3 =  6.61375632143793436117e-05,
P4 = -1.65339022054652515390e-06,
P5 =  4.13813679705723846039e-08;

static volatile double
twom1000 = 9.33263618503218878990e-302;     /* 2**-1000=0x01700000,0*/

__attribute__((always_inline)) static inline double olm_exp(double x) {
    double y, hi = 0.0, lo = 0.0, c, t, twopk;
    int32_t k = 0, xsb;
    uint32_t hx;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    hx = (uint32_t)(bits >> 32);
    xsb = (hx >> 31) & 1;
    hx &= 0x7fffffff;

    if (hx >= 0x40862E42) {
        if (hx >= 0x7ff00000) {
            uint32_t lx;
            __builtin_memcpy(&bits, &x, 8);              /* GET_LOW_WORD */
            lx = (uint32_t)bits;
            if (((hx & 0xfffff) | lx) != 0)
                return x + x;
            else return (xsb == 0) ? x : 0.0;
        }
        if (x > o_threshold) return ex_huge * ex_huge;
        if (x < u_threshold) return twom1000 * twom1000;
    }
    if (x == 1.0)
        return 2.718281828459045235360;
    if (hx > 0x3fd62e42) {
        if (hx < 0x3FF0A2B2) {
            hi = x - ln2HI[xsb]; lo = ln2LO[xsb]; k = 1 - xsb - xsb;
        } else {
            k  = (int)(invln2 * x + halF[xsb]);
            t  = k;
            hi = x - t * ln2HI[0];
            lo = t * ln2LO[0];
        }
        x = hi - lo;                        /* STRICT_ASSIGN */
    }
    else if (hx < 0x3e300000) {
        if (ex_huge + x > ex_one) return ex_one + x;
    }
    else k = 0;
    t = x * x;
    if (k >= -1021) {
        bits = (uint64_t)(uint32_t)(0x3ff00000 + (k << 20)) << 32;
        __builtin_memcpy(&twopk, &bits, 8);              /* INSERT_WORDS */
    } else {
        bits = (uint64_t)(uint32_t)(0x3ff00000 + ((k + 1000) << 20)) << 32;
        __builtin_memcpy(&twopk, &bits, 8);              /* INSERT_WORDS */
    }
    c = x - t * (P1 + t * (P2 + t * (P3 + t * (P4 + t * P5))));
    if (k == 0)  return ex_one - ((x * c) / (c - 2.0) - x);
    else         y = ex_one - ((lo - (x * c) / (2.0 - c)) - hi);
    if (k >= -1021) {
        if (k == 1024) return y * 2.0 * 0x1p1023;
        return y * twopk;
    } else {
        return y * twopk * twom1000;
    }
}

__attribute__((always_inline)) static inline double olm_erf(double x) {
    int32_t hx, ix, i;
    double R, S, P, Q, s, y, z, r;
    uint64_t bits;
    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    hx = (int32_t)(bits >> 32);
    ix = hx & 0x7fffffff;
    if (ix >= 0x7ff00000) {         /* erf(nan)=nan */
        i = ((uint32_t)hx >> 31) << 1;
        return (double)(1 - i) + one / x;  /* erf(+-inf)=+-1 */
    }

    if (ix < 0x3feb0000) {          /* |x|<0.84375 */
        if (ix < 0x3e300000) {      /* |x|<2**-28 */
            if (ix < 0x00800000)
                return 0.125 * (8.0 * x + efx8 * x);  /*avoid underflow */
            return x + efx * x;
        }
        z = x * x;
        r = pp0 + z * (pp1 + z * (pp2 + z * (pp3 + z * pp4)));
        s = one + z * (qq1 + z * (qq2 + z * (qq3 + z * (qq4 + z * qq5))));
        y = r / s;
        return x + x * y;
    }
    if (ix < 0x3ff40000) {          /* 0.84375 <= |x| < 1.25 */
        s = __builtin_fabs(x) - one;
        P = pa0 + s * (pa1 + s * (pa2 + s * (pa3 + s * (pa4 + s * (pa5 + s * pa6)))));
        Q = one + s * (qa1 + s * (qa2 + s * (qa3 + s * (qa4 + s * (qa5 + s * qa6)))));
        if (hx >= 0) return erx + P / Q; else return -erx - P / Q;
    }
    if (ix >= 0x40180000) {         /* inf>|x|>=6 */
        if (hx >= 0) return one - tiny; else return tiny - one;
    }
    x = __builtin_fabs(x);
    s = one / (x * x);
    if (ix < 0x4006DB6E) {          /* |x| < 1/0.35 */
        R = ra0 + s * (ra1 + s * (ra2 + s * (ra3 + s * (ra4 + s * (
                    ra5 + s * (ra6 + s * ra7))))));
        S = one + s * (sa1 + s * (sa2 + s * (sa3 + s * (sa4 + s * (
                    sa5 + s * (sa6 + s * (sa7 + s * sa8)))))));
    } else {                        /* |x| >= 1/0.35 */
        R = rb0 + s * (rb1 + s * (rb2 + s * (rb3 + s * (rb4 + s * (
                    rb5 + s * rb6)))));
        S = one + s * (sb1 + s * (sb2 + s * (sb3 + s * (sb4 + s * (
                    sb5 + s * (sb6 + s * sb7))))));
    }
    z = x;
    __builtin_memcpy(&bits, &z, 8);                      /* SET_LOW_WORD(z,0) */
    bits = bits & 0xffffffff00000000ULL;
    __builtin_memcpy(&z, &bits, 8);
    r = olm_exp(-z * z - 0.5625) * olm_exp((z - x) * (z + x) + R / S);
    if (hx >= 0) return one - r / x; else return r / x - one;
}

__attribute__((always_inline)) static inline double olm_erfc(double x) {
    int32_t hx, ix;
    double R, S, P, Q, s, y, z, r;
    GET_HIGH_WORD(hx, x);
    ix = hx & 0x7fffffff;
    if (ix >= 0x7ff00000) {                 /* erfc(nan)=nan */
                                            /* erfc(+-inf)=0,2 */
        return (double)(((u_int32_t)hx >> 31) << 1) + one / x;
    }

    if (ix < 0x3feb0000) {              /* |x|<0.84375 */
        if (ix < 0x3c700000)            /* |x|<2**-56 */
            return one - x;
        z = x * x;
        r = pp0 + z * (pp1 + z * (pp2 + z * (pp3 + z * pp4)));
        s = one + z * (qq1 + z * (qq2 + z * (qq3 + z * (qq4 + z * qq5))));
        y = r / s;
        if (hx < 0x3fd00000) {          /* x<1/4 */
            return one - (x + x * y);
        } else {
            r = x * y;
            r += (x - half);
            return half - r;
        }
    }
    if (ix < 0x3ff40000) {              /* 0.84375 <= |x| < 1.25 */
        s = __builtin_fabs(x) - one;
        P = pa0 + s * (pa1 + s * (pa2 + s * (pa3 + s * (pa4 + s * (pa5 + s * pa6)))));
        Q = one + s * (qa1 + s * (qa2 + s * (qa3 + s * (qa4 + s * (qa5 + s * qa6)))));
        if (hx >= 0) {
            z = one - erx; return z - P / Q;
        } else {
            z = erx + P / Q; return one + z;
        }
    }
    if (ix < 0x403c0000) {              /* |x|<28 */
        x = __builtin_fabs(x);
        s = one / (x * x);
        if (ix < 0x4006DB6D) {  /* |x| < 1/.35 ~ 2.857143*/
            R = ra0 + s * (ra1 + s * (ra2 + s * (ra3 + s * (ra4 + s * (
                        ra5 + s * (ra6 + s * ra7))))));
            S = one + s * (sa1 + s * (sa2 + s * (sa3 + s * (sa4 + s * (
                        sa5 + s * (sa6 + s * (sa7 + s * sa8)))))));
        } else {                        /* |x| >= 1/.35 ~ 2.857143 */
            if (hx < 0 && ix >= 0x40180000) return two - tiny;/* x < -6 */
            R = rb0 + s * (rb1 + s * (rb2 + s * (rb3 + s * (rb4 + s * (
                        rb5 + s * rb6)))));
            S = one + s * (sb1 + s * (sb2 + s * (sb3 + s * (sb4 + s * (
                        sb5 + s * (sb6 + s * sb7))))));
        }
        z = x;
        SET_LOW_WORD(z, 0);
        r = olm_exp(-z * z - 0.5625) *
            olm_exp((z - x) * (z + x) + R / S);
        if (hx > 0) return r / x; else return two - r / x;
    } else {
        if (hx > 0) return tiny * tiny; else return two - tiny;
    }
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_erfc(q));
}
int main(void) { (void) slice(); return 0; }
