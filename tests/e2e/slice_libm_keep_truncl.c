/* slice_libm_keep_truncl.c — bd 3c6m.56: the long-double `truncl` KEEP path.

   Sibling of slice_libm_keep_rintl.c. With builtins on, `clang -O1` folds
   `truncl(x)` to the in-grid IR intrinsic `@llvm.trunc.f80`, which cq-lowering
   recognizes (IntrinsicLowering.cpp) and lowers to `cq_template_trunc_f80`. No
   injected body; the asm-level `callq _truncl` is intercepted as the intrinsic
   BEFORE codegen (the floor.f80 precedent).

   BENNETT-GATED KEEP (owner criterion 2026-07-24, bd 3c6m.56): `trunc` (round
   toward zero) is backed by Bennett's `soft_trunc` (`src/softfloat/fround.jl`),
   so a real Phase-9 backend has a Bennett source. Contrast `fmod`→`frem` (no
   Bennett primitive → NOT a keep).

   `trunc` is already a census keep (probe.py keep-set); this golden is the Rule-2
   e2e proof (COMPILES-by-recognition -> VERIFIED). Under the census -fno-builtin
   injection posture the truncl cell declines "unknown callee" (the openlibm
   `s_truncl.bc` body is a BSD-header corpus gap) — another reason the keep path,
   not injection, is the right measure for this cell.

   Trace-only runtime: truncl(0.5) = 0 (toward zero) is a SANITY value. */
#include <math.h>

long double slice(void) {
    long double q = cq_theta_f80(0.5L, 0.5);   /* tainted long double: alloc + ry_f80 */
    return cq_measure_f80(truncl(q));           /* @llvm.trunc.f80 -> cq_template_trunc_f80 */
}

int main(void) { (void) slice(); return 0; }
