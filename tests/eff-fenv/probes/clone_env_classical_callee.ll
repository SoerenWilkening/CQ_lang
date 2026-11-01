; cq-xhv4 (173, 174): a clone whose body reaches constrained FP work only through an ORDINARY call (a
; classical argument: __divsc3's logbf reaching the strictfp ilogbf) does not carry the environment
; (rule 23: the callee runs on the host, what it raises is the host part): its clone takes no mode and
; flags and returns its bare result handle.
; CHECK g: call fastcc i32 @__cq_q_f_10(i32 %{{x}}, double %{{c}})
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define internal double @h(double %v) #1 {
  %r = call double @llvm.experimental.constrained.fdiv.f64(double %v, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  ret double %r
}
define internal fastcc double @f(double %v, double %c) #2 {
  %k = call double @h(double %c)
  %m = fmul double %v, %k
  ret double %m
}
define double @g(double %x0, double %th, double %c) {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %z = call fastcc double @f(double %x, double %c)
  %mz = call double @cq_measure_f64(double %z)
  ret double %mz
}
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
attributes #1 = { noinline strictfp }
attributes #2 = { noinline }
