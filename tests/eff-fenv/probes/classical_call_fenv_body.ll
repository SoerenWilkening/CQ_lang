; A classical (not lifted) call of a body that reads the environment while the quantum flags are live:
; its fetestexcept would see the host part only. Still refused (rule 23 state does not cross a classical call).
; EXPECT-ERROR: awaiting owner ruling: SPEC_ISSUES rule 23: a classical call of a body that reads the live quantum environment
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define internal fastcc i32 @peek(i32 %m) #1 {
  %r = call i32 @fetestexcept(i32 %m) #0
  ret i32 %r
}
define i32 @g(double %x0, double %th, double %c) #0 {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  %p = call fastcc i32 @peek(i32 32) #0
  %mz = call double @cq_measure_f64(double %y)
  ret i32 %p
}
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @fetestexcept(i32)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
attributes #1 = { noinline strictfp }
