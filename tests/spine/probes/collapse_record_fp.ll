; cq-e373, cq-29ej: an fp template with no original instruction (an aggr vector lane) whose source is
; measured collapses (rule 2): recomputed classically in the default mode with §2's NaN rule (the first
; NaN operand, quieted).
; CHECK lane_fadd: %{{a}} = fadd double %{{b}}, 1.000000e+00
; CHECK lane_fadd: or i64 %{{c}}, 2251799813685248
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @lane_fadd(double %x0, double %t) {
entry:
  %x = call double @cq_theta_f64(double %x0, double %t)
  %v0 = insertelement <2 x double> poison, double %x, i64 0
  %v = insertelement <2 x double> %v0, double 2.0, i64 1
  %a = fadd <2 x double> %v, <double 1.0, double 1.0>
  %m = call double @cq_measure_f64(double %x)
  %e = extractelement <2 x double> %a, i64 0
  %r = fadd double %e, %m
  ret double %r
}
