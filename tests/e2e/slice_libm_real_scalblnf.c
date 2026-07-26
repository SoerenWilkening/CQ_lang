/* CQ_lang e2e verification slice — census cell scalblnf.f32 (bd 3c6m.53)
 * Vendored REAL openlibm source:
 *   entry:  src/s_scalbln.c   (scalblnf wrapper: int cast + INT_MAX/MIN clamp)
 *   dep:    src/s_scalbnf.c    (scalbnf float body)
 *
 * KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution — bd tkju):
 * olm_scalbnf's overflow/underflow arms call copysignf, a HARDWARE KEEP. At
 * the ship floor (plain clang -O1, builtins ON) the named call folds to
 * @llvm.copysign.f32 before codegen and cq-lowering rewrites that to
 * cq_template_copysign_f32_lh (the literal `huge` + the tainted handle). A
 * keep has no injectable body, so the s_copysignf.c bit-op shim vendored here
 * before (olm_copysignf, plus the unused olm_fabs/olm_fabsf/olm_copysign
 * siblings) misrepresented the ship floor and is deleted. MEASURED: the shim's
 * 4 template calls (one each of bitcast_f32_to_i32 / and_i32_hl / or_i32_hl /
 * bitcast_i32_to_f32) collapse to the single copysign template — trace
 * 238 -> 235 lines.
 */
#include <stdint.h>
#include <limits.h>
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
/* ---- vendored from src/s_scalbnf.c ---- */
static const float
two25   =  3.355443200e+07,	/* 0x4c000000 */
twom25  =  2.9802322388e-08,	/* 0x33000000 */
huge   = 1.0e+30,
tiny   = 1.0e-30;

__attribute__((always_inline)) static inline float
olm_scalbnf (float x, int n)
{
	int32_t k,ix;
	GET_FLOAT_WORD(ix,x);
        k = (ix&0x7f800000)>>23;		/* extract exponent */
        if (k==0) {				/* 0 or subnormal x */
            if ((ix&0x7fffffff)==0) return x; /* +-0 */
	    x *= two25;
	    GET_FLOAT_WORD(ix,x);
	    k = ((ix&0x7f800000)>>23) - 25;
            if (n< -50000) return tiny*x; 	/*underflow*/
	    }
        if (k==0xff) return x+x;		/* NaN or Inf */
        k = k+n;
        if (k >  0xfe) return huge*__builtin_copysignf(huge,x); /* overflow  */
        if (k > 0) 				/* normal result */
	    {SET_FLOAT_WORD(x,(ix&0x807fffff)|(k<<23)); return x;}
        if (k <= -25) {
            if (n > 50000) 	/* in case integer overflow in n+k */
		return huge*__builtin_copysignf(huge,x);	/*overflow*/
	    else return tiny*__builtin_copysignf(tiny,x);	/*underflow*/
        }
	k += 25;				/* subnormal result */
	SET_FLOAT_WORD(x,(ix&0x807fffff)|(k<<23));
        return x*twom25;
}

/* ---- vendored from src/s_scalbln.c (scalblnf wrapper) ---- */
__attribute__((always_inline)) static inline float
olm_scalblnf (float x, long n)
{
	int in;

	in = (int)n;
	if (in != n) {
		if (n > 0)
			in = INT_MAX;
		else
			in = INT_MIN;
	}
	return (olm_scalbnf(x, in));
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_scalblnf(q, 2));
}
int main(void) { (void) slice(); return 0; }
