declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %in = add i32 %i, 1
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %inner, label %armB
inner:
  %j = phi i32 [ 0, %head ], [ %jn, %inner ]
  %jn = add i32 %j, 1
  %jd = icmp eq i32 %jn, 4
  br i1 %jd, label %latch, label %inner
armB:
  br label %latch
latch:
  %v = phi i32 [ 7, %inner ], [ 8, %armB ]
  %w = phi i32 [ 1, %inner ], [ 2, %armB ]
  %s = add i32 %v, %w
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
