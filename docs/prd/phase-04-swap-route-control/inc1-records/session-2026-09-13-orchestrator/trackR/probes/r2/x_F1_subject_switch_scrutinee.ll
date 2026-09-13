; F1 BOUNDARY — the collider is an i32 pinned to the i32 seed 0 and is a SWITCH
; SCRUTINEE, not a br condition.  R-2 as spelled does NOT fire: the row must keep
; declining, and it does not benefit.  (A switch scrutinee can never be an i1, so this
; row also shows R-2's predicate is i1-only in practice.)
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = add nsw i32 %q, -5
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  switch i32 %d, label %sd [ i32 0, label %s0 ]
s0:
  call void @cq_phi(double 7.000000e-01)
  br label %sd
sd:
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mr
}
