; lowering_control_angle_switch_gated.ll — Family B2, gated-switch form, POSITIVE
; (test_C_libtooling-byx, cwk fix (b) PR3). The `SwitchRegion` analog of
; lowering_control_angle_diamond.ll / the angle-select-chain (WP16): a gated
; multi-arm `switch` on a tainted scrutinee whose arms apply gate sequences AND
; reconverge on a merge that ALSO carries a classical `phi double` (a rotation
; angle dispatched per case). `clang -O1` keeps this as a `SwitchInst` (the gate
; bodies are WHY it does not fold to a select chain).
;
; LOWERING: the gate bodies become `_controlled` on per-case eq-flags (case k on
; `f_k=(q==v_k)`, default on the ¬OR "none-matched" flag) — the existing WP18
; path. The angle `φ` is then lowered as base + per-case controlled-difference,
; REUSING those same eq-flags: an unconditional base `Rz(h, default-angle)` then
; one `Rz_controlled(f_k, h, a_k − default)` per case. The cases are mutually
; exclusive, so the net angle is `a_k` for the matching case and the default
; angle otherwise. The single compute/uncompute bracket (per-case eq flags +
; OR-fold) spans BOTH the gate bodies and the angle rotations; the N-way φ leaves
; no residual. (Was the cwk-fix-(a) negative guard; fix (b) PR3 lowers it.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[HV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 1)
; Gate bodies: default on ¬OR ("none matched"), each case on its eq-flag:
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[HV]], double 3.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F0]], i32 %[[HV]], double 1.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[HV]], double 2.000000e-01)
; Angle dispatch: unconditional base (default angle 3.0), then per-case difference:
; CHECK:     call void @cqrt_rz_i32(i32 %[[HV]], double 3.000000e+00)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F0]], i32 %[[HV]], double -2.000000e+00)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[HV]], double -1.000000e+00)
; Reverse-LIFO uncompute (OR-fold then each per-case eq), then the measure:
; CHECK:     call void @cqrt_toffoli_inv(
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 1)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 0)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[HV]])
; CHECK-NOT: switch
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  switch i32 %q, label %def [ i32 0, label %c0
                              i32 1, label %c1 ]
c0:
  %g0 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c1:
  %g1 = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  br label %merge
def:
  %gd = call i32 @cq_phi_si32(i32 %v, double 3.000000e-01)
  br label %merge
merge:
  %ang = phi double [ 1.000000e+00, %c0 ], [ 2.000000e+00, %c1 ], [ 3.000000e+00, %def ]
  %r = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
