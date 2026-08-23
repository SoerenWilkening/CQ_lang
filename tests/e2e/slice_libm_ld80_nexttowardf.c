/* *** NOT A COVERAGE CLAIM — openlibm does NOT build this body (bd 3c6m.63). ***
 *
 * This slice vendors openlibm's `ld80/` variant. openlibm's own build EXCLUDES it
 * on every target: `ld80/Make.files:8-9` comments `s_nextafterl.c` out and never
 * mentions `s_nexttoward.c` / `s_nexttowardf.c`, while `CMakeLists.txt:174/297/309`
 * name `src/` for each. Until 2026-08-23 the census reached these ld80 bodies
 * through a basename collision in the corpus recipe and scored three cells
 * `COMPILES` on a program that ships nowhere.
 *
 * ON THE BODY THAT SHIPS, THIS CELL DECLINES — census cell `nexttowardf.f32` declines at `src/s_nexttowardf.c:45:5`,
 *   `if((hx>=0) ^ (x < y))`: `control flow under quantum control` — the SAME xor-of-two-compares
 *   construct its two siblings die on, declining FLAT here only because it is the outermost
 *   region (PredMux is never invoked on this body). NB the shipped
 *   `src/` body READS its volatile scalar `t`, so the write-only idiom this slice
 *   exists to exercise is NOT present there and bd k710's +1 is RETRACTED. The fenv
 *   ruling and `eraseDeadVolatileScalarStores` are UNAFFECTED — this slice remains
 *   their only e2e witness, which is exactly why it was renamed and not deleted.
 *
 * The slice is KEPT, and renamed out of the `slice_libm_real_*` namespace rather
 * than deleted, because it still proves what its header describes: real
 * BSD-licensed openlibm C that lowers, links, runs and byte-matches. What it must
 * not do is COUNT — `probe.py`'s published `verified` number is the glob count of
 * `slice_libm_real_*.expected.log`, so leaving it there would publish
 * verified > injection-covered. `tools/slice_census_sync_check.py` (ctest
 * `e2e-census-slice-sync`) enforces the split so this cannot drift back silently.
 */
/* slice_libm_ld80_nexttowardf.c — bd k710: the REAL openlibm nexttowardf body
 * (ld80/s_nexttowardf.c, fdlibm/OpenBSD-derived, BSD-licensed) — census cell
 * nexttowardf.f32.
 *
 * THIS SLICE IS THE LINK-LAYER PROOF FOR THE fenv RULING (owner 2026-08-10) and
 * for the stage it licensed, `eraseDeadVolatileScalarStores` (QramLowering.cpp).
 * `opt` exiting 0 is not evidence (Rule 2); this is the only layer that links,
 * runs, and byte-diffs a trace.
 *
 * WHAT MAKES THIS CELL THE ONE THAT NEEDED A RULING. Its final underflow raise is
 *
 *     if(hy<0x00800000) { volatile float u = x*x; }   [line 63 of the vendored body]
 *
 * and `u` is NEVER READ. That single fact separates it from every sibling in the
 * family, all four of which COMPILE without any of this machinery because they
 * read their volatile scalar at BOTH underflow sites and are therefore claimed by
 * the bd zco4 promotion:
 *
 *     nextafter{,f,l}   `t = x*x; if(t!=x) {...}`      — read
 *     nexttoward (f64)  `u = x*x; if(u==x) {...}`      — read   (s_nexttoward.c:145)
 *     nexttowardf       `volatile float u = x*x;`      — WRITE-ONLY  <-- this cell
 *
 * With zero loads neither the etiq const fold (needs loads) nor zco4's promotion
 * (`Loads.empty()` forfeits) can claim the slot, so before the ruling the volatile
 * store reached `declineTaintEscapes` and the whole cell died on
 * `cq taint escape: tainted value stored to memory`.
 *
 * *** WHAT THE GOLDEN ACTUALLY SHOWS, AND IT IS NOT WHAT WAS FIRST CLAIMED: the
 * multiply IS GONE. *** This trace contains ZERO `cq_template_fmul_f32`.
 *
 * The chain is: the k710 stage erases the volatile store, which was the fmul's
 * only consumer; the fmul is then trivially dead; and because it sits inside a
 * tainted-conditional arm, PredMuxFlatten.cpp:2618's pre-existing
 * `RecursivelyDeleteTriviallyDeadInstructions` removes it. That cleanup is not
 * incidental — it exists so a dead TAINTED op does not lower to a forward gate
 * that is never uncomputed and never freed (its own Rule-6/8 reason).
 *
 * That outcome is what "fenv is out of the model" MEANS: an operation whose only
 * purpose is raising a flag has no observable effect, and unobservable dead code
 * is deleted. It is recorded this loudly because the ruling was first requested
 * on a tidier summary — "the implementation keeps the fmul, so nothing the source
 * demanded be evaluated is removed" — which was an artifact of a control-flow-free
 * lit fixture. The owner re-affirmed the ruling on these measured facts.
 *
 * THE CONTRAST THAT MAKES THE FAMILY LEGIBLE, and it is in the committed goldens:
 * `slice_libm_ld80_nexttoward` (f64) and `slice_libm_real_nextafterf` (f32) each
 * carry exactly ONE fmul, because they READ their volatile scalar — live value,
 * untouched by any of this. Only this cell's multiply is dead.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant, branch or
 * expression changed — the `volatile` qualifier is the subject of the test and is
 * kept VERBATIM): includes and license deleted; the entry renamed
 * `olm_nexttowardf` and marked `__attribute__((always_inline)) static inline`;
 * math_private.h's f32 word macros expanded to the __builtin_memcpy idiom; the
 * openbsd ieee_extended_shape_type union + GET_LDOUBLE_WORDS taken verbatim
 * (ld80 word access is NEVER memcpy-shimmed — the 3c6m.51 promoteFp80Union
 * convention), matching slice_libm_ld80_nexttoward.c exactly.
 *
 * The probe pins the census cell: x = theta-tainted f32, y = 0.5L (classical long
 * double — the census `ldbl` arg kind), so the y-side word extract and the NaN
 * guard const-fold exactly as in the census IR.
 */
#include <stdint.h>

typedef unsigned int u_int32_t;

/* math_private.h f32 word macros expanded to the __builtin_memcpy idiom clang
   -O1 folds to the same bitcast/shift IR the taint pass lowers. */
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)

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

__attribute__((always_inline)) static inline float olm_nexttowardf(float x, long double y)
{
	int32_t hx,ix,iy;
	u_int32_t hy,ly,esy;

	GET_FLOAT_WORD(hx,x);
	GET_LDOUBLE_WORDS(esy,hy,ly,y);
	ix = hx&0x7fffffff;		/* |x| */
	iy = esy&0x7fff;		/* |y| */

	if((ix>0x7f800000) ||			/* x is nan */
	   (iy>=0x7fff&&((hy|ly)!=0)))		/* y is nan */
	   return x+y;
	if((long double) x==y) return y;	/* x=y, return y */
	if(ix==0) {				/* x == 0 */
	    volatile float u;
	    SET_FLOAT_WORD(x,((esy&0x8000)<<16)|1);/* return +-minsub*/
	    u = x;
	    u = u * u;				/* raise underflow flag */
	    return x;
	}
	if(hx>=0) {				/* x > 0 */
	    if(esy>=0x8000||((ix>>23)&0xff)>iy-0x3f80
	       || (((ix>>23)&0xff)==iy-0x3f80
		   && ((ix&0x7fffff)<<8)>(hy&0x7fffffff))) {/* x > y, x -= ulp */
		hx -= 1;
	    } else {				/* x < y, x += ulp */
		hx += 1;
	    }
	} else {				/* x < 0 */
	    if(esy<0x8000||((ix>>23)&0xff)>iy-0x3f80
	       || (((ix>>23)&0xff)==iy-0x3f80
		   && ((ix&0x7fffff)<<8)>(hy&0x7fffffff))) {/* x < y, x -= ulp */
		hx -= 1;
	    } else {				/* x > y, x += ulp */
		hx += 1;
	    }
	}
	hy = hx&0x7f800000;
	if(hy>=0x7f800000) {
	  x = x+x;	/* overflow  */
	  return x;
	}
	if(hy<0x00800000) {
	    volatile float u = x*x;		/* underflow */
	}
	SET_FLOAT_WORD(x,hx);
	return x;
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_nexttowardf(q, 0.5L));
}
int main(void) { (void) slice(); return 0; }
