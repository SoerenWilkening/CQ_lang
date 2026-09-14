declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @opaque()
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  br label %loop
loop:
  %s = phi i32 [ 0, %entry ], [ %snext, %read ]
  %i = phi i32 [ 0, %entry ], [ %inext, %read ]
  %g = icmp eq i32 %i, 0
  br i1 %g, label %read, label %read
read:
  %b = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %b)
  %snext = add nsw i32 %s, %m
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %snext
}
