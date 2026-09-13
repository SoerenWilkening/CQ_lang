; E4 RIVAL of E3 (v2) — the cross-handle rival (the only one a ONE-EDGE pin admits):
; the arm rotates %d in place against a literal straight-through incoming.
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
dead:
  br i1 %d, label %d1, label %d2
d1:
  call void @cq_phi(double 7.000000e-01)
  br label %d2
d2:
  unreachable
merge:
  %rm = phi i1 [ %rt, %arm ], [ true, %entry ]
  %md = call i1 @cq_measure_i1(i1 %d)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z1 = zext i1 %md to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
