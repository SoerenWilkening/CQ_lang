declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %inext = add i32 %i, 1
  %c1 = icmp sgt i32 %q, %inext
  br i1 %c1, label %mid, label %exit
mid:
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %latch, label %exit
latch:
  br label %head
exit:
  %p = phi i32 [ 1, %head ], [ 2, %mid ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
