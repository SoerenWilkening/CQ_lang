/* CQ_lang e2e verification slice — census cell modf.f64
 * Vendored REAL openlibm body from: /private/tmp/openlibm/src/s_modf.c
 * (self-contained — no dependency corpus files, and no libm call of any kind)
 * bd 3c6m.53 — injection-covered -> VERIFIED (Rule 2 link-layer, Rule 18 real-source injection)
 *
 * KEEP-SET (Rule 18) — bd tkju: this cell reaches NO keep route. s_modf.c calls
 * no keep, and clang -O1 recognizes no keep idiom in it either — measured: the
 * stage-1 IR contains ZERO @llvm.* intrinsics. The 168-line golden is entirely
 * word-bit and fp route-merge traffic (the 2 cq_template_trunc_i64_to_i32 are
 * the INTEGER trunc opcode, not the fp `trunc` keep). The four
 * olm_fabs/olm_fabsf/olm_copysign/olm_copysignf shims that used to sit in the
 * prelude were DEAD (never called) and are deleted; the golden is byte-identical
 * across that deletion.
 */
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
static const double one = 1.0;

__attribute__((always_inline)) static inline double
olm_modf(double x, double *iptr)
{
	int32_t i0,i1,j0;
	u_int32_t i;
	EXTRACT_WORDS(i0,i1,x);
	j0 = ((i0>>20)&0x7ff)-0x3ff;	/* exponent of x */
	if(j0<20) {			/* integer part in high x */
	    if(j0<0) {			/* |x|<1 */
	        INSERT_WORDS(*iptr,i0&0x80000000,0);	/* *iptr = +-0 */
		return x;
	    } else {
		i = (0x000fffff)>>j0;
		if(((i0&i)|i1)==0) {		/* x is integral */
		    u_int32_t high;
		    *iptr = x;
		    GET_HIGH_WORD(high,x);
		    INSERT_WORDS(x,high&0x80000000,0);	/* return +-0 */
		    return x;
		} else {
		    INSERT_WORDS(*iptr,i0&(~i),0);
		    return x - *iptr;
		}
	    }
	} else if (j0>51) {		/* no fraction part */
	    u_int32_t high;
	    if (j0 == 0x400) {		/* inf/NaN */
		*iptr = x;
		return 0.0 / x;
	    }
	    *iptr = x*one;
	    GET_HIGH_WORD(high,x);
	    INSERT_WORDS(x,high&0x80000000,0);	/* return +-0 */
	    return x;
	} else {			/* fraction part in low x */
	    i = ((u_int32_t)(0xffffffff))>>(j0-20);
	    if((i1&i)==0) { 		/* x is integral */
	        u_int32_t high;
		*iptr = x;
		GET_HIGH_WORD(high,x);
		INSERT_WORDS(x,high&0x80000000,0);	/* return +-0 */
		return x;
	    } else {
	        INSERT_WORDS(*iptr,i0,i1&(~i));
		return x - *iptr;
	    }
	}
}

double slice(void) {
    double ip;
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_modf(q, &ip));
}
int main(void) { (void) slice(); return 0; }
