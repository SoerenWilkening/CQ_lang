/* CQ_lang e2e verification slice — census cell lroundf.f32 (bd 3c6m.53)
 * Vendored REAL openlibm bodies:
 *   src/s_lroundf.c  (public entry, via s_lround.c parametric body)
 *   src/s_lround.c   (parametric lround: INRANGE + roundit + cast)
 *   src/s_roundf.c   (roundf)
 *   src/s_floorf.c   (floorf)
 * Faithful copy: only the mechanical olm_ vendoring edits per bd 3c6m.53.
 */
#include <stdint.h>
#include <limits.h>
#include <fenv.h>
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
__attribute__((always_inline)) static inline double olm_fabs(double x){ uint64_t b; __builtin_memcpy(&b,&x,8); b&=0x7fffffffffffffffULL; __builtin_memcpy(&x,&b,8); return x; }
__attribute__((always_inline)) static inline float  olm_fabsf(float x){ uint32_t b; __builtin_memcpy(&b,&x,4); b&=0x7fffffffU; __builtin_memcpy(&x,&b,4); return x; }
__attribute__((always_inline)) static inline double olm_copysign(double x,double y){ uint64_t bx,by; __builtin_memcpy(&bx,&x,8); __builtin_memcpy(&by,&y,8); bx=(bx&0x7fffffffffffffffULL)|(by&0x8000000000000000ULL); __builtin_memcpy(&x,&bx,8); return x; }
__attribute__((always_inline)) static inline float  olm_copysignf(float x,float y){ uint32_t bx,by; __builtin_memcpy(&bx,&x,4); __builtin_memcpy(&by,&y,4); bx=(bx&0x7fffffffU)|(by&0x80000000U); __builtin_memcpy(&x,&bx,4); return x; }

/* ---- vendored from src/s_floorf.c ---- */
static const float huge = 1.0e30;

__attribute__((always_inline)) static inline float
olm_floorf(float x)
{
	int32_t i0,j0;
	u_int32_t i;
	GET_FLOAT_WORD(i0,x);
	j0 = ((i0>>23)&0xff)-0x7f;
	if(j0<23) {
	    if(j0<0) { 	/* raise inexact if x != 0 */
		if(huge+x>(float)0.0) {/* return 0*sign(x) if |x|<1 */
		    if(i0>=0) {i0=0;}
		    else if((i0&0x7fffffff)!=0)
			{ i0=0xbf800000;}
		}
	    } else {
		i = (0x007fffff)>>j0;
		if((i0&i)==0) return x; /* x is integral */
		if(huge+x>(float)0.0) {	/* raise inexact flag */
		    if(i0<0) i0 += (0x00800000)>>j0;
		    i0 &= (~i);
		}
	    }
	} else {
	    if(j0==0x80) return x+x;	/* inf or NaN */
	    else return x;		/* x is integral */
	}
	SET_FLOAT_WORD(x,i0);
	return x;
}

/* ---- vendored from src/s_roundf.c ---- */
__attribute__((always_inline)) static inline float
olm_roundf(float x)
{
	float t;

	if (!__builtin_isfinite(x))
		return (x);

	if (x >= 0.0) {
		t = olm_floorf(x);
		if (t - x <= -0.5)
			t += 1.0;
		return (t);
	} else {
		t = olm_floorf(-x);
		if (t + x <= -0.5)
			t += 1.0;
		return (-t);
	}
}

/* ---- vendored from src/s_lround.c (parametric) with s_lroundf.c params:
   type=float, roundit=roundf, dtype=long, DTYPE_MIN=LONG_MIN,
   DTYPE_MAX=LONG_MAX, fn=lroundf ---- */
static const float dtype_min = LONG_MIN - 0.5;
static const float dtype_max = LONG_MAX + 0.5;
#define	INRANGE(x)	(dtype_max - LONG_MAX != 0.5 || \
			 ((x) > dtype_min && (x) < dtype_max))

static long
olm_lroundf(float x)
{

	if (INRANGE(x)) {
		x = olm_roundf(x);
		return ((long)x);
	} else {
		feraiseexcept(FE_INVALID);
		return (LONG_MAX);
	}
}

long slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure(olm_lroundf(q));
}
int main(void) { (void) slice(); return 0; }
