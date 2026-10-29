; cq-s32y: the old value of an in-place rotation inside a loop, invariant over the loop, read after
; the rotation: a body lowered once would rotate the same rail on every trip.
; FATAL: cq: unimplemented: spine: the pre-rotation value of an in-place cq_theta is read after it
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @loopinv(i32 %x0, double %t, i32 %n) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  br label %h
h:
  %i = phi i32 [ 0, %entry ], [ %i1, %h ]
  %y = call i32 @cq_theta_si32(i32 %x, double %t)
  %i1 = add nuw nsw i32 %i, 1
  %c = icmp ult i32 %i1, %n
  br i1 %c, label %h, label %e
e:
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}
