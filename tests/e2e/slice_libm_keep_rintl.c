/* slice_libm_keep_rintl.c — bd 3c6m.56: the long-double `rintl` KEEP path.

   This is a RECOGNITION/INTRINSIC KEEP, not an injection slice. With builtins on
   (the natural user compile) `clang -O1` folds `rintl(x)` to the in-grid IR
   intrinsic `@llvm.rint.f80` — which cq-lowering recognizes (IntrinsicLowering.cpp)
   and lowers to `cq_template_rint_f80`. No openlibm body is injected; there is no
   libcall in the IR the pass sees (the asm-level `callq _rintl` is intercepted as
   the intrinsic BEFORE codegen — the floor.f80 precedent).

   BENNETT-GATED KEEP (owner criterion 2026-07-24, bd 3c6m.56): a libm name is a
   legitimate keep only if (a) clang folds it to an in-grid IR construct CQ
   recognizes before codegen AND (b) Bennett.jl ships a reversible gate sequence
   for that construct. `rint`/`nearbyint` clear BOTH: Bennett's
   `src/softfloat/fround.jl` exports `soft_round` (round-to-nearest-even), which
   under the default FP rounding environment IS `rint`/`nearbyint` — so a real
   Phase-9 backend has a Bennett source. (Contrast `fmod`→`frem`: an in-grid
   OPCODE, but Bennett has NO frem/fmod gate sequence, so it is NOT a keep — see
   bd fmod-frem-keep-2026-07-24 / the frem-inversion follow-up.)

   The census already treats `rint`/`nearbyint`/`trunc` as keeps (base names in the
   probe.py keep-set since 3c6m.8), so it does NOT decline them; this golden is the
   Rule-2 e2e proof that the keep path actually lowers+links+runs (promoting the
   census cell COMPILES-by-recognition -> VERIFIED). Under the census's -fno-builtin
   injection posture the openlibm `s_rintl.c` body instead declines
   ("nested control flow under quantum control") — which is exactly why the keep
   path (not injection) is the right measure for this cell.

   Trace-only runtime (no simulation): cq_template_rint_f80 prints one line; the
   classical result is a SANITY value (rintl(0.5) = 0 under round-to-even). */
#include <math.h>

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);   /* tainted long double: alloc + ry_f80 */
    return cq_measure_f80(rintl(q));            /* @llvm.rint.f80 -> cq_template_rint_f80 */
}

int main(void) { (void) slice(); return 0; }
