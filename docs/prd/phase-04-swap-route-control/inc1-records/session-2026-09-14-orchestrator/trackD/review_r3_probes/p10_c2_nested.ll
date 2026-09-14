declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @opaque()
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  br label %outer
outer:
  %o = phi i32 [ 0, %entry ], [ %onext, %olatch ]
  %so = phi i32 [ 0, %entry ], [ %snext, %olatch ]
  br label %loop
loop:
  %s = phi i32 [ %so, %outer ], [ %snext0, %latch ]
  %i = phi i32 [ 0, %outer ], [ %inext, %latch ]
  %g = icmp eq i32 %i, 0
  br i1 %g, label %read, label %latch
read:
  %b = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %b)
  br label %latch
latch:
  %add = phi i32 [ %m, %read ], [ 1, %loop ]
  %snext0 = add nsw i32 %s, %add
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %olatch, label %loop
olatch:
  %snext = phi i32 [ %snext0, %latch ]
  %onext = add nuw nsw i32 %o, 1
  %odone = icmp eq i32 %onext, 4
  br i1 %odone, label %exit, label %outer
exit:
  ret i32 %snext
}
