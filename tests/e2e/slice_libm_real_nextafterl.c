/* slice_libm_real_nextafterl.c — bd 3c6m.58: the REAL openlibm nextafterl body
 * (ld80/s_nextafterl.c, fdlibm/OpenBSD-derived, BSD-licensed) over x86_fp80
 * `long double` — census cell nextafterl.f80.
 *
 * ld80 sibling of nextafter.f64 / nextafterf.f32. Two things make it the hardest
 * of the three: (1) the ±1 ulp walk is a THREE-word borrow/carry chain
 * (esx exponent-sign / hx high mantissa / lx low mantissa) rather than f64's two,
 * with the explicit-integer-bit `(hx ± 1) | (hx & 0x80000000)` fixups the
 * 80-bit format requires; and (2) the volatile underflow-raise locals are
 * declared INSIDE their arms (`volatile long double u;`) — still the bd zco4
 * Inc 1 promoteVolatileScalarLocals shape, but block-scoped. The word access
 * rides the openbsd ieee_extended_shape_type GET/SET_LDOUBLE_WORDS union (the
 * 3c6m.51 promoteFp80Union RMW).
 *
 * This slice is the LINK-layer proof (Rule 2) that every emitted i80/f80 symbol
 * resolves and the trace is stable.
 *
 * The probe pins the census cell: x = theta-tainted, y = 0.5L (classical), so
 * the y-side word extract and NaN guard const-fold exactly as in the census IR.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed — the `volatile` qualifiers are load-bearing and kept VERBATIM, as is
 * openlibm's `hx&0x7fffffff|lx` precedence and the `esy>=0` unsigned compare):
 * includes, license and the commented-out __strong_alias deleted; the entry
 * renamed `olm_nextafterl` and marked `__attribute__((always_inline)) static
 * inline`; the vendored math_private closure inlined (the
 * ieee_extended_shape_type LP64/little-endian union + GET/SET_LDOUBLE_WORDS
 * verbatim from src/math_private_openbsd.h; u_int32_t typedef).
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

__attribute__((always_inline)) static inline long double olm_nextafterl(long double x, long double y)
{
	int32_t hx,hy,ix,iy;
	u_int32_t lx,ly,esx,esy;

	GET_LDOUBLE_WORDS(esx,hx,lx,x);
	GET_LDOUBLE_WORDS(esy,hy,ly,y);
	ix = esx&0x7fff;		/* |x| */
	iy = esy&0x7fff;		/* |y| */

	if (((ix==0x7fff)&&((hx&0x7fffffff|lx)!=0)) ||   /* x is nan */
	    ((iy==0x7fff)&&((hy&0x7fffffff|ly)!=0)))     /* y is nan */
	   return x+y;
	if(x==y) return y;		/* x=y, return y */
	if((ix|hx|lx)==0) {			/* x == 0 */
	    volatile long double u;
	    SET_LDOUBLE_WORDS(x,esy&0x8000,0,1);/* return +-minsubnormal */
	    u = x;
	    u = u * u;				/* raise underflow flag */
	    return x;
	}
	if(esx<0x8000) {			/* x > 0 */
	    if(ix>iy||((ix==iy) && (hx>hy||((hx==hy)&&(lx>ly))))) {
	      /* x > y, x -= ulp */
		if(lx==0) {
		    if ((hx&0x7fffffff)==0) esx -= 1;
		    hx = (hx - 1) | (hx & 0x80000000);
		}
		lx -= 1;
	    } else {				/* x < y, x += ulp */
		lx += 1;
		if(lx==0) {
		    hx = (hx + 1) | (hx & 0x80000000);
		    if ((hx&0x7fffffff)==0) esx += 1;
		}
	    }
	} else {				/* x < 0 */
	    if(esy>=0||(ix>iy||((ix==iy)&&(hx>hy||((hx==hy)&&(lx>ly)))))){
	      /* x < y, x -= ulp */
		if(lx==0) {
		    if ((hx&0x7fffffff)==0) esx -= 1;
		    hx = (hx - 1) | (hx & 0x80000000);
		}
		lx -= 1;
	    } else {				/* x > y, x += ulp */
		lx += 1;
		if(lx==0) {
		    hx = (hx + 1) | (hx & 0x80000000);
		    if ((hx&0x7fffffff)==0) esx += 1;
		}
	    }
	}
	esy = esx&0x7fff;
	if(esy==0x7fff) return x+x;		/* overflow  */
	if(esy==0) {
	    volatile long double u = x*x;	/* underflow */
	    if(u==x) {
		SET_LDOUBLE_WORDS(x,esx,hx,lx);
		return x;
	    }
	}
	SET_LDOUBLE_WORDS(x,esx,hx,lx);
	return x;
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_nextafterl(q, 0.5L));
}
int main(void) { (void) slice(); return 0; }
