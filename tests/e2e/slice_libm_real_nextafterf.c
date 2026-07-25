/* slice_libm_real_nextafterf.c — bd 3c6m.58: the REAL openlibm nextafterf body
 * (src/s_nextafterf.c, fdlibm-derived, BSD-licensed) over f32 — census cell
 * nextafterf.f32.
 *
 * f32 sibling of nextafter.f64: same VOLATILE-LOCAL underflow-raise idiom
 * (`volatile float t; t = x*x;`, the bd zco4 Inc 1 promoteVolatileScalarLocals
 * shape) and the same bit-pattern ±1 ulp walk — but at width 32 the value is a
 * SINGLE word, so the hi/lo borrow propagation of the f64 body collapses to a
 * plain `hx -= 1` / `hx += 1` and the NaN guards are single compares.
 *
 * The probe pins the census cell: x = theta-tainted, y = 0.5f (classical), so
 * the y-side word extract and NaN guard const-fold exactly as in the census IR.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed — the `volatile` qualifier is load-bearing and kept VERBATIM):
 * includes, license and OLM_ macros deleted; the entry renamed `olm_nextafterf`
 * and marked `__attribute__((always_inline)) static inline`; math_private.h word
 * macros expanded to the __builtin_memcpy idiom.
 */
#include <stdint.h>

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)

__attribute__((always_inline)) static inline float olm_nextafterf(float x, float y)
{
	volatile float t;
	int32_t hx,hy,ix,iy;

	GET_FLOAT_WORD(hx,x);
	GET_FLOAT_WORD(hy,y);
	ix = hx&0x7fffffff;		/* |x| */
	iy = hy&0x7fffffff;		/* |y| */

	if((ix>0x7f800000) ||   /* x is nan */
	   (iy>0x7f800000))     /* y is nan */
	   return x+y;
	if(x==y) return y;		/* x=y, return y */
	if(ix==0) {				/* x == 0 */
	    SET_FLOAT_WORD(x,(hy&0x80000000)|1);/* return +-minsubnormal */
	    t = x*x;
	    if(t==x) return t; else return x;	/* raise underflow flag */
	}
	if(hx>=0) {				/* x > 0 */
	    if(hx>hy) {				/* x > y, x -= ulp */
		hx -= 1;
	    } else {				/* x < y, x += ulp */
		hx += 1;
	    }
	} else {				/* x < 0 */
	    if(hy>=0||hx>hy){			/* x < y, x -= ulp */
		hx -= 1;
	    } else {				/* x > y, x += ulp */
		hx += 1;
	    }
	}
	hy = hx&0x7f800000;
	if(hy>=0x7f800000) return x+x;	/* overflow  */
	if(hy<0x00800000) {		/* underflow */
	    t = x*x;
	    if(t!=x) {		/* raise underflow flag */
	        SET_FLOAT_WORD(y,hx);
		return y;
	    }
	}
	SET_FLOAT_WORD(x,hx);
	return x;
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_nextafterf(q, 0.5f));
}
int main(void) { (void) slice(); return 0; }
