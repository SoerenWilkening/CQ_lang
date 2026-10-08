; control_predmux_reject_switch_fp_merge_phase_angle.ll — DECLINE (bd test_C_libtooling-dm7f.17, review round 2).
; The quantum fp switch merge of control_predmux_accept_switch_fp_merge.ll feeds the ANGLE
; of the register-free branch phase `void @cq_phi(double)`. A quantum angle is the open gap
; bd 94ad, so it must fail loudly as an angle. Before W8 this declined at SwitchClassify's
; G4 type gate as `control flow` (its angle walk misses `cq_phi`'s arg-0 slot, bd yhm9);
; W8 routes it to SelectClassify, whose gate 3 covers that slot, so it now declines with
; the precise reason. (The cq_theta arg-1 twin,
; control_predmux_reject_switch_fp_merge_angle.ll, declined `rotation angle` before too.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: rotation angle under quantum control

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @cq_phi(double noundef)

define i32 @main(i32 noundef %c) {
entry:
  %q = tail call i32 @cq_theta_si32(i32 noundef %c, double noundef 5.000000e-01)
  %y = sitofp i32 %q to double
  switch i32 %q, label %merge [
    i32 1, label %one
    i32 2, label %two
  ]
one:
  %y1 = fmul double %y, 3.000000e+00
  br label %merge
two:
  %y2 = fadd double %y, 7.000000e+00
  br label %merge
merge:
  %a = phi double [ %y, %entry ], [ %y2, %two ], [ %y1, %one ]
  tail call void @cq_phi(double noundef %a)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  ret i32 %m
}
