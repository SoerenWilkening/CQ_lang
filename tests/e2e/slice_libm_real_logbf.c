/* slice_libm_real_logbf.c — REAL openlibm logbf (f32) census cell logbf.f32.
 * Vendored verbatim from openlibm src/s_logbf.c (self-contained), fabsf spelled
 * __builtin_fabsf. bd 3c6m.53.
 *
 * KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution; bd tkju):
 * fabsf is a HARDWARE KEEP and is NOT vendored — at the real ship floor (plain
 * clang -O1, builtins ON) it folds to @llvm.fabs.f32 before codegen and
 * cq-lowering rewrites that to cq_template_fabs_f32. The preamble's earlier
 * software fabs/fabsf/copysign/copysignf shims are deleted: MEASURED, the fabsf
 * shim already folded to the same @llvm.fabs.f32 at -O1 and the other three had
 * no call site at all, so the deletion is IR-invisible — 2 cq_template_fabs_f32
 * before and after, 61-line golden byte-identical. Those 2 come mostly from
 * clang, not from the one source fabsf: -O1 canonicalizes each
 * `ix &= 0x7fffffff` word mask into @llvm.fabs.f32 + bitcast (once for x, once
 * for x*2**25), and the source's own -1.0/fabsf(x) shares the first of them. */
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
static const float
two25 = 3.355443200e+07;		/* 0x4c000000 */

__attribute__((always_inline)) static inline float
olm_logbf(float x)
{
	int32_t ix;
	GET_FLOAT_WORD(ix,x);
	ix &= 0x7fffffff;			/* high |x| */
	if(ix==0) return (float)-1.0/__builtin_fabsf(x);
	if(ix>=0x7f800000) return x*x;
	if(ix<0x00800000) {
		x *= two25;		 /* convert subnormal x to normal */
		GET_FLOAT_WORD(ix,x);
		ix &= 0x7fffffff;
		return (float) ((ix>>23)-127-25);
	} else
		return (float) ((ix>>23)-127);
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_logbf(q));
}
int main(void) { (void) slice(); return 0; }
