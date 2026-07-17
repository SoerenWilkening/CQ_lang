/* slice_libm_real_coshl.c — bd 3c6m.55 Inc 3 (adia, Lever C): the REAL openlibm
   coshl body (ld80/e_coshl.c + its full dependency closure: ld80/e_expl.c,
   ld80/s_expm1l.c, ld80/s_floorl.c, src/polevll.c __polevll, src/s_isnan.c
   __isnanl, s_scalbnl.c scalbnl as the ldexpl alias, fdlibm/Cephes-derived,
   BSD-licensed) over x86_fp80 `long double` — the FIRST ld80 TRANSCENDENTAL
   slice, and the Lever-A+B+C composition proof:

     * Lever A (hder): every IEEEl2bits / ieee_extended_shape_type union
       (coshl's GET_LDOUBLE_WORDS, floorl's GET/SET pack, isnanl's mask_nbit_l
       view) promotes to i80 register form — fmuladd/const-global/reload-web
       seeds + the integer-seeded SET_LDBL reconstruct pack.
     * Lever B (lf8s): the __polevll Horner loops (trip 2 and 3, kept rolled at
       -O1) force-unroll to the straight-line fmuladd chain.
     * Lever C (adia): the residual is control — coshl's exponent range ladder
       (select-form short-circuit `&&` conditions), floorl's Q+Q data compares
       (two theta-derived words), the fp80 data selects, and the outlined
       `expl` callee under tainted control (PredMux speculates the proven-pure
       acyclic body, Phase-6 clones it with the fp80-ABI copy-out, and
       lowerCloneControl flattens its internal 30+-branch web).

   This slice is the LINK-layer proof (Rule 2) that every emitted symbol —
   cqrt_copy_f80_controlled, the QQ icmp/fcmp flag mints, the i80 extract/pack
   family, the clone @__cq_q_* + its _unc twin — resolves and the trace is
   stable. The probe pins the census cell coshl.f80: x = theta-tainted.

   Mechanical edits ONLY (libm-real-slice-recipe): includes/license deleted,
   entries renamed olm_*, colliding file-scope statics uniquified per body
   (huge_*, C1/C2_*, MAXLOGL_*), intra-body calls retargeted to the olm_
   names, u_int32_t mapped to stdint. No constant/branch/expression changed. */
#include <stdint.h>

typedef uint32_t u_int32_t;

/* openlibm src/amd64_fpmath.h (verbatim — BOTH views; the fp80 pass owns the
   union, never memcpy-shim ld80 word access). */
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
    struct {
        unsigned long man     : 64;
        unsigned int  expsign : 16;
        unsigned long junk    : 48;
    } xbits;
};
#define LDBL_NBIT 0x80000000
#define mask_nbit_l(u) ((u).bits.manh &= ~LDBL_NBIT)

/* openlibm src/math_private_openbsd.h ieee_extended_shape_type + the
   GET/SET_LDOUBLE_WORDS macros (verbatim; __LP64__ on this target). */
typedef union {
    long double value;
    struct {
        u_int32_t lsw;
        u_int32_t msw;
        int exp : 16;
        int padl : 16;
        int padh : 32;
    } parts;
} ieee_extended_shape_type;

#define GET_LDOUBLE_WORDS(se, ix0, ix1, d) \
    do {                                   \
        ieee_extended_shape_type ew_u;     \
        ew_u.value = (d);                  \
        (se) = ew_u.parts.exp;             \
        (ix0) = ew_u.parts.msw;            \
        (ix1) = ew_u.parts.lsw;            \
    } while (0)

#define SET_LDOUBLE_WORDS(d, se, ix0, ix1) \
    do {                                   \
        ieee_extended_shape_type iw_u;     \
        iw_u.parts.exp = (se);             \
        iw_u.parts.msw = (ix0);            \
        iw_u.parts.lsw = (ix1);            \
        (d) = iw_u.value;                  \
    } while (0)

/* openlibm src/s_isnan.c __isnanl (verbatim). */
static int olm_isnanl(long double e) {
    union IEEEl2bits u;

    u.e = e;
    mask_nbit_l(u);
    return (u.bits.exp == 32767 && (u.bits.manl != 0 || u.bits.manh != 0));
}

/* openlibm src/polevll.c __polevll (verbatim). */
static long double olm_polevll(long double x, void *PP, int n) {
    long double y;
    long double *P;

    P = (long double *)PP;
    y = *P++;
    do {
        y = y * x + *P++;
    } while (--n);

    return (y);
}

/* openlibm s_copysignl.c copysignl (verbatim — from the verified
   slice_libm_real_scalbnl.c). */
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
   slice_libm_real_scalbn.c olm_copysign; f64 words keep the memcpy shim). */
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
huge_scalbnl = 0x1p16000L,
tiny_scalbnl = 0x1p-16000L;

/* openlibm s_scalbnl.c scalbnl (verbatim — from the verified
   slice_libm_real_scalbnl.c; ldexpl is its alias, forwarded below). */
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
        if (n< -50000) return tiny_scalbnl*x;   /*underflow*/
    }
    if (k==0x7fff) return x+x;                  /* NaN or Inf */
    k = k+n;
    if (k >= 0x7fff) return huge_scalbnl*olm_copysignl(huge_scalbnl,x); /* overflow  */
    if (k > 0)                                  /* normal result */
        {u.bits.exp = k; return u.e;}
    if (k <= -128) {
        if (n > 50000)                          /* in case integer overflow in n+k */
            return huge_scalbnl*olm_copysign(huge_scalbnl,x);   /*overflow*/
        else return tiny_scalbnl*olm_copysign(tiny_scalbnl,x);  /*underflow*/
    }
    k += 128;                                   /* subnormal result */
    u.bits.exp = k;
    return u.e*0x1p-128;
}

/* openlibm s_ldexpl.c: ldexpl is scalbnl (the alias forward). */
__attribute__((always_inline)) static inline long double
olm_ldexpl(long double x, int n) {
    return olm_scalbnl(x, n);
}

static const long double huge_floorl = 1.0e4930L;

/* openlibm ld80/s_floorl.c floorl (verbatim). */
static long double olm_floorl(long double x) {
    int32_t i1,jj0;
    u_int32_t i,j,se,i0,sx;
    GET_LDOUBLE_WORDS(se,i0,i1,x);
    sx = (se>>15)&1;
    jj0 = (se&0x7fff)-0x3fff;
    if(jj0<31) {
        if(jj0<0) {	/* raise inexact if x != 0 */
        if(huge_floorl+x>0.0) {
            if(sx==0)
            return 0.0L;
            else if(((se&0x7fff)|i0|i1)!=0)
            return -1.0L;
        }
        } else {
        i = (0x7fffffff)>>jj0;
        if(((i0&i)|i1)==0) return x; /* x is integral */
        if(huge_floorl+x>0.0) {	/* raise inexact flag */
            if(sx) {
            if (jj0>0 && (i0+(0x80000000>>jj0))>i0)
              i0 += (0x80000000)>>jj0;
            else
              {
                i = 0x7fffffff;
                ++se;
              }
            }
            i0 &= (~i); i1=0;
        }
        }
    } else if (jj0>62) {
        if(jj0==0x4000) return x+x;	/* inf or NaN */
        else return x;		/* x is integral */
    } else {
        i = ((u_int32_t)(0xffffffff))>>(jj0-31);
        if((i1&i)==0) return x;	/* x is integral */
        if(huge_floorl+x>0.0) {		/* raise inexact flag */
        if(sx) {
            if(jj0==31) i0+=1;
            else {
            j = i1+(1<<(63-jj0));
            if(j<i1) i0 +=1 ;	/* got a carry */
            i1=j;
            }
        }
        i1 &= (~i);
        }
    }
    SET_LDOUBLE_WORDS(x,se,i0,i1);
    return x;
}

/* openlibm ld80/e_expl.c expl (verbatim; Cephes). INFINITY is float +inf
   promoted to long double — written __builtin_infl(), the identical value. */
static long double P_expl[3] = {
 1.2617719307481059087798E-4L,
 3.0299440770744196129956E-2L,
 9.9999999999999999991025E-1L,
};
static long double Q_expl[4] = {
 3.0019850513866445504159E-6L,
 2.5244834034968410419224E-3L,
 2.2726554820815502876593E-1L,
 2.0000000000000000000897E0L,
};
static const long double C1_expl = 6.9314575195312500000000E-1L;
static const long double C2_expl = 1.4286068203094172321215E-6L;
static const long double MAXLOGL_expl = 1.1356523406294143949492E4L;
static const long double MINLOGL_expl = -1.13994985314888605586758E4L;
static const long double LOG2EL_expl = 1.4426950408889634073599E0L;

static long double olm_expl(long double x) {
long double px, xx;
int n;

if( olm_isnanl(x) )
	return(x);
if( x > MAXLOGL_expl)
	return( __builtin_infl() );

if( x < MINLOGL_expl )
	return(0.0L);

/* Express e**x = e**g 2**n
 *   = e**g e**( n loge(2) )
 *   = e**( g + n loge(2) )
 */
px = olm_floorl( LOG2EL_expl * x + 0.5L ); /* floor() truncates toward -infinity. */
n = px;
x -= px * C1_expl;
x -= px * C2_expl;


/* rational approximation for exponential
 * of the fractional part:
 * e**x =  1 + 2x P(x**2)/( Q(x**2) - P(x**2) )
 */
xx = x * x;
px = x * olm_polevll( xx, P_expl, 2 );
x =  px/( olm_polevll( xx, Q_expl, 3 ) - px );
x = 1.0L + olm_ldexpl( x, 1 );

x = olm_ldexpl( x, n );
return(x);
}

/* openlibm ld80/s_expm1l.c expm1l (verbatim; Cephes). */
static const long double MAXLOGL_expm1l = 1.1356523406294143949492E4L;

static const long double
  P0_expm1l = -1.586135578666346600772998894928250240826E4L,
  P1_expm1l =  2.642771505685952966904660652518429479531E3L,
  P2_expm1l = -3.423199068835684263987132888286791620673E2L,
  P3_expm1l =  1.800826371455042224581246202420972737840E1L,
  P4_expm1l = -5.238523121205561042771939008061958820811E-1L,

  Q0_expm1l = -9.516813471998079611319047060563358064497E4L,
  Q1_expm1l =  3.964866271411091674556850458227710004570E4L,
  Q2_expm1l = -7.207678383830091850230366618190187434796E3L,
  Q3_expm1l =  7.206038318724600171970199625081491823079E2L,
  Q4_expm1l = -4.002027679107076077238836622982900945173E1L,
  /* Q5 = 1.000000000000000000000000000000000000000E0 */

/* C1 + C2 = ln 2 */
C1_expm1l = 6.93145751953125E-1L,
C2_expm1l = 1.428606820309417232121458176568075500134E-6L,
/* ln 2^-65 */
minarg_expm1l = -4.5054566736396445112120088E1L;
static const long double huge_expm1l = 0x1p10000L;

static long double olm_expm1l(long double x) {
long double px, qx, xx;
int k;

/* Overflow.  */
if (x > MAXLOGL_expm1l)
  return (huge_expm1l*huge_expm1l);	/* overflow */

if (x == 0.0)
  return x;

/* Minimum value.  */
if (x < minarg_expm1l)
  return -1.0L;

xx = C1_expm1l + C2_expm1l;

/* Express x = ln 2 (k + remainder), remainder not exceeding 1/2. */
px = olm_floorl (0.5 + x / xx);
k = px;
/* remainder times ln 2 */
x -= px * C1_expm1l;
x -= px * C2_expm1l;

/* Approximate exp(remainder ln 2).  */
px = (((( P4_expm1l * x
	 + P3_expm1l) * x
	+ P2_expm1l) * x
       + P1_expm1l) * x
      + P0_expm1l) * x;

qx = (((( x
	 + Q4_expm1l) * x
	+ Q3_expm1l) * x
       + Q2_expm1l) * x
      + Q1_expm1l) * x
     + Q0_expm1l;

xx = x * x;
qx = x + (0.5 * xx + xx * px / qx);

/* exp(x) = exp(k ln 2) exp(remainder ln 2) = 2^k exp(remainder ln 2).
   We have qx = exp(remainder ln 2) - 1, so
   exp(x) - 1  =  2^k (qx + 1) - 1  =  2^k qx + 2^k - 1.  */
px = olm_ldexpl(1.0L, k);
x = px * qx + (px - 1.0);
return x;
}

/* openlibm ld80/e_coshl.c coshl (verbatim; fdlibm). */
static const long double one_coshl = 1.0, half_coshl = 0.5, huge_coshl = 1.0e4900L;

static long double olm_coshl(long double x) {
    long double t,w;
    int32_t ex;
    u_int32_t mx,lx;

    /* High word of |x|. */
    GET_LDOUBLE_WORDS(ex,mx,lx,x);
    ex &= 0x7fff;

    /* x is INF or NaN */
    if(ex==0x7fff) return x*x;

    /* |x| in [0,0.5*ln2], return 1+expm1l(|x|)^2/(2*expl(|x|)) */
    if(ex < 0x3ffd || (ex == 0x3ffd && mx < 0xb17217f7u)) {
        t = olm_expm1l(__builtin_fabsl(x));
        w = one_coshl+t;
        if (ex<0x3fbc) return w;	/* cosh(tiny) = 1 */
        return one_coshl+(t*t)/(w+w);
    }

    /* |x| in [0.5*ln2,22], return (exp(|x|)+1/exp(|x|)/2; */
    if (ex < 0x4003 || (ex == 0x4003 && mx < 0xb0000000u)) {
        t = olm_expl(__builtin_fabsl(x));
        return half_coshl*t+half_coshl/t;
    }

    /* |x| in [22, ln(maxdouble)] return half*exp(|x|) */
    if (ex < 0x400c || (ex == 0x400c && mx < 0xb1700000u))
        return half_coshl*olm_expl(__builtin_fabsl(x));

    /* |x| in [log(maxdouble), log(2*maxdouble)) */
    if (ex == 0x400c && (mx < 0xb174ddc0u
                 || (mx == 0xb174ddc0u && lx < 0x31aec0ebu)))
    {
        w = olm_expl(half_coshl*__builtin_fabsl(x));
        t = half_coshl*w;
        return t*w;
    }

    /* |x| >= log(2*maxdouble), cosh(x) overflow */
    return huge_coshl*huge_coshl;
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_coshl(q));
}

int main(void) {
    (void) slice();
    return 0;
}
