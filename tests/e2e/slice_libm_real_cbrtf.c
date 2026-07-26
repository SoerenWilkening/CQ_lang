/* slice_libm_real_cbrtf.c -- e2e verification slice for census cell cbrtf.f32
 * Vendors the REAL openlibm cbrtf body from src/s_cbrtf.c (self-contained: the
 * body calls no other libm function, so the injection closure is one file).
 * bd 3c6m.53 (injection-covered -> VERIFIED; Rule 2 link-layer + Rule 18 real-source).
 *
 * KEEP-SET (Rule 18 ship-floor fold, NOT a body substitution) -- bd tkju: there
 * is no keep CALL here, yet the 124-line golden prints 2 cq_template_fabs_f32.
 * Those come from clang -O1 IDIOM recognition of the body's own sign-bit clears
 * (`hx ^= sign` and `high & 0x7fffffff` over the float word pun), which fold to
 * @llvm.fabs.f32 before cq-lowering runs -- measured: stage-1 @slice carries
 * exactly those 2 sites. The four olm_fabs/olm_fabsf/olm_copysign/olm_copysignf
 * shims that used to sit in the prelude were DEAD (never called) and are
 * deleted; the golden is byte-identical across that deletion.
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
/* ---- vendored from openlibm src/s_cbrtf.c ---- */
static const unsigned
	B1 = 709958130, /* B1 = (127-127.0/3-0.03306235651)*2**23 */
	B2 = 642849266; /* B2 = (127-127.0/3-24/3-0.03306235651)*2**23 */

__attribute__((always_inline)) static inline float
olm_cbrtf(float x)
{
	double r,T;
	float t;
	int32_t hx;
	u_int32_t sign;
	u_int32_t high;

	GET_FLOAT_WORD(hx,x);
	sign=hx&0x80000000; 		/* sign= sign(x) */
	hx  ^=sign;
	if(hx>=0x7f800000) return(x+x); /* cbrt(NaN,INF) is itself */

    /* rough cbrt to 5 bits */
	if(hx<0x00800000) { 		/* zero or subnormal? */
	    if(hx==0)
		return(x);		/* cbrt(+-0) is itself */
	    SET_FLOAT_WORD(t,0x4b800000); /* set t= 2**24 */
	    t*=x;
	    GET_FLOAT_WORD(high,t);
	    SET_FLOAT_WORD(t,sign|((high&0x7fffffff)/3+B2));
	} else
	    SET_FLOAT_WORD(t,sign|(hx/3+B1));

    /*
     * First step Newton iteration (solving t*t-x/t == 0) to 16 bits.  In
     * double precision so that its terms can be arranged for efficiency
     * without causing overflow or underflow.
     */
	T=t;
	r=T*T*T;
	T=T*((double)x+x+r)/(x+r+r);

    /*
     * Second step Newton iteration to 47 bits.  In double precision for
     * efficiency and accuracy.
     */
	r=T*T*T;
	T=T*((double)x+x+r)/(x+r+r);

    /* rounding to 24 bits is perfect in round-to-nearest mode */
	return(T);
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_cbrtf(q));
}
int main(void) { (void) slice(); return 0; }
