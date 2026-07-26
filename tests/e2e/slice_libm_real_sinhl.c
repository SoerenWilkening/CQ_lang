/* slice_libm_real_sinhl.c — bd 3c6m.58: the REAL openlibm sinhl body
   (ld80/e_sinhl.c, fdlibm/OpenBSD-derived, BSD-licensed) over its full ld80
   closure — BOTH inner kernels, expm1l (ld80/s_expm1l.c) for the small-|x|
   band and expl (ld80/e_expl.c) for the two large-|x| bands, plus expl's own
   SOFTWARE closure (__isnanl, __polevll, ldexpl==scalbnl) — over x86_fp80
   `long double`. Census cell sinhl.f80.

   This is the one cell in the bd 3c6m.58 sweep whose census status is
   `exit0-spec:['expl']` rather than plain COMPILES: under the census harness
   the inner expl stays OUTLINED and lowers as a Phase-6 specialization clone
   (@__cq_q_expl_1). At the plain -O1 ship floor this slice instead follows the
   recipe's force-inline convention (lesson 1: mark EVERY vendored helper
   always_inline static inline, reproducing the census inline-threshold-2M shape
   at -O1), so the whole closure collapses to one straight-line body and no
   spec clone is minted. Both routes reach opt exit 0; this golden pins the
   ship-floor one.

   sinhl dispatches on |x| across five exits — inf/NaN, |x|<25 (via
   `t = expm1l(|x|)`, itself split at |x|<1 into `h*(2t - t*t/(t+1))` vs
   `h*(t + t/(t+1))`), |x| in [25, log(maxdouble)) (via `h*expl(|x|)`), and the
   near-overflow band (via `w = expl(0.5|x|); t = h*w; return t*w` — the
   squaring trick that avoids overflowing the single exp), and finally the
   overflow tail above that threshold (`return x*sh_shuge`) — with the sign
   folded into `h = ±0.5` up front. (There is also an inner early return inside
   the |x|<25 band: `if(ix<0x3fdf) if(shuge+x>one) return x` — sinh(tiny) = tiny
   with inexact.) Every band boundary is a tainted compare on
   the extracted exponent/mantissa words, so the body is a multi-band value-region
   chain PredMux flattens onto the select substrate, with the fp80 selects
   carried by the kjd1 cqrt_copy_f80_controlled family.

   KEEP-SET CALLS (bd tkju — Rule 18 ship-floor fold, NOT a body substitution):
   fabsl (sinhl's |x| sites), floorl (expl's and expm1l's Cody-Waite round) and
   copysignl/copysign (scalbnl's overflow/underflow arms) are HARDWARE KEEPS. At
   this slice's real ship floor — plain `clang -O1`, builtins ON, no
   -fno-builtin — they fold to @llvm.{fabs,floor,copysign} before codegen, so a
   keep has NO injectable body and vendoring openlibm's software s_copysign{,l}.c
   here MISREPRESENTED the compiled program. They are spelled __builtin_<fn>: no
   math.h is included, and the builtin spelling names the intrinsic without a
   libm declaration. Measured — stage 1 hands the pass 3 @llvm.fabs.f80,
   3 @llvm.floor.f80, 4 @llvm.copysign.f80, 4 @llvm.copysign.f64 and
   23 @llvm.fmuladd.f80 CALL SITES (call sites, not `declare` lines), and every
   one lowers to its cq_template_<fn>_<W>. The
   trace is a dynamic gate log, so it carries 3 fabs_f80 / 3 floor_f80 /
   4 copysign_f80_lh / 4 copysign_f64_lh forward lines. Dropping the two
   vendored copysign bodies took the trace from 2741 to 2703 lines: the f64 shim's bitcast_f64_to_i64/bitcast_i64_to_f64
   pairs vanish outright and the ld80 body's sign-field word traffic drops
   (lshr_i80_hl 24->20, or_i80_hl 6->2, and_i64_hl 24->18), so this slice no
   longer covers the word-level copysign shape — only the keep route.

   This slice is the LINK-layer proof (Rule 2) that every emitted i80/f80
   symbol resolves and the trace is stable+deterministic. The probe pins the
   census cell sinhl.f80: x = theta-tainted.

   Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
   changed): includes, license and OLM_ macros deleted; every vendored function
   marked `__attribute__((always_inline)) static inline` with its
   public/`__`-prefixed entry renamed `olm_<name>`; intra-body calls renamed to
   their olm_ vendored names (expm1l→olm_expm1l, expl→olm_expl, ldexpl→
   olm_scalbnl per openlibm_strong_reference(scalbnl,ldexpl)); the keep calls
   fabsl/floorl/copysignl/copysign written __builtin_<fn> (see KEEP-SET above —
   bd tkju); e_sinhl.c's file-scope `one`/`shuge` uniquified
   `sh_one`/`sh_shuge`, and s_expm1l.c's
   `huge`/`MAXLOGL` uniquified `em1_huge`/`em1_MAXLOGL` against s_scalbnl.c's
   `huge` and e_expl.c's `MAXLOGL` (identical value); s_expm1l.c's
   C1/C2 prefixed `eC1`/`eC2` against e_expl.c's scalar C1/C2 (its P0-P4/Q0-Q4
   carry the same prefix for consistency but do NOT collide — e_expl.c declares
   the ARRAYS P[3]/Q[4]; the real collisions are exactly C1, C2 and MAXLOGL).
   The shared ld80 closure below (ieee_extended_shape_type +
   GET/SET_LDOUBLE_WORDS, union IEEEl2bits, olm_isnanl, olm_polevll,
   olm_scalbnl, olm_expl) is vendored BYTE-IDENTICALLY from the already-verified
   slice_libm_real_erfl.c (lines 60-229, `#include <stdint.h>` through the close
   of olm_expl — the copysign pair that used to sit inside that span is gone,
   tkju), and olm_expm1l BYTE-IDENTICALLY from the sibling
   slice_libm_real_expm1l.c — the recipe's
   "inner body identical to its own standalone verified slice" pattern (bd
   atan2l-verified-corpus-reclone). Both fp80 unions are kept VERBATIM — the
   promoteFp80Union pass owns them, never a memcpy word shim (3c6m.51 ld80
   convention). */
#include <stdint.h>

typedef unsigned int u_int32_t;

/* src/math_private_openbsd.h — the LP64 little-endian ld80 word union +
   GET/SET_LDOUBLE_WORDS (verbatim; x86-64 is always little-endian). */
typedef union
{
  long double value;
  struct {
    u_int32_t lsw;
    u_int32_t msw;
    int exp:16;
    int padl:16;
    int padh:32;
  } parts;
} ieee_extended_shape_type;

#define GET_LDOUBLE_WORDS(se,ix0,ix1,d)				\
do {								\
  ieee_extended_shape_type ew_u;				\
  ew_u.value = (d);						\
  (se) = ew_u.parts.exp;					\
  (ix0) = ew_u.parts.msw;					\
  (ix1) = ew_u.parts.lsw;					\
} while (0)

#define SET_LDOUBLE_WORDS(d,se,ix0,ix1)				\
do {								\
  ieee_extended_shape_type iw_u;				\
  iw_u.parts.exp = (se);					\
  iw_u.parts.msw = (ix0);					\
  iw_u.parts.lsw = (ix1);					\
  (d) = iw_u.value;						\
} while (0)

/* src/amd64_fpmath.h — union IEEEl2bits + LDBL_NBIT + mask_nbit_l (verbatim —
   BOTH views; used by olm_isnanl and olm_scalbnl via .bits/.e). */
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
#define LDBL_NBIT       0x80000000
#define mask_nbit_l(u)  ((u).bits.manh &= ~LDBL_NBIT)

/* src/s_isnan.c __isnanl (verbatim). */
__attribute__((always_inline)) static inline int
olm_isnanl(long double e)
{
    union IEEEl2bits u;
    u.e = e;
    mask_nbit_l(u);
    return (u.bits.exp == 32767 && (u.bits.manl != 0 || u.bits.manh != 0));
}

/* src/polevll.c __polevll (verbatim). */
__attribute__((always_inline)) static inline long double
olm_polevll(long double x, void *PP, int n)
{
    long double y;
    long double *P;

    P = (long double *)PP;
    y = *P++;
    do {
        y = y * x + *P++;
    } while (--n);

    return (y);
}
/* src/s_scalbnl.c scalbnl (verbatim; colliding tiny/huge uniquified scb_*).
   openlibm_strong_reference(scalbnl, ldexpl): ldexpl IS this body. */
static const long double
scb_huge = 0x1p16000L,
scb_tiny = 0x1p-16000L;

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
        if (n< -50000) return scb_tiny*x;       /*underflow*/
    }
    if (k==0x7fff) return x+x;                  /* NaN or Inf */
    k = k+n;
    if (k >= 0x7fff) return scb_huge*__builtin_copysignl(scb_huge,x); /* overflow  */
    if (k > 0)                                  /* normal result */
        {u.bits.exp = k; return u.e;}
    if (k <= -128) {
        if (n > 50000)                          /* in case integer overflow in n+k */
            return scb_huge*__builtin_copysign(scb_huge,x);   /*overflow*/
        else return scb_tiny*__builtin_copysign(scb_tiny,x);  /*underflow*/
    }
    k += 128;                                   /* subnormal result */
    u.bits.exp = k;
    return u.e*0x1p-128;
}

/* ld80/e_expl.c expl (verbatim; floorl→__builtin_floorl, ldexpl→olm_scalbnl,
   isnan→olm_isnanl, __polevll→olm_polevll, INFINITY→__builtin_infl()). */
static long double P[3] = {
 1.2617719307481059087798E-4L,
 3.0299440770744196129956E-2L,
 9.9999999999999999991025E-1L,
};
static long double Q[4] = {
 3.0019850513866445504159E-6L,
 2.5244834034968410419224E-3L,
 2.2726554820815502876593E-1L,
 2.0000000000000000000897E0L,
};
static const long double C1 = 6.9314575195312500000000E-1L;
static const long double C2 = 1.4286068203094172321215E-6L;
static const long double MAXLOGL = 1.1356523406294143949492E4L;
static const long double MINLOGL = -1.13994985314888605586758E4L;
static const long double LOG2EL = 1.4426950408889634073599E0L;

__attribute__((always_inline)) static inline long double
olm_expl(long double x)
{
long double px, xx;
int n;

if( olm_isnanl(x) )
	return(x);
if( x > MAXLOGL)
	return( __builtin_infl() );

if( x < MINLOGL )
	return(0.0L);

/* Express e**x = e**g 2**n
 *   = e**g e**( n loge(2) )
 *   = e**( g + n loge(2) )
 */
px = __builtin_floorl( LOG2EL * x + 0.5L ); /* floor() truncates toward -infinity. */
n = px;
x -= px * C1;
x -= px * C2;


/* rational approximation for exponential
 * of the fractional part:
 * e**x =  1 + 2x P(x**2)/( Q(x**2) - P(x**2) )
 */
xx = x * x;
px = x * olm_polevll( xx, P, 2 );
x =  px/( olm_polevll( xx, Q, 3 ) - px );
x = 1.0L + olm_scalbnl( x, 1 );

x = olm_scalbnl( x, n );
return(x);
}

/* ld80/s_expm1l.c (verbatim; floorl→__builtin_floorl, ldexpl→olm_scalbnl,
   file-scope `huge` uniquified `em1_huge`). */
static const long double em1_MAXLOGL = 1.1356523406294143949492E4L;

/* exp(x) - 1 = x + 0.5 x^2 + x^3 P(x)/Q(x)
   -.5 ln 2  <  x  <  .5 ln 2
   Theoretical peak relative error = 3.4e-22  */

static const long double
  eP0 = -1.586135578666346600772998894928250240826E4L,
  eP1 =  2.642771505685952966904660652518429479531E3L,
  eP2 = -3.423199068835684263987132888286791620673E2L,
  eP3 =  1.800826371455042224581246202420972737840E1L,
  eP4 = -5.238523121205561042771939008061958820811E-1L,

  eQ0 = -9.516813471998079611319047060563358064497E4L,
  eQ1 =  3.964866271411091674556850458227710004570E4L,
  eQ2 = -7.207678383830091850230366618190187434796E3L,
  eQ3 =  7.206038318724600171970199625081491823079E2L,
  eQ4 = -4.002027679107076077238836622982900945173E1L,
  /* Q5 = 1.000000000000000000000000000000000000000E0 */

/* C1 + C2 = ln 2 */
eC1 = 6.93145751953125E-1L,
eC2 = 1.428606820309417232121458176568075500134E-6L,
/* ln 2^-65 */
minarg = -4.5054566736396445112120088E1L;
static const long double em1_huge = 0x1p10000L;

__attribute__((always_inline)) static inline long double
olm_expm1l(long double x)
{
long double px, qx, xx;
int k;

/* Overflow.  */
if (x > em1_MAXLOGL)
  return (em1_huge*em1_huge);	/* overflow */

if (x == 0.0)
  return x;

/* Minimum value.  */
if (x < minarg)
  return -1.0L;

xx = eC1 + eC2;

/* Express x = ln 2 (k + remainder), remainder not exceeding 1/2. */
px = __builtin_floorl (0.5 + x / xx);
k = px;
/* remainder times ln 2 */
x -= px * eC1;
x -= px * eC2;

/* Approximate exp(remainder ln 2).  */
px = (((( eP4 * x
	 + eP3) * x
	+ eP2) * x
       + eP1) * x
      + eP0) * x;

qx = (((( x
	 + eQ4) * x
	+ eQ3) * x
       + eQ2) * x
      + eQ1) * x
     + eQ0;

xx = x * x;
qx = x + (0.5 * xx + xx * px / qx);

/* exp(x) = exp(k ln 2) exp(remainder ln 2) = 2^k exp(remainder ln 2).
   We have qx = exp(remainder ln 2) - 1, so
   exp(x) - 1  =  2^k (qx + 1) - 1  =  2^k qx + 2^k - 1.  */
px = olm_scalbnl(1.0L, k);
x = px * qx + (px - 1.0);
return x;
}


/* ld80/e_sinhl.c (verbatim; expm1l→olm_expm1l, expl→olm_expl,
   fabsl→__builtin_fabsl, file-scope `one`/`shuge` uniquified
   `sh_one`/`sh_shuge`). */
static const long double sh_one = 1.0, sh_shuge = 1.0e4931L;

__attribute__((always_inline)) static inline long double
olm_sinhl(long double x)
{
	long double t,w,h;
	u_int32_t jx,ix,i0,i1;

    /* Words of |x|. */
	GET_LDOUBLE_WORDS(jx,i0,i1,x);
	ix = jx&0x7fff;

    /* x is INF or NaN */
	if(ix==0x7fff) return x+x;

	h = 0.5;
	if (jx & 0x8000) h = -h;
    /* |x| in [0,25], return sign(x)*0.5*(E+E/(E+1))) */
	if (ix < 0x4003 || (ix == 0x4003 && i0 <= 0xc8000000)) { /* |x|<25 */
	    if (ix<0x3fdf)		 /* |x|<2**-32 */
		if(sh_shuge+x>sh_one) return x;/* sinh(tiny) = tiny with inexact */
	    t = olm_expm1l(__builtin_fabsl(x));
	    if(ix<0x3fff) return h*(2.0*t-t*t/(t+sh_one));
	    return h*(t+t/(t+sh_one));
	}

    /* |x| in [25, log(maxdouble)] return 0.5*exp(|x|) */
	if (ix < 0x400c || (ix == 0x400c && i0 < 0xb17217f7))
		return h*olm_expl(__builtin_fabsl(x));

    /* |x| in [log(maxdouble), overflowthreshold] */
	if (ix<0x400c || (ix == 0x400c && (i0 < 0xb174ddc0
					   || (i0 == 0xb174ddc0
					       && i1 <= 0x31aec0ea)))) {
	    w = olm_expl(0.5*__builtin_fabsl(x));
	    t = h*w;
	    return t*w;
	}

    /* |x| > overflowthreshold, sinhl(x) overflow */
	return x*sh_shuge;
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_sinhl(q));
}
int main(void) { (void) slice(); return 0; }
