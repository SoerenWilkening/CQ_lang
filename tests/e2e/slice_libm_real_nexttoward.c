/* slice_libm_real_nexttoward.c — bd 3c6m.58: the REAL openlibm nexttoward body
 * (ld80/s_nexttoward.c, fdlibm/OpenBSD-derived, BSD-licensed) — census cell
 * nexttoward.f64.
 *
 * A MIXED-WIDTH cell, and the only one in this sweep: C11 §7.12.11 fixes
 * nexttoward's second argument at `long double` for every width, so the body
 * walks an f64 value ±1 ulp while comparing DIRECTION against an x86_fp80 y.
 * It therefore drives BOTH word-access idioms in one function — the f64
 * EXTRACT_WORDS/INSERT_WORDS memcpy shim on x, and the openbsd
 * ieee_extended_shape_type GET_LDOUBLE_WORDS union on y (3c6m.51
 * promoteFp80Union) — plus the cross-width `(long double)x == y` compare and
 * the hand-aligned exponent/mantissa comparison ladder
 * (`((ix>>20)&0x7ff) > iy-0x3c00`, `((hx<<11)|(lx>>21)) > (hy&0x7fffffff)`)
 * that re-normalizes f64 fields to fp80 field positions. The volatile
 * underflow-raise locals are the bd zco4 Inc 1 promoteVolatileScalarLocals
 * shape, block-scoped inside their arms.
 *
 * This slice is the LINK-layer proof (Rule 2) that every emitted symbol across
 * BOTH widths resolves and the trace is stable.
 *
 * GOLDEN-FRAGILITY NOTE (bd 3c6m.58 audit; NOT a miscompile). This is the only
 * one of the 15 sweep slices whose lowered module contains a real LLVM `undef`:
 * clang -O1's OWN stage-1 output emits `select i1 %c, double undef, double %v`
 * for the x==y / NaN early-exit merge, which lowers to
 * `call i32 @cqrt_alloc_f64(double undef)` — recorded in the golden as the
 * second `cqrt_alloc_f64` on that merge, which since bd `ni15` reads
 * `0x1.100000002p-1038` (it read `0.000000` while the runtime printed %f).
 * That value is register residue, not a value the program computes. It is
 * SOUND: the undef arm is the dead edge of clang's own select, and the merge
 * consumes the rail only under the complementary flag, so it never reaches the
 * measured register (independently verified). But because the byte is not
 * determined by program semantics, a future clang or libc change could shift it
 * and produce a SPURIOUS golden-diff failure here. If this test ever fails on
 * that single line with everything else identical, suspect the toolchain, not
 * the pass.
 *
 * ni15 SHARPENED THIS, deliberately. Under %f the golden asserted only that the
 * residue rounds to `0.000000` — i.e. that it lands anywhere below 5e-7 — so the
 * fragility was masked by a wide tolerance rather than absent. The hex-float
 * label pins the residue exactly, which is the correct trade: the same tolerance
 * that hid this byte is what hid a real 0x1p-128 -> +0.0 miscompile elsewhere in
 * this corpus. Measured after the change: 20 runs of one binary and 5 independent
 * full-pipeline rebuilds all produce a byte-identical trace, so it is stable for
 * a pinned LLVM 19 toolchain.
 *
 * The probe pins the census cell: x = theta-tainted f64, y = 0.5L (classical
 * long double — the census `ldbl` arg kind), so the y-side word extract and NaN
 * guard const-fold exactly as in the census IR.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed — the `volatile` qualifiers are load-bearing and kept VERBATIM):
 * includes and license deleted (ld80/s_nexttoward.c carries no OLM_ macro — its
 * entry is a bare `double nexttoward(...)`); the entry renamed `olm_nexttoward`
 * and marked `__attribute__((always_inline)) static inline`; the vendored
 * math_private closure inlined (f64 word macros as the __builtin_memcpy idiom;
 * the ieee_extended_shape_type union + GET_LDOUBLE_WORDS verbatim from
 * src/math_private_openbsd.h — ld80 access is NEVER memcpy-shimmed, per the
 * 3c6m.51 convention; u_int32_t typedef).
 */
#include <stdint.h>

typedef unsigned int u_int32_t;

/* math_private.h f64 word macros expanded to the __builtin_memcpy idiom clang
   -O1 folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define INSERT_WORDS(d,hi,lo)  do{ uint64_t __w=((uint64_t)(uint32_t)(hi)<<32)|(uint32_t)(lo); __builtin_memcpy(&(d),&__w,8); }while(0)

/* src/math_private_openbsd.h — the LP64 little-endian ld80 word union +
   GET_LDOUBLE_WORDS (verbatim; x86-64 is always little-endian). */
typedef union
{
  long double value;
  struct {
    u_int32_t lsw;
    u_int32_t msw;
    int exp:16;
    int padl:16;
    int padh:32;
  } parts;
} ieee_extended_shape_type;

#define GET_LDOUBLE_WORDS(se,ix0,ix1,d)				\
do {								\
  ieee_extended_shape_type ew_u;				\
  ew_u.value = (d);						\
  (se) = ew_u.parts.exp;					\
  (ix0) = ew_u.parts.msw;					\
  (ix1) = ew_u.parts.lsw;					\
} while (0)

__attribute__((always_inline)) static inline double olm_nexttoward(double x, long double y)
{
	int32_t hx,ix,iy;
	u_int32_t lx,hy,ly,esy;

	EXTRACT_WORDS(hx,lx,x);
	GET_LDOUBLE_WORDS(esy,hy,ly,y);
	ix = hx&0x7fffffff;		/* |x| */
	iy = esy&0x7fff;		/* |y| */

	if(((ix>=0x7ff00000)&&((ix-0x7ff00000)|lx)!=0) ||   /* x is nan */
	   ((iy>=0x7fff)&&(hy|ly)!=0))		/* y is nan */
	   return x+y;
	if((long double) x==y) return y;	/* x=y, return y */
	if((ix|lx)==0) {			/* x == 0 */
	    volatile double u;
	    INSERT_WORDS(x,(esy&0x8000)<<16,1); /* return +-minsub */
	    u = x;
	    u = u * u;				/* raise underflow flag */
	    return x;
	}
	if(hx>=0) {				/* x > 0 */
	    if (esy>=0x8000||((ix>>20)&0x7ff)>iy-0x3c00
		|| (((ix>>20)&0x7ff)==iy-0x3c00
		    && (((hx<<11)|(lx>>21))>(hy&0x7fffffff)
			|| (((hx<<11)|(lx>>21))==(hy&0x7fffffff)
			    && (lx<<11)>ly)))) {	/* x > y, x -= ulp */
		if(lx==0) hx -= 1;
		lx -= 1;
	    } else {				/* x < y, x += ulp */
		lx += 1;
		if(lx==0) hx += 1;
	    }
	} else {				/* x < 0 */
	    if (esy<0x8000||((ix>>20)&0x7ff)>iy-0x3c00
		|| (((ix>>20)&0x7ff)==iy-0x3c00
		    && (((hx<<11)|(lx>>21))>(hy&0x7fffffff)
			|| (((hx<<11)|(lx>>21))==(hy&0x7fffffff)
			    && (lx<<11)>ly))))	{/* x < y, x -= ulp */
		if(lx==0) hx -= 1;
		lx -= 1;
	    } else {				/* x > y, x += ulp */
		lx += 1;
		if(lx==0) hx += 1;
	    }
	}
	hy = hx&0x7ff00000;
	if(hy>=0x7ff00000) {
	  x = x+x;	/* overflow  */
	  return x;
	}
	if(hy<0x00100000) {
	    volatile double u = x*x;		/* underflow */
	    if(u==x) {
		INSERT_WORDS(x,hx,lx);
		return x;
	    }
	}
	INSERT_WORDS(x,hx,lx);
	return x;
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_nexttoward(q, 0.5L));
}
int main(void) { (void) slice(); return 0; }
