/* slice_libm_real_lround.c — bd 3c6m.14 / L6 Inc 1, keep-route corrected by
   bd tkju: the REAL openlibm lround body (src/s_lround.c at the double/long
   instantiation, fdlibm-derived, BSD-licensed), census cell lround.f64.
   INRANGE() is compile-time TRUE there, so the whole function is
   lround(x) = (long)round(x) — no fenv path; that test is folded BY HAND in the
   body below, with the argument and the corpus-IR confirmation in its comment.
   lround itself is a LIBRARY function and stays vendored as SOURCE (Rule 18).

   KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution): `round` is
   a HARDWARE KEEP. At the real ship floor (plain clang -O1, builtins ON) the
   named call folds to @llvm.round.f64 before codegen and cq-lowering rewrites
   that to cq_template_round_f64; `__builtin_round` emits exactly that construct
   and needs no libm declaration. A keep has no injectable body, so the software
   s_round.c / s_floor.c ladders this slice used to vendor modelled a program the
   ship floor never compiles — deleted (bd tkju). (<stdint.h> is now vestigial:
   nothing in the surviving text uses a fixed-width type.)

   WHAT IT PROVES (measured on the committed golden): the 5-line trace
   cqrt_alloc_f64 · cqrt_ry_f64 · cq_template_round_f64 ·
   cq_template_fptosi_f64_to_i64 · cqrt_measure_i64 — the keep route plus the
   trailing narrowing, LINK-layer (Rule 2). It proves strictly LESS than before,
   and deliberately so: the vendored ladders were the only tainted control flow
   in the slice, so the trace drops 1564 → 5 lines (cqrt_free 364 → 0,
   cqrt_toffoli 350 → 0, cqrt_alloc_i1 175 → 0, cqrt_alloc_f64 13 → 1) and this
   slice no longer exercises PredMux at all. PredMux coverage has to come from
   slices whose census cell really is an injectable library function. */
#include <stdint.h>

__attribute__((always_inline)) static inline long olm_lround(double x) {
    /* openlibm s_lround.c: INRANGE(x) = (dtype_max - DTYPE_MAX != 0.5 ||
       (x > dtype_min && x < dtype_max)). For the double/long instantiation
       the FIRST disjunct is a compile-time constant: dtype_max =
       (double)(LONG_MAX + 0.5) rounds to 2^63 and (double)LONG_MAX also
       rounds to 2^63, so the difference is 0.0 != 0.5 == TRUE and the ||
       short-circuits — INRANGE is compile-time TRUE and the
       feraiseexcept/saturate branch is dead (the openlibm header comment's
       "or TRUE otherwise" case). Empirically confirmed: the census-inlined
       s_lround.c IR (scratchpad ir8/lround_inl.ll) contains no range compare
       and no fenv call — round + fptosi only, exactly this body. */
    return (long)__builtin_round(x);
}

long slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_lround(q));
}
int main(void) { (void) slice(); return 0; }
