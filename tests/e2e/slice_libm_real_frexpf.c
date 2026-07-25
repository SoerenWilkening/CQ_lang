/* slice_libm_real_frexpf.c — bd 3c6m.58: the REAL openlibm frexpf body
 * (src/s_frexpf.c, fdlibm-derived, BSD-licensed) over f32 — census cell frexpf.f32.
 *
 * f32 sibling of frexp.f64, at width 32 with the single-word GET/SET_FLOAT_WORD
 * idiom and the two25 subnormal scale (vs f64's two54). Note the f32
 * zero/inf/nan guard is a single `ix==0` test — there is no low word to OR in.
 *
 * The probe pins the census cell EXACTLY as wprobe.make_src builds it:
 * `int outp; r = frexpf(q, &outp); return measure(r)` — the out-param is
 * declared and passed but NEVER READ. See the frexp.f64 sibling header for the
 * measured scope caveat this implies: the dead `outp` means clang -O1 DCEs every
 * `*eptr` store before cq-lowering runs, so this golden verifies the MANTISSA
 * half only (zero store/Shadow/QRAM activity in the trace), which is the census
 * cell's true content.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed): includes, license and OLM_ macros deleted; the entry renamed
 * `olm_frexpf` and marked `__attribute__((always_inline)) static inline`;
 * math_private.h word macros expanded to the __builtin_memcpy idiom.
 */
#include <stdint.h>

/* math_private.h word macros expanded to the __builtin_memcpy idiom clang -O1
   folds to the same bitcast/shift IR the taint pass lowers. */
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
#define SET_FLOAT_WORD(d,i)    do{ uint32_t __w=(uint32_t)(i); __builtin_memcpy(&(d),&__w,4); }while(0)

static const float
two25 =  3.3554432000e+07; /* 0x4c000000 */

__attribute__((always_inline)) static inline float olm_frexpf(float x, int *eptr)
{
	int32_t hx,ix;
	GET_FLOAT_WORD(hx,x);
	ix = 0x7fffffff&hx;
	*eptr = 0;
	if(ix>=0x7f800000||(ix==0)) return x;	/* 0,inf,nan */
	if (ix<0x00800000) {		/* subnormal */
	    x *= two25;
	    GET_FLOAT_WORD(hx,x);
	    ix = hx&0x7fffffff;
	    *eptr = -25;
	}
	*eptr += (ix>>23)-126;
	hx = (hx&0x807fffff)|0x3f000000;
	SET_FLOAT_WORD(x,hx);
	return x;
}

float slice(void) {
    int e;
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_frexpf(q, &e));
}
int main(void) { (void) slice(); return 0; }
