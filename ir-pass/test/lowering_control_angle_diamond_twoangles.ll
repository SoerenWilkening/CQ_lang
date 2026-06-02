; lowering_control_angle_diamond_twoangles.ll — Family B2, MULTIPLE angle φ,
; POSITIVE (test_C_libtooling-byx, adversarial-review lock). One diamond whose
; merge carries TWO independent classical-angle φ (%ang1 on %u, %ang2 on %w),
; both gated by the same condition. Detection must collect BOTH (not just the
; first) so each is lowered as base + controlled-difference; lowering only the
; first would leave the second `phi double` to reduceClassicalMux (the cwk
; miscompile). Expect two base rotations and two controlled-difference rotations,
; all inside the single compare/uncompute bracket, verify-clean.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(
; CHECK:     call void @cqrt_rz_i32_controlled(
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: phi double
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %w0, double %a, double %b, double %p, double %q) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w = call i32 @cq_theta_si32(i32 %w0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %ang1 = phi double [ %a, %arm ], [ %b, %entry ]
  %ang2 = phi double [ %p, %arm ], [ %q, %entry ]
  %r1 = call i32 @cq_phi_si32(i32 %u, double %ang1)
  %r2 = call i32 @cq_phi_si32(i32 %w, double %ang2)
  %m1 = call i32 @cq_measure_si32(i32 %r1)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  %s = add i32 %m1, %m2
  ret i32 %s
}
