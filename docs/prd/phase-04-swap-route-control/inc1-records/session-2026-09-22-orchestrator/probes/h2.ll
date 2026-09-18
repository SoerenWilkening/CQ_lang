; Same, but the angle select's consumer (cq_theta) is OUTSIDE the arm, so the
; select's only in-arm user is nothing — it ESCAPES, which is (K3).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %ac = icmp slt i32 %q, 9
  %ang = select i1 %ac, double 1.0, double 2.0
  %v1 = add i32 %p, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %ap = phi double [ %ang, %arm ], [ 0.0, %entry ]
  %r = call i32 @cq_theta_si32(i32 %pm, double %ap)
  %m  = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
