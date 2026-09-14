; Track F — ATTEMPT to build a BOTH-EDGE fp collider (the fp half of R-2''s
; argument).  F2's fp ANCHOR seeds on exactly ONE edge by construction
; (ArmClassify.cpp EqHolds switch), so an fp collider is ALWAYS reported
; one-edge whether or not it is semantically the seed on the other edge.
; `%d = fmul %t, 0.0` is 0.0 for every finite %t, i.e. semantically the seed on
; BOTH edges; without fast-math `-O1` will not fold it, so it survives.
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t = fmul double %q, 2.000000e+00
  %c = fcmp oeq double %t, 6.000000e+00
  %d = fmul double %t, 0.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 0.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 0.000000e+00, %entry ]
  %mr = call double @cq_measure_f64(double %rm)
  %md = call double @cq_measure_f64(double %d)
  %s  = fadd double %mr, %md
  ret double %s
}
