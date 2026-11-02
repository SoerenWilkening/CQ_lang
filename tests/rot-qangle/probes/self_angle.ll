; cq_theta of an f64 register by its own value (cq-oa67): the target is never one of its own controls (CR
; §1.3), so the angle is a basis copy of the register taken before the rotation, which stays allocated.
; CHECK self_angle: call void @cqrt_copy_f64(i32 %{{x}}, i32 %{{c}})
; CHECK-COUNT self_angle: call void @cqrt_ry_f64_qangle( 1
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @self_angle(double %x0, double %t) {
  %x = call double @cq_theta_f64(double %x0, double %t)
  %y = call double @cq_theta_f64(double %x, double %x)
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}
