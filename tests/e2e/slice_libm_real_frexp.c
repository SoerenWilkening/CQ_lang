/* slice_libm_real_frexp.c — bd 3c6m.58: the REAL openlibm frexp body
 * (src/s_frexp.c, fdlibm-derived, BSD-licensed) over f64 — census cell frexp.f64.
 *
 * This is a BY-REF cell (Rule 18 lists frexp among the "by-ref frexp/modf/remquo"
 * library functions that decline WITHOUT injection). The probe pins the census
 * cell EXACTLY as wprobe.make_src builds it: `int outp; r = frexp(q, &outp);
 * return measure(r)` — the out-param is declared and passed but NEVER READ.
 *
 * SCOPE HONESTY (measured, not assumed — bd 3c6m.58): because `outp` is dead,
 * clang -O1 DCEs all three `*eptr` stores (`*eptr = 0`, the subnormal
 * `*eptr = -54`, and the `*eptr += (ix>>20)-1022` RMW) before cq-lowering ever
 * runs. The lowered trace contains ZERO store/Shadow/QRAM activity — so this
 * golden verifies the MANTISSA half of frexp (the return-value dataflow: word
 * extract, the tainted zero/inf/nan and subnormal dispatch flattened onto the
 * select substrate, the exponent-field rewrite and SET_HIGH_WORD repack) and
 * NOT the by-ref exponent output. It is the census cell's true content, and the
 * same caveat applies to the already-verified modf.f64 / modff.f32 goldens.
 * Separately MEASURED this session: a live-out-param variant
 * (`measure(r + (double)e)`) ALSO compiles clean at this ship floor (154-line
 * trace), so the dead store is a probe-convention artifact, not a capability gap.
 * But NOTE WHAT THAT VARIANT DOES *NOT* SHOW (measured, bd 3c6m.58 audit): it
 * does NOT reach the Phase-7.5 alloca Shadow ABI either. clang -O1 SROA-promotes
 * the `int e` slot outright — stage-1 IR has ZERO alloca and ZERO store, the
 * exponent becoming `phi i32 [-1076], [-1022]` + `add nsw` + `sitofp` — so the
 * live variant lowers onto the register/select control-merge substrate
 * (cqrt_copy_i32_controlled / cq_template_add_i32 / cq_template_sitofp_i32_to_f64)
 * with zero cqrt_qram_* symbols. NO golden in the frexp/modf family gives the
 * Shadow ABI e2e coverage; making one do so would need an alloca that SURVIVES
 * SROA. Do not cite these cells as Shadow-path evidence.
 *
 * The f64 word macros are SROA-promoted by clang -O1 to register bitcast/shift form.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed): includes, license, OLM_ macros and weak_reference deleted; the entry
 * renamed `olm_frexp` and marked `__attribute__((always_inline)) static inline`;
 * math_private.h word macros expanded to the __builtin_memcpy idiom (the f32/f64
 * shim convention — ld80 keeps its union instead).
 */
#include <stdint.h>

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define EXTRACT_WORDS(hi,lo,d) do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (hi)=(int32_t)(__w>>32); (lo)=(int32_t)__w; }while(0)
#define GET_HIGH_WORD(i,d)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); (i)=(int32_t)(__w>>32); }while(0)
#define SET_HIGH_WORD(d,v)     do{ uint64_t __w; __builtin_memcpy(&__w,&(d),8); __w=(__w&0x00000000ffffffffULL)|((uint64_t)(uint32_t)(v)<<32); __builtin_memcpy(&(d),&__w,8); }while(0)

static const double
two54 =  1.80143985094819840000e+16; /* 0x43500000, 0x00000000 */

__attribute__((always_inline)) static inline double olm_frexp(double x, int *eptr)
{
	int32_t hx, ix, lx;
	EXTRACT_WORDS(hx,lx,x);
	ix = 0x7fffffff&hx;
	*eptr = 0;
	if(ix>=0x7ff00000||((ix|lx)==0)) return x;	/* 0,inf,nan */
	if (ix<0x00100000) {		/* subnormal */
	    x *= two54;
	    GET_HIGH_WORD(hx,x);
	    ix = hx&0x7fffffff;
	    *eptr = -54;
	}
	*eptr += (ix>>20)-1022;
	hx = (hx&0x800fffff)|0x3fe00000;
	SET_HIGH_WORD(x,hx);
	return x;
}

double slice(void) {
    int e;
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_frexp(q, &e));
}
int main(void) { (void) slice(); return 0; }
