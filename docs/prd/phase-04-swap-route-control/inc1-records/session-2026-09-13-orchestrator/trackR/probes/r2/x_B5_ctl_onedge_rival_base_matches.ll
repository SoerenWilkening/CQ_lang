; B5 — THE BISECTION THAT NAMES THE FENCE.  A1/A2/B1/B4/E4 all declined `control flow`
; with the straight-through incoming a LITERAL and the rotated base a register; here the
; SAME one-edge-pinned %d is rotated in place with the merge's pred incoming CHANGED to
; %d, so R3 ("ONE base", ArmClassify.cpp:4103) is satisfied and nothing else moves.
; An ACCEPT here proves (a) the fence in front of the one-edge rival is R3, and (b) that
; rival is a well-formed lowerable program that CANNOT fold into the subject, because its
; pred-edge use of %d is not pinned on that edge.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = icmp sgt i32 %q, 7
  %c = icmp sgt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 %d, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ %d, %entry ]
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z2 = zext i1 %mr to i32
  ret i32 %z2
}
