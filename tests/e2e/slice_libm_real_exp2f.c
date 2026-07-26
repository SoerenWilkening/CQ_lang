/* CQ_lang e2e verification slice — census cell exp2f.f32 (bd 3c6m.53)
   Vendors the REAL openlibm exp2f body from src/s_exp2f.c (self-contained —
   s_exp2f.c calls no libm helper, so nothing else is vendored).
   arg0 tainted (cq_theta); real-source injection per Rule 18.

   KEEP-SET (Rule 18 ship-floor fold, NOT a body substitution; bd tkju): the
   unreferenced fabs/copysign shim helpers this file used to carry are deleted
   — both are HARDWARE KEEPS with no injectable body, so a vendored software
   shim models a program the ship floor never compiles. They were dead text
   here and the golden is BYTE-IDENTICAL across the deletion (measured). The
   keep constructs the pass actually sees are clang's own at plain -O1: the
   `hx & 0x7fffffff` sign-mask test folds to 1 @llvm.fabs.f32, and fp-contract
   fuses 4 @llvm.fmuladd.f64 (the polynomial is evaluated in double) — lowered
   1:1 to the golden's 1 cq_template_fabs_f32 + 4 cq_template_fma_f64* calls. */
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
/* On x86-64 SSE, FLT_EVAL_METHOD==0, so openlibm's STRICT_ASSIGN is the plain
   assignment (no volatile temp) — this is the target-faithful expansion. */
#define STRICT_ASSIGN(type, lval, rval) ((lval) = (rval))
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)
#define	TBLBITS	4
#define	TBLSIZE	(1 << TBLBITS)

static const float
    huge    = 0x1p100f,
    redux   = 0x1.8p23f / TBLSIZE,
    P1	    = 0x1.62e430p-1f,
    P2	    = 0x1.ebfbe0p-3f,
    P3	    = 0x1.c6b348p-5f,
    P4	    = 0x1.3b2c9cp-7f;

static volatile float twom100 = 0x1p-100f;

static const double exp2ft[TBLSIZE] = {
	0x1.6a09e667f3bcdp-1,
	0x1.7a11473eb0187p-1,
	0x1.8ace5422aa0dbp-1,
	0x1.9c49182a3f090p-1,
	0x1.ae89f995ad3adp-1,
	0x1.c199bdd85529cp-1,
	0x1.d5818dcfba487p-1,
	0x1.ea4afa2a490dap-1,
	0x1.0000000000000p+0,
	0x1.0b5586cf9890fp+0,
	0x1.172b83c7d517bp+0,
	0x1.2387a6e756238p+0,
	0x1.306fe0a31b715p+0,
	0x1.3dea64c123422p+0,
	0x1.4bfdad5362a27p+0,
	0x1.5ab07dd485429p+0,
};

static float
olm_exp2f(float x)
{
	double tv, twopk, u, z;
	float t;
	u_int32_t hx, ix, i0;
	int32_t k;

	/* Filter out exceptional cases. */
	GET_FLOAT_WORD(hx, x);
	ix = hx & 0x7fffffff;		/* high word of |x| */
	if(ix >= 0x43000000) {			/* |x| >= 128 */
		if(ix >= 0x7f800000) {
			if ((ix & 0x7fffff) != 0 || (hx & 0x80000000) == 0)
				return (x + x);	/* x is NaN or +Inf */
			else
				return (0.0);	/* x is -Inf */
		}
		if(x >= 0x1.0p7f)
			return (huge * huge);	/* overflow */
		if(x <= -0x1.2cp7f)
			return (twom100 * twom100); /* underflow */
	} else if (ix <= 0x33000000) {		/* |x| <= 0x1p-25 */
		return (1.0f + x);
	}

	/* Reduce x, computing z, i0, and k. */
	STRICT_ASSIGN(float, t, x + redux);
	GET_FLOAT_WORD(i0, t);
	i0 += TBLSIZE / 2;
	k = (i0 >> TBLBITS) << 20;
	i0 &= TBLSIZE - 1;
	t -= redux;
	z = x - t;
	INSERT_WORDS(twopk, 0x3ff00000 + k, 0);

	/* Compute r = exp2(y) = exp2ft[i0] * p(z). */
	tv = exp2ft[i0];
	u = tv * z;
	tv = tv + u * (P1 + z * P2) + u * (z * z) * (P3 + z * P4);

	/* Scale by 2**(k>>20). */
	return (tv * twopk);
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_exp2f(q));
}
int main(void) { (void) slice(); return 0; }
