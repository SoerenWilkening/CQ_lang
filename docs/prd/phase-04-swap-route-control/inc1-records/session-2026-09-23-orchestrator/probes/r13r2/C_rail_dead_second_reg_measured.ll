; ATTACK C — the dead rail is chained on a compare of q2; a DIFFERENT register
; q is the one measured.  q2 is never measured, so FreePoint has no measured
; register in the dead chain.
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u, i32 %v) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %v, double 3.000000e-01)
  %c  = icmp sgt i32 %q2, 1
  %rail = call i1 @cq_theta_i1(i1 %c, double 5.000000e-01)
  br i1 %rail, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %p2 = phi i1 [ false, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %z1, %z2
  %s2 = add i32 %s, %m
  ret i32 %s2
}
declare i32 @cq_measure_si32(i32)
