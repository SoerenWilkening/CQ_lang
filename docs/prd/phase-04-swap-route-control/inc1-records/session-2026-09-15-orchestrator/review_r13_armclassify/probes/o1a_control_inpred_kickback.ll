; o1a — the in-Pred control for o1: the kickback's branch sits in the prep's own
; merge block, so the hcrg alias edge supplies the order and no new edge is used.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %M = phi i1 [ %t, %arm ], [ false, %entry ]
  %s = select i1 %M, i32 2, i32 5
  br i1 %M, label %ph, label %post
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %post
post:
  %m = call i32 @cq_measure_si32(i32 %s)
  %mb = call i1 @cq_measure_i1(i1 %M)
  %z = zext i1 %mb to i32
  %r = add i32 %m, %z
  ret i32 %r
}
