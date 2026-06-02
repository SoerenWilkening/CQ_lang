; lowering_control_switch_gated_shared_angle.ll — Phase 4.x WP18 follow-on
; (test_C_libtooling-6qg) × cwk fix (b) PR3, POSITIVE. A SHARED arm block (cases
; 1 and 5 fold onto one body) dispatching a rotation ANGLE, with an EMPTY default
; routed straight to the merge (`switch …, label %merge`). Composes the shared-arm
; case-set (6qg) with the angle controlled-rotation-by-difference reducer
; (`reduceAngleSwitchPhi`) and the direct-default base edge (test_C_libtooling-509).
;
; The shared arm's controlled-difference rotation fires on the OR of its cases'
; eq-flags (q==1 ∨ q==5), so q∈{1,5} get the SAME angle 1.0 (they share the body).
; Net angle = base (entry/default 0.9) + (q∈{1,5})·(1.0−0.9) + (q==2)·(2.0−0.9).
; Empty default ⇒ only the per-ARM OR-fold is emitted (no default ¬OR fold).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[HV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; Shared arm's two eq-flags (q==1, q==5) + case 2 (q==2):
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ:[a-zA-Z0-9_.]+]], i32 1)
; CHECK:     %[[F5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 5)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 2)
; The shared arm's OR-of-cases flag f1∨f5 — the ONLY OR-fold (empty default):
; CHECK:     %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F5]], i32 %[[FA]])
; Angle: unconditional base 0.9, shared-arm difference on f1∨f5, case-2 difference on f2:
; CHECK:     call void @cqrt_rz_i32(i32 %[[HV]], double 9.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FA]], i32 %[[HV]], double 0x3FB9999999999998)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HV]], double 1.100000e+00)
; CHECK:     call void @cqrt_toffoli_inv(i32 %[[F1]], i32 %[[F5]], i32 %[[FA]])
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
  switch i32 %q, label %merge [ i32 1, label %shared
                                i32 5, label %shared
                                i32 2, label %c2 ]
shared:
  br label %merge
c2:
  br label %merge
merge:
  %ang = phi double [ 9.000000e-01, %entry ], [ 1.000000e+00, %shared ], [ 2.000000e+00, %c2 ]
  %r = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
