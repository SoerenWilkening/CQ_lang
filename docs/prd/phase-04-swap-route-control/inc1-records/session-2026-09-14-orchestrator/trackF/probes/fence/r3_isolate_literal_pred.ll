; Track F — R3 ISOLATION.  An OFF-WIRE tainted base %p rotated in the arm, with a
; LITERAL in the pred slot.  RotBase=%p is not a Constant, so the F1/F2 state-prep
; block at ArmClassify.cpp:3876-4163 is skipped (its entry does
; cast<Constant>(RotBase)); the next `control flow` site on the rotation path is
; R3, :4168-4170, `if (Routed && RotBase != Routed)`.  Twin below flips ONLY the
; pred slot.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 4.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %p, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 7, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mr
}
