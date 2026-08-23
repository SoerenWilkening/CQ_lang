/* slice_libm_real_nextafterl.c — bd 3c6m.67: the REAL openlibm nextafterl body
 * (src/s_nextafterl.c, fdlibm/FreeBSD-derived, BSD-licensed) over x86_fp80
 * `long double` — census cell nextafterl.f80.
 *
 * *** THIS IS THE BODY openlibm ACTUALLY BUILDS. *** Read that together with its
 * sibling `slice_libm_ld80_nextafterl.c`, which vendors the `ld80/` variant:
 * openlibm's own build EXCLUDES the ld80 file on every target
 * (`ld80/Make.files:8-9`; `CMakeLists.txt:174` names `src/`). Until 2026-08-23 the
 * census reached the ld80 body through a basename collision and scored this cell
 * COMPILES on a program that ships nowhere (bd 3c6m.63). The two slices are kept
 * side by side deliberately: the `ld80_` one still proves that real BSD C lowers,
 * links and runs, but only THIS one may COUNT as coverage —
 * `tools/slice_census_sync_check.py` (ctest `e2e-census-slice-sync`) enforces the
 * split, because `probe.py`'s published `verified` number is the glob count of
 * `slice_libm_real_*.expected.log`.
 *
 * WHAT MADE THIS CELL DECLINE, AND WHAT UNBLOCKED IT. The two source families
 * differ in exactly one place — the ulp-direction test. `ld80/` uses an INTEGER
 * WORD LADDER (`ix>iy || ((ix==iy) && (hx>hy || …))`), which ControlDetect has
 * always claimed. `src/` uses an XOR OF TWO COMPARES on the tainted value:
 *
 *     if((x>0.0) ^ (x<y))            <- src/s_nextafterl.c:55, line 62 below
 *
 * which lowers to `xor i1` of two `fcmp`s as a BRANCH CONDITION. Both compare
 * leaves were always in-grammar; the two-operand xor node was not, in either
 * condition-tree recogniser, so PredMux left the region (gate E6-condtree, 16
 * leaves / 0 claims) and ControlDetect then declined the ENCLOSING NaN guard as
 * `nested control flow`. The reported location was therefore :42:29, the guard —
 * never the blocker. bd 3c6m.67 admits the xor node (it emits `cnot(L,G);
 * cnot(Rv,G)` onto a fresh |0> ancilla — the OR node minus its toffoli) and the
 * whole body lowers.
 *
 * `nexttowardl` is THIS function: `openlibm_strong_reference(nextafterl,
 * nexttowardl)` at src/s_nextafterl.c:80, so the two cells share one body and
 * `slice_libm_real_nexttowardl.c` vendors it under the other spelling.
 *
 * The probe pins the census cell: x = theta-tainted, y = 0.5L (classical), so the
 * y-side union read and NaN guard const-fold exactly as in the census IR.
 *
 * Mechanical edits ONLY (libm-real-slice-recipe; NO constant/branch/expression
 * changed — the `volatile long double t` underflow-raise local is load-bearing
 * and kept VERBATIM, as is openlibm's `(ux.bits.manh - 1) | (ux.bits.manh &
 * LDBL_NBIT)` explicit-integer-bit fixup): includes, license, the
 * LDBL_MAX_EXP #error guard, OLM_DLLEXPORT and the strong_reference deleted; the
 * entry renamed `olm_nextafterl` and marked `__attribute__((always_inline))
 * static inline`; `union IEEEl2bits` + LDBL_NBIT + mask_nbit_l inlined VERBATIM
 * from src/amd64_fpmath.h (per the 3c6m.51 ld80 convention the fp80 union is
 * never memcpy-shimmed — promoteFp80Union owns it).
 */
#include <stdint.h>

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
#define	mask_nbit_l(u)	((u).bits.manh &= ~LDBL_NBIT)

__attribute__((always_inline)) static inline long double olm_nextafterl(long double x, long double y)
{
	volatile long double t;
	union IEEEl2bits ux, uy;

	ux.e = x;
	uy.e = y;

	if ((ux.bits.exp == 0x7fff &&
	     ((ux.bits.manh&~LDBL_NBIT)|ux.bits.manl) != 0) ||
	    (uy.bits.exp == 0x7fff &&
	     ((uy.bits.manh&~LDBL_NBIT)|uy.bits.manl) != 0))
	   return x+y;	/* x or y is nan */
	if(x==y) return y;		/* x=y, return y */
	if(x==0.0) {
	    ux.bits.manh = 0;			/* return +-minsubnormal */
	    ux.bits.manl = 1;
	    ux.bits.sign = uy.bits.sign;
	    t = ux.e*ux.e;
	    if(t==ux.e) return t; else return ux.e; /* raise underflow flag */
	}
	if((x>0.0) ^ (x<y)) {			/* x -= ulp */
	    if(ux.bits.manl==0) {
		if ((ux.bits.manh&~LDBL_NBIT)==0)
		    ux.bits.exp -= 1;
		ux.bits.manh = (ux.bits.manh - 1) | (ux.bits.manh & LDBL_NBIT);
	    }
	    ux.bits.manl -= 1;
	} else {				/* x += ulp */
	    ux.bits.manl += 1;
	    if(ux.bits.manl==0) {
		ux.bits.manh = (ux.bits.manh + 1) | (ux.bits.manh & LDBL_NBIT);
		if ((ux.bits.manh&~LDBL_NBIT)==0)
		    ux.bits.exp += 1;
	    }
	}
	if(ux.bits.exp==0x7fff) return x+x;	/* overflow  */
	if(ux.bits.exp==0) {			/* underflow */
	    mask_nbit_l(ux);
	    t = ux.e * ux.e;
	    if(t!=ux.e)			/* raise underflow flag */
		return ux.e;
	}
	return ux.e;
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_nextafterl(q, 0.5L));
}
int main(void) { (void) slice(); return 0; }
