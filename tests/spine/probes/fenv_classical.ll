; calls::classify routes every <fenv.h> call of a lowered function to eff-fenv (rule 23, cq-beya),
; classical ones included; with no quantum mode or flags rail live, eff-fenv keeps the host call.
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @fesetround(i32)
declare i32 @fegetround()
declare i32 @feclearexcept(i32)
declare i32 @fetestexcept(i32)

define double @fenv_classical(double %x0, double %t) {
  %s = call i32 @fesetround(i32 3072)
  %c = call i32 @feclearexcept(i32 63)
  %x = call double @cq_theta_f64(double %x0, double %t)
  %r = call double @cq_measure_f64(double %x)
  %g = call i32 @fegetround()
  %f = call i32 @fetestexcept(i32 32)
  %h = call i32 @fesetround(i32 0)
  ret double %r
}
; CHECK fenv_classical: call i32 @fesetround(i32 3072)
; CHECK fenv_classical: call i32 @feclearexcept(i32 63)
; CHECK fenv_classical: call i32 @fegetround()
; CHECK fenv_classical: call i32 @fetestexcept(i32 32)
; CHECK fenv_classical: call i32 @fesetround(i32 0)
