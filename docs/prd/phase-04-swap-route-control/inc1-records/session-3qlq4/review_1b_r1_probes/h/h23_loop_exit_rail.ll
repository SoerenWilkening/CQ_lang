define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %i1, %head ]
  call void @cq_phi(double 7.000000e-01)
  %i1 = add i32 %i, 1
  br i1 %b, label %head, label %out
out:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  ret i32 %z
}
