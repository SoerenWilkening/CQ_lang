; an f64 CLASSICAL table value muxed under a tainted condition (L9: an fp merge phi
; is an ANGLE, not data).  The new predicate's width gate is abiWidthFromType!=empty.
@cd = constant [4 x double] [double 1.5, double 2.5, double 3.5, double 4.5], align 16
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @probe(i64 %i) {
entry:
  %j = and i64 %i, 3
  %q = call double @cq_theta_f64(double 0.0, double 5.000000e-01)
  %Z = call double @cq_theta_f64(double 5.0, double 2.500000e-01)
  %c = fcmp ogt double %q, 2.0
  br i1 %c, label %arm, label %merge
arm:
  %gz = getelementptr inbounds [4 x double], ptr @cd, i64 0, i64 %j
  %z = load double, ptr %gz, align 8
  %Z1 = fsub double %Z, 1.0
  br label %merge
merge:
  %v  = phi double [ 1.000000e+00, %entry ], [ %z, %arm ]
  %Zn = phi double [ %Z, %entry ], [ %Z1, %arm ]
  %t  = fadd double %Zn, %v
  %m1 = call double @cq_measure_f64(double %t)
  ret double %m1
}
