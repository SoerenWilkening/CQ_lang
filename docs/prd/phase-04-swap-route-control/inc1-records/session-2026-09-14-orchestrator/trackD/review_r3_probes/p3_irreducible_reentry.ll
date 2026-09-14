declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @opaque()
define i32 @example(i32 %c0, i32 %c2) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %e = icmp eq i32 %c0, 0
  br i1 %e, label %pre, label %mid
pre:
  br label %loop
loop:
  %s = phi i32 [ 0, %pre ], [ %snext, %latch ]
  %i = phi i32 [ 0, %pre ], [ %inext, %latch ]
  %g = icmp eq i32 %i, 0
  br i1 %g, label %read, label %latch
read:
  %b = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %b)
  br label %latch
latch:
  %add = phi i32 [ %m, %read ], [ 1, %loop ]
  %snext = add nsw i32 %s, %add
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %mid, label %loop
mid:
  %again = icmp eq i32 %c2, 0
  br i1 %again, label %pre, label %exit
exit:
  ret i32 %c0
}
