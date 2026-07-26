/* slice_libm_real_atanf.c — REAL openlibm atanf (f32) end-to-end verification slice.
 * Cell: atanf.f32. Source: openlibm src/s_atanf.c (self-contained). bd 3c6m.53.
 * Vendored verbatim from the real corpus with only mechanical edits (shim word
 * macros, olm_-prefixed always_inline entry, fabsf spelled __builtin_fabsf).
 *
 * KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution; bd tkju):
 * fabsf is a HARDWARE KEEP and is NOT vendored — at the real ship floor (plain
 * clang -O1, builtins ON) it folds to @llvm.fabs.f32 before codegen and
 * cq-lowering rewrites that to cq_template_fabs_f32. The preamble's earlier
 * software fabs/fabsf/copysign/copysignf shims are deleted: MEASURED, the fabsf
 * shim already folded to the same @llvm.fabs.f32 at -O1 and the other three had
 * no call site at all, so the deletion is IR-invisible — 585-line golden
 * byte-identical. That trace carries just 1 cq_template_fabs_f32 for the whole
 * body: clang -O1 also canonicalizes the source's own `ix &= 0x7fffffff` word
 * mask into @llvm.fabs.f32 + bitcast, so the masked word and `x = fabsf(x)` are
 * one value sharing one template (in the golden, ix IS the bitcast of the fabs
 * result). */
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
static const float atanhi[] = {
  4.6364760399e-01, /* atan(0.5)hi 0x3eed6338 */
  7.8539812565e-01, /* atan(1.0)hi 0x3f490fda */
  9.8279368877e-01, /* atan(1.5)hi 0x3f7b985e */
  1.5707962513e+00, /* atan(inf)hi 0x3fc90fda */
};

static const float atanlo[] = {
  5.0121582440e-09, /* atan(0.5)lo 0x31ac3769 */
  3.7748947079e-08, /* atan(1.0)lo 0x33222168 */
  3.4473217170e-08, /* atan(1.5)lo 0x33140fb4 */
  7.5497894159e-08, /* atan(inf)lo 0x33a22168 */
};

static const float aT[] = {
  3.3333328366e-01,
 -1.9999158382e-01,
  1.4253635705e-01,
 -1.0648017377e-01,
  6.1687607318e-02,
};

static const float
one   = 1.0,
huge   = 1.0e30;

__attribute__((always_inline)) static inline float
olm_atanf(float x)
{
	float w,s1,s2,z;
	int32_t ix,hx,id;

	GET_FLOAT_WORD(hx,x);
	ix = hx&0x7fffffff;
	if(ix>=0x4c800000) {	/* if |x| >= 2**26 */
	    if(ix>0x7f800000)
		return x+x;		/* NaN */
	    if(hx>0) return  atanhi[3]+*(volatile float *)&atanlo[3];
	    else     return -atanhi[3]-*(volatile float *)&atanlo[3];
	} if (ix < 0x3ee00000) {	/* |x| < 0.4375 */
	    if (ix < 0x39800000) {	/* |x| < 2**-12 */
		if(huge+x>one) return x;	/* raise inexact */
	    }
	    id = -1;
	} else {
	x = __builtin_fabsf(x);
	if (ix < 0x3f980000) {		/* |x| < 1.1875 */
	    if (ix < 0x3f300000) {	/* 7/16 <=|x|<11/16 */
		id = 0; x = ((float)2.0*x-one)/((float)2.0+x);
	    } else {			/* 11/16<=|x|< 19/16 */
		id = 1; x  = (x-one)/(x+one);
	    }
	} else {
	    if (ix < 0x401c0000) {	/* |x| < 2.4375 */
		id = 2; x  = (x-(float)1.5)/(one+(float)1.5*x);
	    } else {			/* 2.4375 <= |x| < 2**26 */
		id = 3; x  = -(float)1.0/x;
	    }
	}}
    /* end of argument reduction */
	z = x*x;
	w = z*z;
    /* break sum from i=0 to 10 aT[i]z**(i+1) into odd and even poly */
	s1 = z*(aT[0]+w*(aT[2]+w*aT[4]));
	s2 = w*(aT[1]+w*aT[3]);
	if (id<0) return x - x*(s1+s2);
	else {
	    z = atanhi[id] - ((x*(s1+s2) - atanlo[id]) - x);
	    return (hx<0)? -z:z;
	}
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_atanf(q));
}
int main(void) { (void) slice(); return 0; }
