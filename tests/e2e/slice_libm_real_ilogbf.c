/* CQ_lang e2e verification slice — census cell ilogbf.f32 (bd ww4c.3, Inc 2)
 * Vendors the REAL openlibm body of ilogbf from:
 *   /private/tmp/openlibm/src/s_ilogbf.c  (openlibm @82e90ae)
 * Self-contained (no dependency corpus files). Mechanical edits only:
 * #includes/license/FBSDID stripped; entry renamed to always_inline static
 * inline olm_ilogbf; GET_FLOAT_WORD expanded to the __builtin_memcpy idiom;
 * FP_ILOGB0 / FP_ILOGBNAN / INT_MAX spelled as their openlibm values.
 * NO constant, branch or expression changed — the `for` loop is verbatim.
 *
 * WHAT THIS CELL PROVES (bd ww4c): the single subnormal loop has the same
 * STRUCTURE as ilogb.f64's s_ilogb.c:42 loop — unguarded (clang folds the
 * guard, having proved the entry value positive) with the pre-shift in the
 * preheader — but every constant differs: the pre-shift is `hx<<=8` here
 * against `hx<<=11` there, and the seed is C0 = -126 against C0 = -1022. So
 * the golden pins that the closed form is DERIVED from the loop it rewrites,
 * not hardcoded to one spelling.
 *
 * The enclosing diamonds flatten for the same measured reason as the f64 cell —
 * this return merge has FOUR incomings, so PredMux claims via the no-call-fence
 * `SolePhiIncomings > 2` disjunct and W7's clause (e) is never consulted. See
 * the slice_libm_real_ilogb.c header for the full mechanism.
 *
 * One thing in the trace that is NOT in the source: `cq_template_fabs_f32`.
 * That is stock clang canonicalizing `GET_FLOAT_WORD(hx,x); hx &= 0x7fffffff`
 * into `bitcast(fabs(x))` — a sign-mask identity on the WORD, value-preserving
 * on every input including NaN and -0.0, and the same fold the already-verified
 * slice_libm_real_logb.c records. It is not a body substitution.
 */
#include <stdint.h>
typedef uint32_t u_int32_t;
/* math_private.h word macro expanded to the __builtin_memcpy idiom. */
#define GET_FLOAT_WORD(i,d)    do{ uint32_t __w; __builtin_memcpy(&__w,&(d),4); (i)=(int32_t)__w; }while(0)
/* <limits.h> / openlibm_math.h values, verbatim:
     INT_MAX 2147483647 · FP_ILOGB0 (-INT_MAX) · FP_ILOGBNAN INT_MAX  */
#define INT_MAX      2147483647
#define FP_ILOGB0    (-INT_MAX)
#define FP_ILOGBNAN  INT_MAX

__attribute__((always_inline)) static inline int
olm_ilogbf(float x)
{
	int32_t hx,ix;

	GET_FLOAT_WORD(hx,x);
	hx &= 0x7fffffff;
	if(hx<0x00800000) {
	    if(hx==0)
		return FP_ILOGB0;
	    else			/* subnormal x */
	        for (ix = -126,hx<<=8; hx>0; hx<<=1) ix -=1;
	    return ix;
	}
	else if (hx<0x7f800000) return (hx>>23)-127;
	else if (hx>0x7f800000) return FP_ILOGBNAN;
	else return INT_MAX;
}

int slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure(olm_ilogbf(q));
}
int main(void) { (void) slice(); return 0; }
