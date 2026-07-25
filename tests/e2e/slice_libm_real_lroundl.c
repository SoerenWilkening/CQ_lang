/* slice_libm_real_lroundl.c — bd 3c6m.58: the REAL openlibm lroundl body
   (src/s_lroundl.c → the src/s_lround.c template instantiated at
   type=long double / dtype=long / roundit=roundl → src/s_roundl.c →
   src/s_isfinite.c __isfinitel + ld80/s_floorl.c, fdlibm/FreeBSD-derived,
   BSD-licensed) over x86_fp80 `long double`.

   INRANGE() folds to a compile-time TRUE exactly as in the verified lround.f64
   sibling, and for the same reason: `dtype_max = DTYPE_MAX + 0.5` applies the
   USUAL ARITHMETIC CONVERSIONS to `LONG_MAX + 0.5` — long and double, so the
   sum is computed in DOUBLE and rounds to 2^63 before being widened to the
   `static const long double`. `dtype_max - DTYPE_MAX` then widens LONG_MAX
   (2^63-1, exact in fp80's 64-bit significand) and yields 1.0L, so the first
   disjunct `1.0 != 0.5` short-circuits TRUE and the feraiseexcept/saturate arm
   is dead. Confirmed against the census-inlined IR (llvm-dis of
   /private/tmp/bc/s_lroundl.bc: `tail call @roundl` + `fptosi`, no range
   compare, no fenv call) — exactly this body.

   The lowered shape is the ld80 counterpart of lround.f64: floorl's word RMW
   rides the 3c6m.51 promoteFp80Union Shadow store (GET/SET_LDOUBLE_WORDS over
   the openbsd ieee_extended_shape_type), the multi-band exponent dispatch is
   flattened by PredMux onto the select substrate, and the trailing
   `(long)` narrowing is the fptosi. This slice is the LINK-layer proof (Rule 2)
   that every emitted i80/f80 symbol resolves and the trace is stable.

   Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
   changed): includes, license and OLM_ macros deleted (none of the five vendored
   sources carries a weak_reference); the vendored
   math_private closure inlined (the ieee_extended_shape_type LP64/little-endian
   union + GET/SET_LDOUBLE_WORDS verbatim from src/math_private_openbsd.h;
   union IEEEl2bits verbatim from src/amd64_fpmath.h — BOTH fp80 union views are
   kept, the promoteFp80Union pass owns them and a memcpy word shim is NEVER used
   at ld80, per the 3c6m.51 convention); every vendored function marked
   `__attribute__((always_inline)) static inline` with its public/`__`-prefixed
   entry renamed `olm_<name>`; intra-body calls renamed to their olm_ vendored
   names (isfinite→olm_isfinitel per the sizeof-dispatch macro, floorl→
   olm_floorl); s_floorl.c's file-scope `huge` uniquified `fl_hugel` (the
   s_lround.c template contributes no colliding static). */
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

/* src/amd64_fpmath.h — union IEEEl2bits (verbatim, both views). */
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
        unsigned long man : 64;
        unsigned int expsign : 16;
        unsigned long junk : 48;
    } xbits;
};

/* openlibm s_isfinite.c __isfinitel (verbatim). */
__attribute__((always_inline)) static inline int olm_isfinitel(long double e) {
	union IEEEl2bits u;

	u.e = e;
	return (u.bits.exp != 32767);
}

/* openlibm ld80/s_floorl.c (verbatim; `huge` → `fl_hugel`). */
static const long double fl_hugel = 1.0e4930L;

__attribute__((always_inline)) static inline long double olm_floorl(long double x)
{
	int32_t i1,jj0;
	u_int32_t i,j,se,i0,sx;
	GET_LDOUBLE_WORDS(se,i0,i1,x);
	sx = (se>>15)&1;
	jj0 = (se&0x7fff)-0x3fff;
	if(jj0<31) {
	    if(jj0<0) {	/* raise inexact if x != 0 */
		if(fl_hugel+x>0.0) {
		    if(sx==0)
			return 0.0L;
		    else if(((se&0x7fff)|i0|i1)!=0)
			return -1.0L;
		}
	    } else {
		i = (0x7fffffff)>>jj0;
		if(((i0&i)|i1)==0) return x; /* x is integral */
		if(fl_hugel+x>0.0) {	/* raise inexact flag */
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
	    if(fl_hugel+x>0.0) {		/* raise inexact flag */
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

/* openlibm s_roundl.c (verbatim; isfinite→olm_isfinitel, floorl→olm_floorl). */
__attribute__((always_inline)) static inline long double olm_roundl(long double x)
{
	long double t;

	if (!olm_isfinitel(x))
		return (x);

	if (x >= 0.0) {
		t = olm_floorl(x);
		if (t - x <= -0.5)
			t += 1.0;
		return (t);
	} else {
		t = olm_floorl(-x);
		if (t + x <= -0.5)
			t += 1.0;
		return (-t);
	}
}

/* openlibm s_lround.c instantiated by s_lroundl.c
   (type=long double, roundit=roundl, dtype=long, DTYPE_MAX=LONG_MAX).
   The INRANGE macro is vendored VERBATIM — the compile-time TRUE fold is
   DEMONSTRATED by clang, not asserted by hand (if the fold did not happen the
   live feraiseexcept call would decline loudly as a taint escape, which is
   exactly the signal we want). FE_INVALID = 0x01 per openlibm_fenv_amd64.h. */
#define LONG_MIN  (-0x7fffffffffffffffL - 1L)
#define LONG_MAX  0x7fffffffffffffffL
#define FE_INVALID 0x01
extern int feraiseexcept(int __excepts);

static const long double dtype_min = LONG_MIN - 0.5;
static const long double dtype_max = LONG_MAX + 0.5;
#define	INRANGE(x)	(dtype_max - LONG_MAX != 0.5 || \
			 ((x) > dtype_min && (x) < dtype_max))

__attribute__((always_inline)) static inline long olm_lroundl(long double x)
{

	if (INRANGE(x)) {
		x = olm_roundl(x);
		return ((long)x);
	} else {
		feraiseexcept(FE_INVALID);
		return (LONG_MAX);
	}
}

long slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_lroundl(q));
}
int main(void) { (void) slice(); return 0; }
