; EXPECT-ERROR: eff-fenv: the quantum floating-point environment changes in a block a classical branch chooses
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @k(double %x0, double %th, double %c, i1 %b) #0 {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  br i1 %b, label %t, label %j
t:
  %y = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  br label %j
j:
  %f = call i32 @fetestexcept(i32 63) #0
  %m = call i32 @cq_measure_si32(i32 %f)
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
