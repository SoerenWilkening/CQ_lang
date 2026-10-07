; lowering_intrinsic_fma_llq.ll — bd 3c6m.73: the ternary fma with an ALL-CLASSICAL
; PRODUCT and a QUANTUM ADDEND, `fma(a, b, q)` = a*b + q, lowers to the `llq` shape
; `cq_template_fma_<W>_llq(<W> a, <W> b, i32 q)`. Formerly
; lowering_reject_fma_literal_product.ll, which declined the shape as unreachable
; ("clang const-folds a literal*literal product"). That premise is false for runtime
; operands: `fma(x0, x1, q)` (math.h CCQ cell) and plain C `x*y + q` (clang's default
; -ffp-contract=on emits `@llvm.fmuladd`) both reach it with classical PARAMETERS.
;
; The product a*b is never computed classically and passed as one literal: fma
; rounds a*b+c once, so a classical a*b rounded first is a different function.
; Both factors ride the template as literals (R13, never cqrt_alloc'd), the addend
; handle is positional. Class-2 producer: |q>|0> -> |q>|fma(a,b,q)>, and the void
; `_llq_unc(out, a, b, q)` recomputes it from the still-live q (source-liveness).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=NONE %s < %t.ll
;
; f64, two runtime factors, the fma result is an interior node (uncomputed):
; CHECK-LABEL: define double @f64_params(
; CHECK:       %[[Q:[^ ]+]] = call i32 @cqrt_alloc_f64(double %u)
; CHECK:       %[[R:[^ ]+]] = call i32 @cq_template_fma_f64_llq(double %x, double %y, i32 %[[Q]])
; CHECK:       call i32 @cq_template_fadd_f64(i32 %[[Q]], i32 %[[R]])
; CHECK:       call void @cq_template_fma_f64_llq_unc(i32 %[[R]], double %x, double %y, i32 %[[Q]])
; CHECK:       ret double
;
; f32 via the may-fuse contraction `x*y + q` (llvm.fmuladd), a constant factor:
; CHECK-LABEL: define float @f32_fmuladd(
; CHECK:       %[[Q32:[^ ]+]] = call i32 @cqrt_alloc_f32(float %u)
; CHECK:       call i32 @cq_template_fma_f32_llq(float %x, float 3.000000e+00, i32 %[[Q32]])
; CHECK:       ret float
;
; f80 (fmal), operand order of the product preserved, the addend stays slot 2:
; CHECK-LABEL: define x86_fp80 @f80_params(
; CHECK:       %[[Q80:[^ ]+]] = call i32 @cqrt_alloc_f80(x86_fp80 %u)
; CHECK:       call i32 @cq_template_fma_f80_llq(x86_fp80 %y, x86_fp80 %x, i32 %[[Q80]])
; CHECK:       ret x86_fp80
;
; Whole file (a NONE-only prefix scans all of it; the source `declare`s of the
; intrinsics survive, so the negatives name the CALL): no source intrinsic call
; survives, and no classical factor becomes a qubit.
; NONE-NOT:    call {{.*}}@llvm.fma.
; NONE-NOT:    call {{.*}}@llvm.fmuladd.
; NONE-NOT:    cqrt_alloc_{{f32|f64|f80}}({{float|double|x86_fp80}} %x)
; NONE-NOT:    cqrt_alloc_{{f32|f64|f80}}({{float|double|x86_fp80}} %y)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare double @llvm.fma.f64(double, double, double)
declare float @llvm.fmuladd.f32(float, float, float)
declare x86_fp80 @llvm.fma.f80(x86_fp80, x86_fp80, x86_fp80)

define double @f64_params(double %u, double %x, double %y) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.fma.f64(double %x, double %y, double %q)
  %s = fadd double %r, %q
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}

define float @f32_fmuladd(float %u, float %x) {
entry:
  %q = call float @cq_theta_f32(float %u, double 5.000000e-01)
  %r = call float @llvm.fmuladd.f32(float %x, float 3.000000e+00, float %q)
  %m = call float @cq_measure_f32(float %r)
  ret float %m
}

define x86_fp80 @f80_params(x86_fp80 %u, x86_fp80 %x, x86_fp80 %y) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  %r = call x86_fp80 @llvm.fma.f80(x86_fp80 %y, x86_fp80 %x, x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}
