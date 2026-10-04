/* CQ_lang e2e verification slice — census cell logb.f64 (bd 3c6m.53)
 * Vendors the REAL openlibm body of logb from:
 *   /private/tmp/openlibm/src/s_logb.c
 * Self-contained (no dependency corpus files). Mechanical edits only:
 * #includes/license/LDBL-trailer stripped; entry renamed to
 * always_inline static inline olm_logb; fabs spelled __builtin_fabs.
 *
 * KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution; bd tkju):
 * fabs is a HARDWARE KEEP and is NOT vendored — at the real ship floor (plain
 * clang -O1, builtins ON) it folds to @llvm.fabs.f64 before codegen and
 * cq-lowering rewrites that to cq_template_fabs_f64 (1 in this trace, the
 * -1.0/fabs(x) zero arm). The preamble's earlier software fabs/fabsf/copysign/
 * copysignf shims are deleted: MEASURED, the fabs shim already folded to the
 * same @llvm.fabs.f64 at -O1 and the other three had no call site at all, so
 * the deletion is IR-invisible — 67-line golden byte-identical.
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
static const double
two54 = 1.80143985094819840000e+16;	/* 43500000 00000000 */

__attribute__((always_inline)) static inline double
olm_logb(double x)
{
	int32_t lx,ix;
	EXTRACT_WORDS(ix,lx,x);
	ix &= 0x7fffffff;			/* high |x| */
	if((ix|lx)==0) return -1.0/__builtin_fabs(x);
	if(ix>=0x7ff00000) return x*x;
	if(ix<0x00100000) {
		x *= two54;		 /* convert subnormal x to normal */
		GET_HIGH_WORD(ix,x);
		ix &= 0x7fffffff;
		return (double) ((ix>>20)-1023-54);
	} else
		return (double) ((ix>>20)-1023);
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_logb(q));
}
int main(void) { (void) slice(); return 0; }
