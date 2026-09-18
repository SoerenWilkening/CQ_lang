; The rail is ALSO a merge-phi incoming (task attack 1, last bullet): the phi
; carries %rail on the arm edge and false on the pred edge, so after the flatten
; the rail is read by the composed value AND is the condition.
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %rail, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1  [ %rail, %arm ], [ false, %entry ]
  %p2 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %z1 = zext i1 %p1 to i32
  %m  = call i32 @cq_measure_si32(i32 %p2)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %z1, %m
  %s2 = add i32 %s, %mq
  ret i32 %s2
}
