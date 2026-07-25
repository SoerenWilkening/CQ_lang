/* slice_libm_real_modfl.c — bd 3c6m.58: the REAL openlibm modfl body
 * (ld80/s_modfl.c, fdlibm/OpenBSD-derived, BSD-licensed) over x86_fp80
 * `long double` — census cell modfl.f80.
 *
 * ld80 sibling of the verified modf.f64 / modff.f32 goldens. Where those use the
 * memcpy word shim, this body drives the openbsd `ieee_extended_shape_type`
 * GET/SET_LDOUBLE_WORDS union (the 3c6m.51 promoteFp80Union RMW), across a
 * 3-band exponent dispatch (jj0<32 integer-part-in-high-word / jj0>63 no-fraction
 * / else fraction-in-low-word) that PredMux flattens onto the select substrate.
 * This slice is the LINK-layer proof (Rule 2) that the emitted i80/f80 symbols
 * resolve and the trace is stable.
 *
 * The probe pins the census cell EXACTLY as wprobe.make_src builds it:
 * `long double outp; r = modfl(q, &outp); return measure(r)` — the out-param is
 * declared and passed but NEVER READ (the same convention as the already-verified
 * modf.f64 golden), so clang -O1 DCEs the `*iptr` stores before cq-lowering runs
 * and this golden verifies the FRACTIONAL-return half only. See the frexp.f64
 * sibling header for the full measured scope caveat.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed): includes and license deleted (ld80/s_modfl.c carries no OLM_ macro —
 * its entry is a bare `long double modfl(...)`); the entry renamed
 * `olm_modfl` and marked `__attribute__((always_inline)) static inline`; the
 * vendored math_private closure inlined (the ieee_extended_shape_type
 * LP64/little-endian union + GET/SET_LDOUBLE_WORDS verbatim from
 * src/math_private_openbsd.h; u_int32_t typedef); s_modfl.c's file-scope `one`
 * uniquified `mdf_one`.
 */
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

static const long double mdf_one = 1.0;

__attribute__((always_inline)) static inline long double olm_modfl(long double x, long double *iptr)
{
	int32_t i0,i1,jj0;
	u_int32_t i,se;
	GET_LDOUBLE_WORDS(se,i0,i1,x);
	jj0 = (se&0x7fff)-0x3fff;	/* exponent of x */
	if(jj0<32) {			/* integer part in high x */
	    if(jj0<0) {			/* |x|<1 */
		SET_LDOUBLE_WORDS(*iptr,se&0x8000,0,0);	/* *iptr = +-0 */
		return x;
	    } else {
		i = (0x7fffffff)>>jj0;
		if(((i0&i)|i1)==0) {		/* x is integral */
		    *iptr = x;
		    SET_LDOUBLE_WORDS(x,se&0x8000,0,0);	/* return +-0 */
		    return x;
		} else {
		    SET_LDOUBLE_WORDS(*iptr,se,i0&(~i),0);
		    return x - *iptr;
		}
	    }
	} else if (jj0>63) {		/* no fraction part */
	    *iptr = x*mdf_one;
	    /* We must handle NaNs separately.  */
	    if (jj0 == 0x4000 && ((i0 & 0x7fffffff) | i1))
	      return x*mdf_one;
	    SET_LDOUBLE_WORDS(x,se&0x8000,0,0);	/* return +-0 */
	    return x;
	} else {			/* fraction part in low x */
	    i = ((u_int32_t)(0x7fffffff))>>(jj0-32);
	    if((i1&i)==0) {		/* x is integral */
		*iptr = x;
		SET_LDOUBLE_WORDS(x,se&0x8000,0,0);	/* return +-0 */
		return x;
	    } else {
		SET_LDOUBLE_WORDS(*iptr,se,i0,i1&(~i));
		return x - *iptr;
	    }
	}
}

long double slice(void) {
    long double ip;
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_modfl(q, &ip));
}
int main(void) { (void) slice(); return 0; }
