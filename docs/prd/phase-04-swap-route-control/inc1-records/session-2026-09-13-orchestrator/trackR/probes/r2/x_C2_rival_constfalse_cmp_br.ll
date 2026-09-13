; C2 RIVAL of C1 — the BOTH-SLOTS-FOLDED rival: an honest in-place Ry on %x's own rail
; (), %x still a branch condition.  This is the ONLY
; rival family that can fold into C1 (the cross-handle family is R3-refused, B1).
; If this LOWERS, R-2 removes the only decline of a lowerable rival = HOLE.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = icmp slt i32 %q, -2147483648
  %c = icmp sgt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ %x, %entry ]
  br i1 %x, label %arm2, label %merge2
arm2:
  call void @cq_phi(double 7.000000e-01)
  br label %merge2
merge2:
  %mx = call i1 @cq_measure_i1(i1 %x)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z1 = zext i1 %mx to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
