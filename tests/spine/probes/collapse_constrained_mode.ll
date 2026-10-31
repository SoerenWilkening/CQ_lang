; cq-i962: y = x * c rounded upward from quantum x, mode back to nearest, x measured: y's classical
; recomputation rounds in the mode it was lowered with (fesetround(2048)) and restores the host
; environment after it (fegetenv / fesetenv: its exceptions do not reach the host flags).
; CHECK f: call i32 @fegetenv(ptr %{{e}})
; CHECK f: call i32 @fesetround(i32 2048)
; CHECK f: call i32 @fesetenv(ptr %{{e}})
target triple = "x86_64-apple-macosx16.0.0"
define i32 @f(double %x0, double %th, double %c) #0 {
  %x = tail call double @cq_theta_f64(double %x0, double %th) #1
  %r1 = tail call i32 @fesetround(i32 2048) #1
  %y = tail call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.ignore") #1
  %r2 = tail call i32 @fesetround(i32 0) #1
  %m = tail call double @cq_measure_f64(double %x) #1
  %b = bitcast double %y to i64
  %t = trunc i64 %b to i32
  ret i32 %t
}
declare double @cq_theta_f64(double, double)
declare i32 @fesetround(i32)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata)
declare double @cq_measure_f64(double)
attributes #0 = { strictfp }
attributes #1 = { strictfp }
