; lowering_control_angle_diamond_armneg.ll — Family B2, ArmNegated diamond,
; POSITIVE (test_C_libtooling-byx, cwk fix (b)). POLARITY LOCK for a SWAPPED
; branch: `clang` emits `br i1 %c, label %merge, label %arm` (the gate arm is the
; FALSE successor — e.g. from `if (u <= 5)` canonicalized), so the arm is taken
; when the condition is FALSE. The merge `φ [%a, %arm], [%b, %entry]` is therefore
; `flag==1 ? %b : %a`: the flag==0 edge is the ARM, so the base MUST be `%a` and
; the controlled difference `%b − %a`. A wrong ZeroEdge (treating `entry` as the
; base, as the true-successor case does) would emit base `%b` / `fsub %a, %b` —
; the opposite rotation, a silent miscompile this fixture forbids.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     call void @cqrt_rz_i32(i32 %[[H]], double %a)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = fsub double %b, %a
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]], double %[[D]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[H]], i32 5)
; CHECK-NOT: phi double
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %merge, label %arm   ; swapped: arm is the FALSE successor
arm:
  br label %merge
merge:
  %ang = phi double [ %a, %arm ], [ %b, %entry ]  ; flag==1 ? %b : %a
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
