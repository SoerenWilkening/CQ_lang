declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %body ]
  %inext = add i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %body
body:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armA, label %armB
armA:
  br label %head
armB:
  br label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
