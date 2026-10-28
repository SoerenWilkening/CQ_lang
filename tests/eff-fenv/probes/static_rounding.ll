; A static rounding metadata is its FE_* literal (_rm 2048); round.tonearest takes no mode;
; fpexcept.ignore emits no _exc.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define double @g(double %x0, double %th, double %c) #0 {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.upward", metadata !"fpexcept.ignore") #0
  %z = call double @llvm.experimental.constrained.fadd.f64(double %y, double %c, metadata !"round.tonearest", metadata !"fpexcept.ignore") #0
  %r = call double @cq_measure_f64(double %z)
  ret double %r
}
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @cq_measure_si32(i32)
declare i32 @fetestexcept(i32)
declare i32 @feclearexcept(i32)
declare i32 @fesetround(i32)
declare i32 @feholdexcept(ptr)
declare i32 @feupdateenv(ptr)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
; CHECK g: call i32 @cq_template_fmul_f64_hl_rm(i32 %{{a}}, double %{{b}}, i32 2048)
; CHECK g: call i32 @cq_template_fadd_f64_hl(
; CHECK-COUNT g: _exc( 0
