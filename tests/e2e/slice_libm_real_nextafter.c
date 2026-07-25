/* slice_libm_real_nextafter.c — bd 3c6m.58: the REAL openlibm nextafter body
 * (src/s_nextafter.c, fdlibm-derived, BSD-licensed) over f64 — census cell
 * nextafter.f64.
 *
 * This is a VOLATILE-LOCAL cell: the body declares `volatile double t` and uses
 * `t = x*x` at two sites as the fdlibm idiom for RAISING the underflow flag (the
 * store exists purely for its fp side effect). NB the two sites test OPPOSITE
 * predicates: the x==0 min-subnormal path branches on `if(t==x)`, the trailing
 * underflow path on `if(t!=x)`. It is the shape bd zco4
 * Inc 1 `promoteVolatileScalarLocals` was built for — a volatile scalar local
 * whose address never escapes is promoted to a register so the taint pass sees
 * plain SSA arithmetic rather than a Shadow store. (Contrast nexttowardf.f32,
 * which the taxonomy still lists as declining: that one's volatile store is
 * genuinely runtime-valued in a way this promotion does not reach.)
 *
 * The rest is the bit-pattern ±1 ulp walk: two word extracts, the x/y NaN
 * guards, the x==0 min-subnormal path, the signed hi/lo borrow-propagating
 * decrement/increment under a tainted comparison ladder that PredMux flattens
 * onto the select substrate, and the overflow/underflow repack. This slice is
 * the LINK-layer proof (Rule 2) that every emitted symbol resolves and the
 * trace is stable.
 *
 * The probe pins the census cell: x = theta-tainted, y = 0.5 (classical), so the
 * y-side word extract and NaN guard const-fold exactly as in the census IR.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed — the `volatile` qualifiers are load-bearing and kept VERBATIM):
 * includes, license, OLM_ macros and weak_reference deleted; the entry renamed
 * `olm_nextafter` and marked `__attribute__((always_inline)) static inline`;
 * math_private.h word macros expanded to the __builtin_memcpy idiom.
 */
#include <stdint.h>

typedef uint32_t u_int32_t;

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define INSERT_WORDS(d,hi,lo)  do{ uint64_t __w=((uint64_t)(uint32_t)(hi)<<32)|(uint32_t)(lo); __builtin_memcpy(&(d),&__w,8); }while(0)

__attribute__((always_inline)) static inline double olm_nextafter(double x, double y)
{
	volatile double t;
	int32_t hx,hy,ix,iy;
	u_int32_t lx,ly;

	EXTRACT_WORDS(hx,lx,x);
	EXTRACT_WORDS(hy,ly,y);
	ix = hx&0x7fffffff;		/* |x| */
	iy = hy&0x7fffffff;		/* |y| */

	if(((ix>=0x7ff00000)&&((ix-0x7ff00000)|lx)!=0) ||   /* x is nan */
	   ((iy>=0x7ff00000)&&((iy-0x7ff00000)|ly)!=0))     /* y is nan */
	   return x+y;
	if(x==y) return y;		/* x=y, return y */
	if((ix|lx)==0) {			/* x == 0 */
	    INSERT_WORDS(x,hy&0x80000000,1);	/* return +-minsubnormal */
	    t = x*x;
	    if(t==x) return t; else return x;	/* raise underflow flag */
	}
	if(hx>=0) {				/* x > 0 */
	    if(hx>hy||((hx==hy)&&(lx>ly))) {	/* x > y, x -= ulp */
		if(lx==0) hx -= 1;
		lx -= 1;
	    } else {				/* x < y, x += ulp */
		lx += 1;
		if(lx==0) hx += 1;
	    }
	} else {				/* x < 0 */
	    if(hy>=0||hx>hy||((hx==hy)&&(lx>ly))){/* x < y, x -= ulp */
		if(lx==0) hx -= 1;
		lx -= 1;
	    } else {				/* x > y, x += ulp */
		lx += 1;
		if(lx==0) hx += 1;
	    }
	}
	hy = hx&0x7ff00000;
	if(hy>=0x7ff00000) return x+x;	/* overflow  */
	if(hy<0x00100000) {		/* underflow */
	    t = x*x;
	    if(t!=x) {		/* raise underflow flag */
	        INSERT_WORDS(y,hx,lx);
		return y;
	    }
	}
	INSERT_WORDS(x,hx,lx);
	return x;
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_nextafter(q, 0.5));
}
int main(void) { (void) slice(); return 0; }
