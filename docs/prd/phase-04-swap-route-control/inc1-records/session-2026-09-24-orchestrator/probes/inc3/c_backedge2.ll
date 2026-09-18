declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %ia, %armA ], [ %ib, %armB ]
  %g = icmp eq i32 %i, 7
  br i1 %g, label %exit, label %body
body:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armA, label %armB
armA:
  %ia = add i32 %i, 1
  br label %head
armB:
  %ib = add i32 %i, 2
  br label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
