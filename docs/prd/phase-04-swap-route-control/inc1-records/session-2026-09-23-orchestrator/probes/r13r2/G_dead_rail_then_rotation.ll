; The dead rail sits BEFORE a non-diagonal gate on the SAME register chain: the
; rail is chained from %s0, and %s0 is rotated again AFTER the region, then
; measured.  If the dead rail's Ry is emitted but not reverse-played the later
; rotation is on a relabelled rail (Rule 8).
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @probe() {
entry:
  %s0 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  %r  = call i1 @cq_theta_i1(i1 %s0, double 5.000000e-01)
  br i1 %r, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %t  = call i1 @cq_theta_i1(i1 %r, double 9.000000e-01)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %z2 = zext i1 %mt to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
