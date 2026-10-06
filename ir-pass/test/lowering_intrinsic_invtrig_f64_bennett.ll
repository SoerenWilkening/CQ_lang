; lowering_intrinsic_invtrig_f64_bennett.ll — bd 3c6m.71 (owner 2026-10-06): a
; tainted `double` asin/acos/atan lowers to one backend call each,
; `cq_template_{asin,acos,atan}_f64`, reference Bennett.jl soft_asin/acos/atan
; (824458d1; contracts in tools/intrinsic_table.yaml). Additive producers: the
; chain's intermediates are uncomputed by `_unc`, never inverted.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u)
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_asin_f64(i32 %[[H]])
; CHECK:     %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_acos_f64(i32 %[[A]])
; CHECK:     %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_atan_f64(i32 %[[B]])
; CHECK:     call void @cq_template_acos_f64_unc(i32 %[[B]], i32 %[[A]])
; CHECK:     call void @cq_template_asin_f64_unc(i32 %[[A]], i32 %[[H]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[C]])
; CHECK-NOT: @llvm.asin
; CHECK-NOT: @llvm.acos
; CHECK-NOT: @llvm.atan
; CHECK-NOT: cq taint escape

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.asin.f64(double)
declare double @llvm.acos.f64(double)
declare double @llvm.atan.f64(double)

define double @example(double %u) {
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %a = call double @llvm.asin.f64(double %q)
  %b = call double @llvm.acos.f64(double %a)
  %c = call double @llvm.atan.f64(double %b)
  %m = call double @cq_measure_f64(double %c)
  ret double %m
}
