; E1 (rule 23, 82): a quantum call of a clone doing constrained FP work while the quantum flags are live.
; Until calls and spine pass the caller's mode and flags (fenv::envArgs / bindCloneEnv), the clone must
; stop loudly instead of rounding in the host mode and dropping what it raises.
; EXPECT-ERROR: materialized without the caller's mode and flags
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define internal fastcc double @scale(double %v, double %c) #1 {
  %r = call double @llvm.experimental.constrained.fmul.f64(double %v, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  ret double %r
}
define i32 @g(double %x0, double %th, double %c) #0 {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  %z = call fastcc double @scale(double %y, double %c) #0
  %f = call i32 @fetestexcept(i32 63) #0
  %m = call i32 @cq_measure_si32(i32 %f)
  %mz = call double @cq_measure_f64(double %z)
  ret i32 %m
}
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @cq_measure_si32(i32)
declare i32 @fetestexcept(i32)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
attributes #1 = { noinline strictfp }
