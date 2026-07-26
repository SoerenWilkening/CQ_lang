/* slice_libm_real_lroundl.c — bd 3c6m.58, keep-route corrected by bd tkju: the
   REAL openlibm lroundl body (src/s_lroundl.c → the src/s_lround.c template
   instantiated at type=long double / dtype=long / roundit=roundl;
   fdlibm/FreeBSD-derived, BSD-licensed) over x86_fp80 `long double`. That
   template is the WHOLE vendored closure — lroundl is a LIBRARY function and
   stays vendored as SOURCE (Rule 18); roundl is not (see KEEP-SET below).

   INRANGE() folds to a compile-time TRUE exactly as in the verified lround.f64
   sibling, and for the same reason: `dtype_max = DTYPE_MAX + 0.5` applies the
   USUAL ARITHMETIC CONVERSIONS to `LONG_MAX + 0.5` — long and double, so the
   sum is computed in DOUBLE and rounds to 2^63 before being widened to the
   `static const long double`. `dtype_max - DTYPE_MAX` then widens LONG_MAX
   (2^63-1, exact in fp80's 64-bit significand) and yields 1.0L, so the first
   disjunct `1.0 != 0.5` short-circuits TRUE and the feraiseexcept/saturate arm
   is dead. Confirmed against the census-inlined IR (llvm-dis of
   /private/tmp/bc/s_lroundl.bc: `tail call @roundl` + `fptosi`, no range
   compare, no fenv call) — exactly this body.

   KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution): `roundl` is
   a HARDWARE KEEP. At the real ship floor (plain clang -O1, builtins ON) the
   named call folds to @llvm.round.f80 before codegen and cq-lowering rewrites
   that to cq_template_round_f80; `__builtin_roundl` emits exactly that construct
   and needs no libm declaration. A keep has no injectable body, so the software
   ld80 ladders this slice used to vendor — src/s_roundl.c, ld80/s_floorl.c,
   src/s_isfinite.c __isfinitel and the math_private_openbsd.h /
   amd64_fpmath.h union closure they needed — modelled a program the ship floor
   never compiles; all deleted (bd tkju). Only the s_lround.c template survives,
   and it uses no word union at all, so <stdint.h> is now vestigial.

   Mechanical edits ONLY on what remains (libm-real-slice-recipe; NO
   constant/branch/expression changed): includes, license and OLM_ macros
   deleted (the s_lround.c template carries no weak_reference); the entry marked
   `__attribute__((always_inline)) static inline` and renamed `olm_lroundl`;
   LONG_MIN/LONG_MAX/FE_INVALID supplied locally (see below).

   WHAT IT PROVES (measured on the committed golden): the 5-line trace
   cqrt_alloc_f80 · cqrt_ry_f80 · cq_template_round_f80 ·
   cq_template_fptosi_f80_to_i64 · cqrt_measure_i64 — the fp80 keep route plus
   the `(long)` fptosi narrowing, LINK-layer (Rule 2) that every emitted f80
   symbol resolves and the trace is stable. It proves strictly LESS than before,
   and deliberately so: the deleted ladders were the entire lowered body, so the
   trace drops 4446 → 5 lines (cqrt_free 1052 → 0, cqrt_toffoli 1076 → 0,
   cqrt_alloc_i1 538 → 0, cqrt_alloc_f80 22 → 1). In particular the old claim
   that floorl's word RMW rides the 3c6m.51 promoteFp80Union Shadow store is NO
   LONGER TRUE OF THIS SLICE: it now emits no fp80 union traffic and no i80
   symbols whatsoever, and no longer exercises promoteFp80Union or PredMux —
   that coverage has to come from ld80 slices whose census cell really is an
   injectable library function. */
#include <stdint.h>

/* openlibm s_lround.c instantiated by s_lroundl.c
   (type=long double, roundit=roundl, dtype=long, DTYPE_MAX=LONG_MAX).
   The INRANGE macro is vendored VERBATIM — the compile-time TRUE fold is
   DEMONSTRATED by clang, not asserted by hand (if the fold did not happen the
   live feraiseexcept call would decline loudly as a taint escape, which is
   exactly the signal we want). FE_INVALID = 0x01 per openlibm_fenv_amd64.h. */
#define LONG_MIN  (-0x7fffffffffffffffL - 1L)
#define LONG_MAX  0x7fffffffffffffffL
#define FE_INVALID 0x01
extern int feraiseexcept(int __excepts);

static const long double dtype_min = LONG_MIN - 0.5;
static const long double dtype_max = LONG_MAX + 0.5;
#define	INRANGE(x)	(dtype_max - LONG_MAX != 0.5 || \
			 ((x) > dtype_min && (x) < dtype_max))

__attribute__((always_inline)) static inline long olm_lroundl(long double x)
{

	if (INRANGE(x)) {
		x = __builtin_roundl(x);
		return ((long)x);
	} else {
		feraiseexcept(FE_INVALID);
		return (LONG_MAX);
	}
}

long slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_lroundl(q));
}
int main(void) { (void) slice(); return 0; }
