; control_predmux_reject_switch_fp_merge_angle.ll — DECLINE (bd test_C_libtooling-dm7f.17).
; The negative twin of control_predmux_accept_switch_fp_merge.ll: the SAME quantum fp
; switch merge, but it feeds the ANGLE of a `cq_theta` on another register. A
; quantum-valued angle is the open gap bd 94ad (CLAUDE.md R3), so it must fail loudly,
; never lower as data. Since W8 claims the switch, the decision is made at the
; rotation consumer by SelectClassify's gate 3 on the flattened select, not by the
; merge's type.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: rotation angle under quantum control

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @main(i32 noundef %c, i32 noundef %r0) {
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
  %r = tail call i32 @cq_theta_si32(i32 noundef %r0, double noundef %a)
  %m = tail call i32 @cq_measure_si32(i32 noundef %r)
  ret i32 %m
}
