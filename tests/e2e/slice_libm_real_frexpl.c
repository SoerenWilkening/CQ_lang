/* slice_libm_real_frexpl.c — bd 3c6m.58: the REAL openlibm frexpl body
 * (src/s_frexpl.c, FreeBSD-derived, BSD-licensed) over x86_fp80 `long double`
 * — census cell frexpl.f80.
 *
 * Unlike the f64/f32 siblings (which extract words via the memcpy shim), the
 * ld80 body drives the `union IEEEl2bits` bit-pattern union directly, BOTH as a
 * read (`u.bits.exp`, `u.bits.manl|u.bits.manh`) and as a WRITE-BACK
 * (`u.bits.exp = 0x3ffe` field insert, then `return u.e`) — the multi-block
 * promoteFp80Union RMW shape (bd 3c6m.51), here under a 3-way `switch` on the
 * tainted exponent field (0 / 0x7fff / default) which the tainted-switch
 * substrate (Phase 4.5) routes. This slice is the LINK-layer proof (Rule 2)
 * that the emitted i80/f80 symbols resolve and the trace is stable.
 *
 * The probe pins the census cell EXACTLY as wprobe.make_src builds it:
 * `int outp; r = frexpl(q, &outp); return measure(r)` — the out-param is
 * declared and passed but NEVER READ, so clang -O1 DCEs the `*ex` stores before
 * cq-lowering runs and this golden verifies the MANTISSA half only. See the
 * frexp.f64 sibling header for the full measured scope caveat.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed): includes, license, OLM_ macros and the LDBL_MAX_EXP #error guard
 * deleted; the entry renamed `olm_frexpl` and marked
 * `__attribute__((always_inline)) static inline`; union IEEEl2bits kept VERBATIM
 * from src/amd64_fpmath.h (BOTH views — the promoteFp80Union pass owns them, and
 * a memcpy word shim is NEVER used at ld80, per the 3c6m.51 convention).
 */
#include <stdint.h>

/* src/amd64_fpmath.h — union IEEEl2bits (verbatim, both views). */
union IEEEl2bits {
    long double e;
    struct {
        unsigned int manl : 32;
        unsigned int manh : 32;
        unsigned int exp  : 15;
        unsigned int sign : 1;
        unsigned int junkl : 16;
        unsigned int junkh : 32;
    } bits;
    struct {
        unsigned long man : 64;
        unsigned int expsign : 16;
        unsigned long junk : 48;
    } xbits;
};

__attribute__((always_inline)) static inline long double olm_frexpl(long double x, int *ex)
{
	union IEEEl2bits u;

	u.e = x;
	switch (u.bits.exp) {
	case 0:		/* 0 or subnormal */
		if ((u.bits.manl | u.bits.manh) == 0) {
			*ex = 0;
		} else {
			u.e *= 0x1.0p514;
			*ex = u.bits.exp - 0x4200;
			u.bits.exp = 0x3ffe;
		}
		break;
	case 0x7fff:	/* infinity or NaN; value of *ex is unspecified */
		break;
	default:	/* normal */
		*ex = u.bits.exp - 0x3ffe;
		u.bits.exp = 0x3ffe;
		break;
	}
	return (u.e);
}

long double slice(void) {
    int e;
    long double q = 0.5L; cq_theta(&q, 0.5);
    return cq_measure(olm_frexpl(q, &e));
}
int main(void) { (void) slice(); return 0; }
