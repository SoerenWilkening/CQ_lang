/* slice_libm_real_nexttoward.c — bd 3c6m.67: the REAL openlibm nexttoward body
 * (src/s_nexttoward.c, fdlibm/FreeBSD-derived, BSD-licensed) — census cell
 * nexttoward.f64.
 *
 * *** THIS IS THE BODY openlibm ACTUALLY BUILDS. *** Its `ld80/` namesake is
 * EXCLUDED from openlibm's build on every target — `ld80/Make.files` never
 * mentions `s_nexttoward.c`, and `CMakeLists.txt:297` names `src/`. Until
 * 2026-08-23 the census reached the ld80 body through a basename collision and
 * scored this cell COMPILES on a program that ships nowhere (bd 3c6m.63). The
 * sibling `slice_libm_ld80_nexttoward.c` keeps that body as a lowering proof but
 * must NOT count; `tools/slice_census_sync_check.py` (ctest
 * `e2e-census-slice-sync`) enforces the split.
 *
 * A MIXED-WIDTH CELL, which is what makes it worth having beside nextafterl:
 * `nexttoward(double x, long double y)` reads x through the f64 EXTRACT_WORDS
 * memcpy idiom and y through the fp80 `union IEEEl2bits`, so one body exercises
 * BOTH word-access conventions at once (the recipe's f32/f64-memcpy vs
 * ld80-union-verbatim split) and returns f64.
 *
 * WHY IT DECLINED. The ulp-direction test at src/s_nexttoward.c:54, line 68 below:
 *
 *     if((hx>0.0) ^ (x < y))
 *
 * — an `xor i1` whose leaves are an `icmp` on the extracted high word and an
 * `fcmp` on the f64 value, in BRANCH-CONDITION position. Note the mixed leaf
 * kinds: nothing about the xor node cares, because it operates on FLAG rails,
 * which are i1 whatever the leaves compared. Both leaves were always in-grammar;
 * the two-operand xor node was not, so PredMux left the region at gate
 * E6-condtree (7 leaves / 0 claims) and ControlDetect declined the enclosing NaN
 * guard as `nested control flow` at :44:22 — a REPORTED location that was never
 * the blocker. bd 3c6m.67 admits the node and the body lowers.
 *
 * (openlibm writes `hx>0.0` — an int32_t compared against a double literal,
 * which C promotes to `(double)hx > 0.0`. It is kept VERBATIM, oddity and all;
 * changing it to `hx>0` would be an expression change the recipe forbids.)
 *
 * The probe pins the census cell: x = theta-tainted f64, y = 0.5L (classical
 * long double, the spec's second-argument type), so the y-side union read and
 * NaN guard const-fold exactly as in the census IR.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed — the `volatile double t` underflow-raise local is load-bearing and
 * kept VERBATIM): includes, license, the LDBL_MAX_EXP #error guard and
 * OLM_DLLEXPORT deleted; the entry renamed `olm_nexttoward` and marked
 * `__attribute__((always_inline)) static inline`; math_private.h's
 * EXTRACT_WORDS/INSERT_WORDS expanded to the __builtin_memcpy idiom;
 * `union IEEEl2bits` + LDBL_NBIT inlined VERBATIM from src/amd64_fpmath.h.
 */
#include <stdint.h>

typedef uint32_t u_int32_t;

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define INSERT_WORDS(d,hi,lo)  do{ uint64_t __w=((uint64_t)(uint32_t)(hi)<<32)|(uint32_t)(lo); __builtin_memcpy(&(d),&__w,8); }while(0)

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

__attribute__((always_inline)) static inline double olm_nexttoward(double x, long double y)
{
	union IEEEl2bits uy;
	volatile double t;
	int32_t hx,ix;
	u_int32_t lx;

	EXTRACT_WORDS(hx,lx,x);
	ix = hx&0x7fffffff;		/* |x| */
	uy.e = y;

	if(((ix>=0x7ff00000)&&((ix-0x7ff00000)|lx)!=0) ||
	    (uy.bits.exp == 0x7fff &&
	     ((uy.bits.manh&~LDBL_NBIT)|uy.bits.manl) != 0))
	   return x+y;	/* x or y is nan */
	if(x==y) return (double)y;		/* x=y, return y */
	if(x==0.0) {
	    INSERT_WORDS(x,uy.bits.sign<<31,1);	/* return +-minsubnormal */
	    t = x*x;
	    if(t==x) return t; else return x;	/* raise underflow flag */
	}
	if((hx>0.0) ^ (x < y)) {			/* x -= ulp */
	    if(lx==0) hx -= 1;
	    lx -= 1;
	} else {				/* x += ulp */
	    lx += 1;
	    if(lx==0) hx += 1;
	}
	ix = hx&0x7ff00000;
	if(ix>=0x7ff00000) return x+x;	/* overflow  */
	if(ix<0x00100000) {		/* underflow */
	    t = x*x;
	    if(t!=x) {		/* raise underflow flag */
	        INSERT_WORDS(x,hx,lx);
		return x;
	    }
	}
	INSERT_WORDS(x,hx,lx);
	return x;
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_nexttoward(q, 0.5L));
}
int main(void) { (void) slice(); return 0; }
