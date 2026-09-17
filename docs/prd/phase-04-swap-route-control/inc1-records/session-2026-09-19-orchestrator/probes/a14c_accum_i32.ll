; A14c — lowering_reject_loop_cross_iter.ll AT i32, the width bd `zujr`'s
; predicate admits. The latch incoming is a FRESH TEMPLATE RAIL, not a
; control-merge %out, so the promotion must refuse it and the module must still
; decline LOUDLY.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @crossiter(i32 %seed, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %seed, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %exit
ph:
  br label %loop
exit:
  %accx = phi i32 [ 0, %entry ], [ %accn, %loop ]
  %m = call i32 @cq_measure_si32(i32 %accx)
  ret i32 %m
loop:
  %i = phi i32 [ 0, %ph ], [ %inext, %loop ]
  %acch = phi i32 [ 0, %ph ], [ %accn, %loop ]
  %accn = add i32 %q0, %acch
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop
}
