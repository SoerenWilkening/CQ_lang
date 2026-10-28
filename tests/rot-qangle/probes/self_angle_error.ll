; cq_theta of an f64 register by its own value: the target would be among the primitive's controls (CR
; §1.3). Not built yet: an internal error, never a lowering.
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @self_angle(double %x0, double %t) {
  %x = call double @cq_theta_f64(double %x0, double %t)
  %y = call double @cq_theta_f64(double %x, double %x)
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}
; EXPECT-ERROR: cq: unimplemented: rot-qangle: cq_theta of a rail by its own value as the angle
