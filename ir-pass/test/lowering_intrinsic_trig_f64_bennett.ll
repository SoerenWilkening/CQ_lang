; lowering_intrinsic_trig_f64_bennett.ll — bd 3c6m.71 (owner ruling 2026-10-06):
; a tainted `double` sin/cos/tan lowers DIRECTLY to one backend call
; `cq_template_{sin,cos,tan}_f64`, whose circuit a backend supplies; the
; reference implementation is Bennett.jl soft_sin/soft_cos/soft_tan (824458d1,
; a musl port: full f64 range, Cody-Waite + Payne-Hanek reduction, <=1 ULP
; reference, bit-exact vs Linux libm). CLAUDE R14's Bennett route. Additive
; producers: each mints a fresh rail, and the chain's intermediates are
; uncomputed by their `_unc` twins (recompute from the live source), never
; inverted. Nothing reaches the bundle, and no libm call survives.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u)
; CHECK:     %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sin_f64(i32 %[[H]])
; CHECK:     %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_cos_f64(i32 %[[S]])
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_tan_f64(i32 %[[C]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[T]])
; CHECK-NOT: @llvm.sin
; CHECK-NOT: @llvm.cos
; CHECK-NOT: @llvm.tan
; CHECK-NOT: cq taint escape
; CHECK-NOT: _f64_inv

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sin.f64(double)
declare double @llvm.cos.f64(double)
declare double @llvm.tan.f64(double)

define double @example(double %u) {
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %s = call double @llvm.sin.f64(double %q)
  %c = call double @llvm.cos.f64(double %s)
  %t = call double @llvm.tan.f64(double %c)
  %m = call double @cq_measure_f64(double %t)
  ret double %m
}
