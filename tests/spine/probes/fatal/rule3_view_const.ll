; cq-su3p: a rule 10 merge through a zext whose constant incoming is not the register's initial value
; (the register was minted at 0, the other edge brings 1): no rail holds that merge.
; FATAL: cq: unimplemented: spine: a rule 10 merge through a representation change whose constant incoming
declare i1 @cq_theta_i1(i1, double)
declare i8 @cq_measure_ui8(i8)

define i8 @badconst(double %t) {
entry:
  %q = call i1 @cq_theta_i1(i1 false, double %t)
  br i1 %q, label %a, label %j
a:
  %r = call i1 @cq_theta_i1(i1 false, double %t)
  %z = zext i1 %r to i8
  br label %j
j:
  %p = phi i8 [ %z, %a ], [ 1, %entry ]
  %m = call i8 @cq_measure_ui8(i8 %p)
  ret i8 %m
}
