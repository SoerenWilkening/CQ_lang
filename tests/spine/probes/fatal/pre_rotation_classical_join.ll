; cq-drcl (rev s32y-n1 a2c): the old value of a rotation inside a classical arm, read after the
; classical join: the copy is emitted in the arm, and on the other path the value is the register
; itself; a merge of the two at the classical join is not built.
; FATAL: cq: unimplemented: spine: the pre-rotation value of an in-place cq_theta under a classical guard
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @a2c(i32 %x0, double %tx, i32 %c, double %t) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %tx)
  %z = icmp eq i32 %c, 0
  br i1 %z, label %j, label %a
a:
  %x2 = call i32 @cq_theta_si32(i32 %x, double %t)
  br label %j
j:
  %xm = phi i32 [ %x2, %a ], [ %x, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %xm)
  %m2 = call i32 @cq_measure_si32(i32 %x)
  %s = add nsw i32 %m2, %m1
  ret i32 %s
}
