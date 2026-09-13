; B3 SUBJECT — a NON-compare i1 collider: %t = trunc %q to i1, pinned to {true} on
; the true edge of , and USED AS A BRANCH CONDITION downstream.
; R-2 removes F2's decline here too; %t is a cast (a template-minted rail), not a
; compare flag — so B1's shape wall may not stand in front of its rival (B4).
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = trunc i32 %q to i1
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 true, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ true, %entry ]
  br i1 %t, label %arm2, label %merge2
arm2:
  call void @cq_phi(double 7.000000e-01)
  br label %merge2
merge2:
  %mt = call i1 @cq_measure_i1(i1 %t)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z1 = zext i1 %mt to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
