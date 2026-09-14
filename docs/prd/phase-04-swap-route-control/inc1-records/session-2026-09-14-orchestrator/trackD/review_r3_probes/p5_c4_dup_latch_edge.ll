declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @opaque()
define i32 @example(i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  br label %loop
loop:
  %s = phi i32 [ 0, %entry ], [ %snext, %latch ], [ %snext, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ], [ %inext, %latch ]
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
  switch i32 %k, label %exit [ i32 1, label %loop
                               i32 2, label %loop ]
exit:
  ret i32 %snext
}
