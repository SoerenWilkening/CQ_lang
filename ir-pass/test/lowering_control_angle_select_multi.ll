; lowering_control_angle_select_multi.ll — Family B2, SELECT form, MULTI-CONSUMER,
; POSITIVE (test_C_libtooling-byx, adversarial-review lock for the reduceAngleSelect
; twin). The select-form (WP10) analog of lowering_control_angle_diamond_multi.ll:
; one tainted-condition angle `select` feeds TWO rotations. The same use-list-order
; anchor hazard existed in reduceAngleSelect (pre-existing); the shared
; anchorAfterLastConsumer fix now anchors the flag uncompute after the
; program-order-last rotation here too. Both controlled-difference rotations MUST
; precede the single `..._hl_inv` uncompute.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(
; CHECK-NOT: cq_template_icmp_sgt_i32_hl_inv
; CHECK:     call void @cqrt_rz_i32_controlled(
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %w0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w = call i32 @cq_theta_si32(i32 %w0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  %ang = select i1 %c, double %a, double %b
  %r1 = call i32 @cq_phi_si32(i32 %u, double %ang)
  %r2 = call i32 @cq_phi_si32(i32 %w, double %ang)
  %m1 = call i32 @cq_measure_si32(i32 %r1)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  %s = add i32 %m1, %m2
  ret i32 %s
}
