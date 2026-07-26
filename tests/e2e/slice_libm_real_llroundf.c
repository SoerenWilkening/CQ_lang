/* slice_libm_real_llroundf.c — bd 3c6m.53, keep-route corrected by bd tkju: the
   REAL openlibm llroundf body (src/s_llroundf.c = the src/s_lround.c template at
   the float/long-long instantiation; fdlibm-derived, BSD-licensed), census cell
   llroundf.f32 — float in, long long out. INRANGE() is compile-time TRUE there
   (dtype_max = (float)(LLONG_MAX + 0.5) rounds to 2^63 and (float)LLONG_MAX also
   rounds to 2^63, so dtype_max - LLONG_MAX == 0.0 != 0.5 -> the || short-circuits),
   so the feraiseexcept/saturate branch is dead and the whole function is
   llroundf(x) = (long long)roundf(x) — verified by inlining the real corpus (no
   fcmp range compare, no feraiseexcept). That test is folded BY HAND in the body
   below (the lroundf/lroundl siblings instead vendor the INRANGE macro verbatim
   and let clang fold it). llroundf itself is a LIBRARY function and stays
   vendored as SOURCE (Rule 18).

   KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution): `roundf` is
   a HARDWARE KEEP. At the real ship floor (plain clang -O1, builtins ON) the
   named call folds to @llvm.round.f32 before codegen and cq-lowering rewrites
   that to cq_template_round_f32; `__builtin_roundf` emits exactly that
   construct. A keep has no injectable body, so the software s_roundf.c /
   s_floorf.c ladders this slice used to vendor (with the fabs/copysign bit-op
   shims feeding them) modelled a program the ship floor never compiles —
   deleted (bd tkju). (<stdint.h> is now vestigial: nothing in the surviving
   text uses a fixed-width type.)

   WHAT IT PROVES (measured on the committed golden): the 5-line trace
   cqrt_alloc_f32 · cqrt_ry_f32 · cq_template_round_f32 ·
   cq_template_fptosi_f32_to_i64 · cqrt_measure_i64 — the keep route plus the
   float→long-long narrowing, LINK-layer (Rule 2). It proves strictly LESS than
   before, and deliberately so: the deleted ladders were the only tainted control
   flow here, so the trace drops 625 → 5 lines (cqrt_free 132 → 0,
   cqrt_toffoli 124 → 0, cqrt_alloc_i1 62 → 0, cqrt_alloc_f32 20 → 1), the one
   pre-existing keep template (cq_template_fabs_f32, from the vendored roundf's
   __builtin_isfinite) is gone, and this slice no longer exercises PredMux. */
#include <stdint.h>

/* s_llroundf.c -> s_lround.c (float / long long instantiation): INRANGE()
   compile-time TRUE, so the body reduces to (long long)roundf(x). */
static long long olm_llroundf(float x)
{
	return (long long)__builtin_roundf(x);
}

long long slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure(olm_llroundf(q));
}
int main(void) { (void) slice(); return 0; }
