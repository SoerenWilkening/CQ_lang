declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br label %header
header:
  %i = phi i32 [ 0, %merge ], [ %inext, %latch ]
  br i1 %b1, label %ph, label %latch
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %latch
latch:
  %c = call i1 @cq_theta_i1(i1 %b0, double 7.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %header
exit:
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
