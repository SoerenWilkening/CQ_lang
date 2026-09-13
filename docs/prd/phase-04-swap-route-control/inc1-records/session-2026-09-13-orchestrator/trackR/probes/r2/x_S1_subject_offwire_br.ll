; S1 SUBJECT — control_inplace_ry_reject_stateprep_second_flag_i1.ll VERBATIM plus a
; second region whose BRANCH CONDITION is the off-wire pinned flag %d.  R-2 as
; spelled ("a pinned value used as the condition of a conditional br is not a
; collider") REMOVES F2's decline here.  Predict: DECLINE F2 on the ORACLE.
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
  %rt = call i1 @cq_theta_i1(i1 true, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ true, %entry ]
  br i1 %d, label %arm2, label %merge2
arm2:
  call void @cq_phi(double 7.000000e-01)
  br label %merge2
merge2:
  %md = call i1 @cq_measure_i1(i1 %d)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z1 = zext i1 %md to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
