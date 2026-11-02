; cq-hzji: round.tonearestaway has no x86-64 FE_* mode; the x86 backend rounds such an op in the current
; mode, so it is the dynamic mode here (a fegetround() literal while MODE is classical).
; CHECK f: call i32 @cq_template_fadd_f64_hl_rm(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define double @f(double %x0, double %th, double %c) #0 {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fadd.f64(double %x, double %c, metadata !"round.tonearestaway", metadata !"fpexcept.strict") #0
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
