/* slice_libm_real_nexttowardf.c — bd 3c6m.67: the REAL openlibm nexttowardf body
 * (src/s_nexttowardf.c, fdlibm/FreeBSD-derived, BSD-licensed) — census cell
 * nexttowardf.f32.
 *
 * *** THIS IS THE BODY openlibm ACTUALLY BUILDS, AND THE DIFFERENCE IS NOT
 * COSMETIC. *** Its `ld80/` namesake is excluded from openlibm's build
 * (`CMakeLists.txt:309` names `src/`), and the two differ in a way that already
 * cost this campaign a retracted `+1`: `ld80/s_nexttowardf.c:63` declares
 * `volatile float u = x*x;` and NEVER READS IT — the write-only fenv idiom bd
 * k710 built `eraseDeadVolatileScalarStores` around, scoring the cell COMPILES.
 * The SHIPPED body below READS its volatile scalar (`t = x*x; if(t==x) …`), so
 * that path is never reached here and the k710 credit was withdrawn (bd
 * 3c6m.63). *** THE FENV RULING AND `eraseDeadVolatileScalarStores` ARE
 * UNAFFECTED *** — they keep their lit coverage, and
 * `slice_libm_ld80_nexttowardf.c` remains their e2e witness. What was withdrawn
 * was the coverage CREDIT, not the capability. This slice re-earns the cell on a
 * different mechanism entirely.
 *
 * THAT MECHANISM. The ulp-direction test at src/s_nexttowardf.c:45, line 63 below:
 *
 *     if((hx>=0) ^ (x < y))
 *
 * — an `xor i1` of an `icmp` on the extracted word and an `fcmp` on the f32
 * value. This cell is the one that declined FLAT rather than nested
 * ("control flow under quantum control" at :45:5) because the `^` diamond IS the
 * outermost region here, with PredMux never invoked at all (0 leaves). *** THAT
 * IS AN ARTIFACT OF POSITION, NOT A SECOND PROBLEM: *** same construct as its
 * three siblings, different bucket only because nothing encloses it. Reading the
 * bucket split as two distinct blockers would have been a scoping error, and the
 * shared fix — admitting the two-operand xor to the condition-tree grammar (bd
 * 3c6m.67) — clears all four.
 *
 * The probe pins the census cell: x = theta-tainted f32, y = 0.5L (classical
 * long double, the spec's second-argument type), so the y-side union read and
 * NaN guard const-fold exactly as in the census IR.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed — the `volatile float t` underflow-raise local is load-bearing and kept
 * VERBATIM, as is the `#ifdef OLM_LONG_DOUBLE` body's use of LDBL_INFNAN_EXP):
 * includes, license, OLM_DLLEXPORT and the OLM_LONG_DOUBLE guard deleted; the
 * entry renamed `olm_nexttowardf` and marked `__attribute__((always_inline))
 * static inline`; math_private.h's GET/SET_FLOAT_WORD expanded to the
 * __builtin_memcpy idiom; `union IEEEl2bits` + LDBL_NBIT inlined VERBATIM from
 * src/amd64_fpmath.h, and LDBL_INFNAN_EXP kept as openlibm spells it
 * (src/s_nexttowardf.c:21, `LDBL_MAX_EXP * 2 - 1` = 0x7fff).
 */
#include <float.h>
#include <stdint.h>

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)

/* src/amd64_fpmath.h — verbatim (x86-64 long double = x86_fp80). */
union IEEEl2bits {
	long double	e;
	struct {
		unsigned int	manl	:32;
		unsigned int	manh	:32;
		unsigned int	exp	:15;
		unsigned int	sign	:1;
		unsigned int	junkl	:16;
		unsigned int	junkh	:32;
	} bits;
	struct {
		unsigned long	man	:64;
		unsigned int	expsign	:16;
		unsigned long	junk	:48;
	} xbits;
};

#define	LDBL_NBIT	0x80000000
#define	LDBL_INFNAN_EXP	(LDBL_MAX_EXP * 2 - 1)

__attribute__((always_inline)) static inline float olm_nexttowardf(float x, long double y)
{
	union IEEEl2bits uy;
	volatile float t;
	int32_t hx,ix;

	GET_FLOAT_WORD(hx,x);
	ix = hx&0x7fffffff;		/* |x| */
	uy.e = y;

	if((ix>0x7f800000) ||
	   (uy.bits.exp == LDBL_INFNAN_EXP &&
	    ((uy.bits.manh&~LDBL_NBIT)|uy.bits.manl) != 0))
	   return x+y;	/* x or y is nan */
	if(x==y) return (float)y;		/* x=y, return y */
	if(ix==0) {				/* x == 0 */
	    SET_FLOAT_WORD(x,(uy.bits.sign<<31)|1);/* return +-minsubnormal */
	    t = x*x;
	    if(t==x) return t; else return x;	/* raise underflow flag */
	}
	if((hx>=0) ^ (x < y))			/* x -= ulp */
	    hx -= 1;
	else					/* x += ulp */
	    hx += 1;
	ix = hx&0x7f800000;
	if(ix>=0x7f800000) return x+x;	/* overflow  */
	if(ix<0x00800000) {		/* underflow */
	    t = x*x;
	    if(t!=x) {		/* raise underflow flag */
	        SET_FLOAT_WORD(x,hx);
		return x;
	    }
	}
	SET_FLOAT_WORD(x,hx);
	return x;
}

float slice(void) {
    float q = 0.5f; cq_theta(&q, 0.5);
    return cq_measure(olm_nexttowardf(q, 0.5L));
}
int main(void) { (void) slice(); return 0; }
