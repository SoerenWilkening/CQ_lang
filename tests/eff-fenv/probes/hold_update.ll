; feholdexcept saves the quantum flags and empties them; feupdateenv ORs the saved part back.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @h(double %x0, double %th, double %c) #0 {
  %env = alloca [32 x i8]
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  %s = call i32 @feholdexcept(ptr %env) #0
  %z = call double @llvm.experimental.constrained.fadd.f64(double %y, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  %u = call i32 @feupdateenv(ptr %env) #0
  %f = call i32 @fetestexcept(i32 63) #0
  %m = call i32 @cq_measure_si32(i32 %f)
  %mz = call double @cq_measure_f64(double %z)
  ret i32 %m
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
; CHECK h: call i32 @feholdexcept(
; CHECK h: call i32 @cq_template_or_i32(
; CHECK h: call i32 @feupdateenv(
