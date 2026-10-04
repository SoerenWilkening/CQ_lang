/* slice_libm_real_log2.c — bd 3c6m.53: the REAL openlibm log2 body
   (census cell log2.f64). Entry corpus: openlibm/src/e_log2.c; dependency
   corpus: openlibm/src/k_log.h (k_log1p, vendored as olm_k_log1p). Verbatim
   fdlibm-derived algorithm with the math_private.h word macros expanded to the
   __builtin_memcpy idiom clang -O1 folds to the same bitcast IR the taint pass
   lowers. That is the WHOLE closure — the vendored text calls nothing but
   other vendored text (the stage-1 IR's only external declares are
   @cq_theta_f64 / @cq_measure_f64 and the @llvm.fmuladd.f64 keep).
   Rule 18 real-source injection; Rule 2 link-layer proof.

   KEEP-SET (Rule 18 ship-floor fold, NOT a body substitution; bd tkju): the
   unreferenced fabs/copysign shim helpers this file used to carry are deleted
   — both are HARDWARE KEEPS with no injectable body, so a vendored software
   shim models a program the ship floor never compiles. They were dead text
   here and the golden is BYTE-IDENTICAL across the deletion (measured). The
   only keep construct reaching the pass is clang's own: at plain -O1
   fp-contract fuses 6 @llvm.fmuladd.f64, lowered 1:1 to the golden's 6
   cq_template_fma_f64* calls. */
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
/* ---- vendored from openlibm/src/k_log.h ---- */
static const double
Lg1 = 6.666666666666735130e-01,  /* 3FE55555 55555593 */
Lg2 = 3.999999999940941908e-01,  /* 3FD99999 9997FA04 */
Lg3 = 2.857142874366239149e-01,  /* 3FD24924 94229359 */
Lg4 = 2.222219843214978396e-01,  /* 3FCC71C5 1D8E78AF */
Lg5 = 1.818357216161805012e-01,  /* 3FC74664 96CB03DE */
Lg6 = 1.531383769920937332e-01,  /* 3FC39A09 D078C69F */
Lg7 = 1.479819860511658591e-01;  /* 3FC2F112 DF3E5244 */

__attribute__((always_inline)) static inline double
olm_k_log1p(double f)
{
	double hfsq,s,z,R,w,t1,t2;

 	s = f/(2.0+f);
	z = s*s;
	w = z*z;
	t1= w*(Lg2+w*(Lg4+w*Lg6));
	t2= z*(Lg1+w*(Lg3+w*(Lg5+w*Lg7)));
	R = t2+t1;
	hfsq=0.5*f*f;
	return s*(hfsq+R);
}

/* ---- vendored from openlibm/src/e_log2.c ---- */
static const double
two54      =  1.80143985094819840000e+16, /* 0x43500000, 0x00000000 */
ivln2hi    =  1.44269504072144627571e+00, /* 0x3ff71547, 0x65200000 */
ivln2lo    =  1.67517131648865118353e-10; /* 0x3de705fc, 0x2eefa200 */

static const double zero   =  0.0;

__attribute__((always_inline)) static inline double
olm_log2(double x)
{
	double f,hfsq,hi,lo,r,val_hi,val_lo,w,y;
	int32_t i,k,hx;
	u_int32_t lx;

	EXTRACT_WORDS(hx,lx,x);

	k=0;
	if (hx < 0x00100000) {			/* x < 2**-1022  */
	    if (((hx&0x7fffffff)|lx)==0)
		return -two54/zero;		/* log(+-0)=-inf */
	    if (hx<0) return (x-x)/zero;	/* log(-#) = NaN */
	    k -= 54; x *= two54; /* subnormal number, scale up x */
	    GET_HIGH_WORD(hx,x);
	}
	if (hx >= 0x7ff00000) return x+x;
	if (hx == 0x3ff00000 && lx == 0)
	    return zero;			/* log(1) = +0 */
	k += (hx>>20)-1023;
	hx &= 0x000fffff;
	i = (hx+0x95f64)&0x100000;
	SET_HIGH_WORD(x,hx|(i^0x3ff00000));	/* normalize x or x/2 */
	k += (i>>20);
	y = (double)k;
	f = x - 1.0;
	hfsq = 0.5*f*f;
	r = olm_k_log1p(f);

	hi = f - hfsq;
	SET_LOW_WORD(hi,0);
	lo = (f - hi) - hfsq + r;
	val_hi = hi*ivln2hi;
	val_lo = (lo+hi)*ivln2lo + lo*ivln2hi;

	/* spadd(val_hi, val_lo, y), except for not using double_t: */
	w = y + val_hi;
	val_lo += (y - w) + val_hi;
	val_hi = w;

	return val_lo + val_hi;
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_log2(q));
}
int main(void) { (void) slice(); return 0; }
