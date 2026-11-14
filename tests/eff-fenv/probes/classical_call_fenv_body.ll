; A call with classical data of a body that reads the environment while the quantum flags are live (cq-fqlf):
; rule 23 reaches it with the mode and the flags rail, so it is the all-zero-mask clone with 82's ABI and the mode
; as a handle (_rmq, §1.4), never the own symbol, whose fetestexcept would see the host part only.
; CHECK g: call fastcc { i32, i32 } @__cq_q_peek_0_rmq(i32 32, i32 %{{m}}, i32 %{{f}})
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
