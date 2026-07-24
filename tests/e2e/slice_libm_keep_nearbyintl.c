/* slice_libm_keep_nearbyintl.c — bd 3c6m.56: the long-double `nearbyintl` KEEP path.

   Sibling of slice_libm_keep_rintl.c. With builtins on, `clang -O1` folds
   `nearbyintl(x)` to the in-grid IR intrinsic `@llvm.nearbyint.f80`, which
   cq-lowering recognizes (IntrinsicLowering.cpp) and lowers to
   `cq_template_nearbyint_f80`. No injected body; the asm-level `callq _nearbyintl`
   is intercepted as the intrinsic BEFORE codegen (the floor.f80 precedent).

   BENNETT-GATED KEEP (owner criterion 2026-07-24, bd 3c6m.56): `nearbyint` is
   `rint` without raising the inexact exception; under the default FP environment
   both are round-to-nearest-even, backed by Bennett's `soft_round`
   (`src/softfloat/fround.jl`). In a trace-only model with no rounding-mode state
   and no FP-exception observer, nearbyint and rint are the same operation — so the
   Bennett gate sequence covers this cell. Contrast `fmod`→`frem` (no Bennett
   primitive → NOT a keep).

   `rint`/`nearbyint`/`trunc` are already census keeps (probe.py keep-set); this
   golden is the Rule-2 e2e proof (COMPILES-by-recognition -> VERIFIED). Under the
   census -fno-builtin injection posture the openlibm `s_nearbyintl.c` (which shares
   `s_rintl.c`) declines "nested control flow under quantum control".

   Trace-only runtime: nearbyintl(0.5) = 0 (round-to-even) is a SANITY value. */
#include <math.h>

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);   /* tainted long double: alloc + ry_f80 */
    return cq_measure_f80(nearbyintl(q));       /* @llvm.nearbyint.f80 -> cq_template_nearbyint_f80 */
}

int main(void) { (void) slice(); return 0; }
