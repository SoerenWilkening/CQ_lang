; B4 RIVAL of B3 — the arm rotates the trunc-minted i1 rail %t IN PLACE, and %t is
; still a downstream branch condition.  If this LOWERS, R-2 removes the ONLY decline
; of a lowerable rival = a HOLE.
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
  %rt = call i1 @cq_theta_i1(i1 %t, double 9.000000e-01)
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
