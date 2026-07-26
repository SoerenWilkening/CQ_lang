/* CQ_lang e2e verification slice — census cell lroundf.f32 (bd 3c6m.53),
 * keep-route corrected by bd tkju.
 * Vendored REAL openlibm bodies (the whole remaining closure):
 *   src/s_lroundf.c  (public entry, via s_lround.c parametric body)
 *   src/s_lround.c   (parametric lround: INRANGE + roundit + cast)
 * Faithful copy: only the mechanical olm_ vendoring edits per bd 3c6m.53, plus
 * the bd tkju keep respelling below. No constant/branch/expression changed.
 *
 * KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution): `roundf` is
 * a HARDWARE KEEP — at the real ship floor (plain clang -O1, builtins ON) the
 * named call folds to @llvm.round.f32 before codegen and cq-lowering rewrites
 * that to cq_template_round_f32, which is exactly what `__builtin_roundf`
 * emits. A keep has no injectable body, so the software s_roundf.c / s_floorf.c
 * ladders (and the fabs/copysign bit-op shims that fed them) modelled a program
 * the ship floor never compiles — deleted (bd tkju). lroundf itself is a
 * LIBRARY function and stays vendored as SOURCE; <limits.h>/<fenv.h> are still
 * needed to compile it (LONG_MIN/LONG_MAX and the feraiseexcept declaration,
 * whose arm INRANGE folds dead), while <stdint.h> is now vestigial.
 *
 * WHAT IT PROVES (measured on the committed golden): the 5-line trace
 * cqrt_alloc_f32 · cqrt_ry_f32 · cq_template_round_f32 ·
 * cq_template_fptosi_f32_to_i64 · cqrt_measure_i64 — the keep route plus the
 * float→long narrowing, LINK-layer (Rule 2). It proves strictly LESS than
 * before, and deliberately so: the deleted ladders were the only tainted
 * control flow here, so the trace drops 625 → 5 lines (cqrt_free 132 → 0,
 * cqrt_toffoli 124 → 0, cqrt_alloc_i1 62 → 0, cqrt_alloc_f32 20 → 1), the one
 * pre-existing keep template (cq_template_fabs_f32, from the vendored roundf's
 * __builtin_isfinite) is gone, and this slice no longer exercises PredMux.
 */
#include <stdint.h>
#include <limits.h>
#include <fenv.h>
/* ---- vendored from src/s_lround.c (parametric) with s_lroundf.c params:
   type=float, roundit=roundf, dtype=long, DTYPE_MIN=LONG_MIN,
   DTYPE_MAX=LONG_MAX, fn=lroundf ---- */
static const float dtype_min = LONG_MIN - 0.5;
static const float dtype_max = LONG_MAX + 0.5;
#define	INRANGE(x)	(dtype_max - LONG_MAX != 0.5 || \
			 ((x) > dtype_min && (x) < dtype_max))

static long
olm_lroundf(float x)
{

	if (INRANGE(x)) {
		x = __builtin_roundf(x);
		return ((long)x);
	} else {
		feraiseexcept(FE_INVALID);
		return (LONG_MAX);
	}
}

long slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure(olm_lroundf(q));
}
int main(void) { (void) slice(); return 0; }
