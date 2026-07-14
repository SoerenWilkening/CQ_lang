/* slice_libm_real_sinh.c — bd 3c6m.53: the REAL openlibm sinh body
   (e_sinh.c → expm1 (s_expm1.c) → __ieee754_exp (e_exp.c) → __ldexp_exp /
   __frexp_exp (k_exp.c); fdlibm/BSD-licensed; verbatim algorithms with the
   math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast IR the taint pass lowers). The olm_expm1 helper is
   copied VERBATIM from the verified slice_libm_real_tanh.c; olm_exp VERBATIM
   from the verified slice_libm_real_exp.c; olm_frexp_exp / olm_ldexp_exp
   vendored fresh from k_exp.c. sinh's |x| branches select among the expm1
   small-arg path, the 0.5*exp(|x|) mid path, and the __ldexp_exp large-arg
   path — the deepest combined DAG under a tainted top-level |x| split. This
   slice is the LINK-layer proof (Rule 2) promoting the census cell sinh.f64
   from injection-covered to VERIFIED (Rule 18 real-source injection). */
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
__attribute__((always_inline)) static inline double olm_fabs(double x){ uint64_t b; __builtin_memcpy(&b,&x,8); b&=0x7fffffffffffffffULL; __builtin_memcpy(&x,&b,8); return x; }
__attribute__((always_inline)) static inline float  olm_fabsf(float x){ uint32_t b; __builtin_memcpy(&b,&x,4); b&=0x7fffffffU; __builtin_memcpy(&x,&b,4); return x; }
__attribute__((always_inline)) static inline double olm_copysign(double x,double y){ uint64_t bx,by; __builtin_memcpy(&bx,&x,8); __builtin_memcpy(&by,&y,8); bx=(bx&0x7fffffffffffffffULL)|(by&0x8000000000000000ULL); __builtin_memcpy(&x,&bx,8); return x; }
__attribute__((always_inline)) static inline float  olm_copysignf(float x,float y){ uint32_t bx,by; __builtin_memcpy(&bx,&x,4); __builtin_memcpy(&by,&y,4); bx=(bx&0x7fffffffU)|(by&0x80000000U); __builtin_memcpy(&x,&bx,4); return x; }

/* ---- shared file-scope constants (uniquified across concatenated corpus) ---- */
static const double one = 1.0;
static const double huge = 1.0e+300;
static const double tiny = 1.0e-300;

/* s_expm1.c constants (em1_-prefixed to avoid collision with e_exp.c) */
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

/* e_exp.c constants */
static const double
halF[2] = {0.5, -0.5,},
o_threshold =  7.09782712893383973096e+02,  /* 0x40862E42, 0xFEFA39EF */
u_threshold = -7.45133219101941108420e+02,  /* 0xc0874910, 0xD52D3051 */
ln2HI[2] = { 6.93147180369123816490e-01,    /* 0x3fe62e42, 0xfee00000 */
            -6.93147180369123816490e-01,},  /* 0xbfe62e42, 0xfee00000 */
ln2LO[2] = { 1.90821492927058770002e-10,    /* 0x3dea39ef, 0x35793c76 */
            -1.90821492927058770002e-10,},  /* 0xbdea39ef, 0x35793c76 */
invln2 = 1.44269504088896338700e+00,        /* 0x3ff71547, 0x652b82fe */
P1 =  1.66666666666666019037e-01,  /* 0x3FC55555, 0x5555553E */
P2 = -2.77777777770155933842e-03,  /* 0xBF66C16C, 0x16BEBD93 */
P3 =  6.61375632143793436117e-05,  /* 0x3F11566A, 0xAF25DE2C */
P4 = -1.65339022054652515390e-06,  /* 0xBEBBBD41, 0xC5D26BF1 */
P5 =  4.13813679705723846039e-08;  /* 0x3E663769, 0x72BEA4D0 */

static volatile double
twom1000 = 9.33263618503218878990e-302;     /* 2**-1000=0x01700000,0*/

/* k_exp.c constants (file-scope `k` renamed kexp_k to avoid local-`k` shadow) */
static const uint32_t kexp_k = 1799;              /* constant for reduction */
static const double kln2 = 1246.97177782734161156; /* k * ln2 */

/* e_sinh.c constant */
static const double shuge = 1.0e307;

/* ---- olm_expm1 : VERBATIM from verified slice_libm_real_tanh.c ---- */
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

/* ---- olm_exp : VERBATIM from verified slice_libm_real_exp.c ---- */
__attribute__((always_inline)) static inline double olm_exp(double x) {
    double y, hi = 0.0, lo = 0.0, c, t, twopk;
    int32_t k = 0, xsb;
    uint32_t hx;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* GET_HIGH_WORD */
    hx = (uint32_t)(bits >> 32);
    xsb = (hx >> 31) & 1;       /* sign bit of x */
    hx &= 0x7fffffff;           /* high word of |x| */

    /* filter out non-finite argument */
    if (hx >= 0x40862E42) {                 /* if |x|>=709.78... */
        if (hx >= 0x7ff00000) {
            uint32_t lx;
            __builtin_memcpy(&bits, &x, 8);              /* GET_LOW_WORD */
            lx = (uint32_t)bits;
            if (((hx & 0xfffff) | lx) != 0)
                return x + x;               /* NaN */
            else return (xsb == 0) ? x : 0.0;  /* exp(+-inf)={inf,0} */
        }
        if (x > o_threshold) return huge * huge;             /* overflow */
        if (x < u_threshold) return twom1000 * twom1000;     /* underflow */
    }

    /* this implementation gives 2.7182818284590455 for exp(1.0),
       which is well within the allowable error. */
    if (x == 1.0)
        return 2.718281828459045235360;

    /* argument reduction */
    if (hx > 0x3fd62e42) {                  /* if  |x| > 0.5 ln2 */
        if (hx < 0x3FF0A2B2) {              /* and |x| < 1.5 ln2 */
            hi = x - ln2HI[xsb]; lo = ln2LO[xsb]; k = 1 - xsb - xsb;
        } else {
            k  = (int)(invln2 * x + halF[xsb]);
            t  = k;
            hi = x - t * ln2HI[0];          /* t*ln2HI is exact here */
            lo = t * ln2LO[0];
        }
        x = hi - lo;                        /* STRICT_ASSIGN */
    }
    else if (hx < 0x3e300000) {             /* when |x|<2**-28 */
        if (huge + x > one) return one + x; /* trigger inexact */
    }
    else k = 0;

    /* x is now in primary range */
    t = x * x;
    if (k >= -1021) {
        bits = (uint64_t)(uint32_t)(0x3ff00000 + (k << 20)) << 32;
        __builtin_memcpy(&twopk, &bits, 8);              /* INSERT_WORDS */
    } else {
        bits = (uint64_t)(uint32_t)(0x3ff00000 + ((k + 1000) << 20)) << 32;
        __builtin_memcpy(&twopk, &bits, 8);              /* INSERT_WORDS */
    }
    c = x - t * (P1 + t * (P2 + t * (P3 + t * (P4 + t * P5))));
    if (k == 0)  return one - ((x * c) / (c - 2.0) - x);
    else         y = one - ((lo - (x * c) / (2.0 - c)) - hi);
    if (k >= -1021) {
        if (k == 1024) return y * 2.0 * 0x1p1023;
        return y * twopk;
    } else {
        return y * twopk * twom1000;        /* subnormal result */
    }
}

/* ---- olm_frexp_exp / olm_ldexp_exp : vendored from k_exp.c ---- */
__attribute__((always_inline)) static inline double olm_frexp_exp(double x, int *expt) {
    double exp_x;
    uint32_t hx;

    /*
     * We use exp(x) = exp(x - kln2) * 2**k, carefully chosen to
     * minimize |exp(kln2) - 2**k|.
     */
    exp_x = olm_exp(x - kln2);
    GET_HIGH_WORD(hx, exp_x);
    *expt = (hx >> 20) - (0x3ff + 1023) + kexp_k;
    SET_HIGH_WORD(exp_x, (hx & 0xfffff) | ((0x3ff + 1023) << 20));
    return (exp_x);
}

__attribute__((always_inline)) static inline double olm_ldexp_exp(double x, int expt) {
    double exp_x, scale;
    int ex_expt;

    exp_x = olm_frexp_exp(x, &ex_expt);
    expt += ex_expt;
    INSERT_WORDS(scale, (0x3ff + expt) << 20, 0);
    return (exp_x * scale);
}

/* ---- olm_sinh : entry, from e_sinh.c ---- */
__attribute__((always_inline)) static inline double olm_sinh(double x) {
    double t, h;
    int32_t ix, jx;

    /* High word of |x|. */
    GET_HIGH_WORD(jx, x);
    ix = jx & 0x7fffffff;

    /* x is INF or NaN */
    if (ix >= 0x7ff00000) return x + x;

    h = 0.5;
    if (jx < 0) h = -h;
    /* |x| in [0,22], return sign(x)*0.5*(E+E/(E+1))) */
    if (ix < 0x40360000) {              /* |x|<22 */
        if (ix < 0x3e300000)            /* |x|<2**-28 */
            if (shuge + x > one) return x; /* sinh(tiny) = tiny with inexact */
        t = olm_expm1(olm_fabs(x));
        if (ix < 0x3ff00000) return h * (2.0 * t - t * t / (t + one));
        return h * (t + t / (t + one));
    }

    /* |x| in [22, log(maxdouble)] return 0.5*exp(|x|) */
    if (ix < 0x40862E42)  return h * olm_exp(olm_fabs(x));

    /* |x| in [log(maxdouble), overflowthresold] */
    if (ix <= 0x408633CE)
        return h * 2.0 * olm_ldexp_exp(olm_fabs(x), -1);

    /* |x| > overflowthresold, sinh(x) overflow */
    return x * shuge;
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_sinh(q));
}
int main(void) { (void) slice(); return 0; }
