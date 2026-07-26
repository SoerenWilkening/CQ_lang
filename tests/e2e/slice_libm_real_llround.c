/* slice_libm_real_llround.c — bd 3c6m.53, keep-route corrected by bd tkju: the
   REAL openlibm llround body (src/s_llround.c = the src/s_lround.c template
   re-instantiated with dtype=long long, type=double, roundit=round; fdlibm-
   derived, BSD-licensed), census cell llround.f64. INRANGE() is compile-time
   TRUE for that instantiation exactly as for lround, so the whole function is
   llround(x) = (long long)round(x) — no fenv path; that test is folded BY HAND
   in the body below (argument in its comment). llround itself is a LIBRARY
   function and stays vendored as SOURCE (Rule 18).

   KEEP-SET CALL (Rule 18 ship-floor fold, NOT a body substitution): `round` is
   a HARDWARE KEEP. At the real ship floor (plain clang -O1, builtins ON) the
   named call folds to @llvm.round.f64 before codegen and cq-lowering rewrites
   that to cq_template_round_f64; `__builtin_round` emits exactly that construct
   and needs no libm declaration. A keep has no injectable body, so the software
   s_round.c / s_floor.c ladders this slice used to carry (copied from
   slice_libm_real_lround.c) modelled a program the ship floor never compiles —
   deleted (bd tkju). (<stdint.h> is now vestigial: nothing in the surviving
   text uses a fixed-width type.)

   WHAT IT PROVES (measured on the committed golden): the 5-line trace
   cqrt_alloc_f64 · cqrt_ry_f64 · cq_template_round_f64 ·
   cq_template_fptosi_f64_to_i64 · cqrt_measure_i64 — the keep route plus the
   trailing narrowing, LINK-layer (Rule 2). It proves strictly LESS than before,
   and deliberately so: the vendored ladders were the only tainted control flow
   in the slice, so the trace drops 1564 → 5 lines (cqrt_free 364 → 0,
   cqrt_toffoli 350 → 0, cqrt_alloc_i1 175 → 0, cqrt_alloc_f64 13 → 1) and this
   slice no longer exercises PredMux at all. Its remaining distinction from the
   lround.f64 sibling is the dtype=long long instantiation of INRANGE. */
#include <stdint.h>
__attribute__((always_inline)) static inline long long olm_llround(double x) {
    /* openlibm s_llround.c = s_lround.c with dtype=long long. INRANGE(x)
       short-circuits to compile-time TRUE for the double/long-long
       instantiation (dtype_max - DTYPE_MAX == 0.0 != 0.5), so the
       feraiseexcept/saturate branch is dead: llround(x) = (long long)round(x),
       round + fptosi only. */
    return (long long)__builtin_round(x);
}

long long slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_llround(q));
}
int main(void) { (void) slice(); return 0; }
