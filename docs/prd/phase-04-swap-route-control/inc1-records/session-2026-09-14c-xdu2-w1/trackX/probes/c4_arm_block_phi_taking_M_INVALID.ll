; c4 — bd hrts proposes a SECOND clause "for the ARM slot: a phi at the top of
; the arm block taking M on a back edge is available at the arm and not at the
; pred".  Construction attempt: a phi in the ARM block taking M.
; EXPECT: opt -passes=verify REJECTS (the arm's single incoming edge is Pred->Arm,
; which M does not dominate).
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %ap = phi i32 [ %m, %entry ]
  %t = call i32 @cq_theta_si32(i32 %ap, double 9.000000e-01)
  br label %merge
merge:
  %m = phi i32 [ %t, %arm ], [ 7, %entry ]
  %mm = call i32 @cq_measure_si32(i32 %m)
  ret i32 %mm
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
