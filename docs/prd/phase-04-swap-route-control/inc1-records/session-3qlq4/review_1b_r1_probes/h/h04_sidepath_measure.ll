define i32 @example(i1 %u0, i32 %g) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %cg = icmp ne i32 %g, 0
  br i1 %cg, label %mm, label %pred
mm:
  %m0 = call i1 @cq_measure_i1(i1 %b)
  br label %pred
pred:
  %p = phi i1 [ %m0, %mm ], [ false, %entry ]
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %z = zext i1 %p to i32
  ret i32 %z
}
