; lowering_control_switch_gated_emptydefault_angle.ll — Phase 4.x WP18 follow-on
; (test_C_libtooling-509) × cwk fix (b) PR3, POSITIVE. The empty-default gated
; switch (default routed STRAIGHT to merge) carrying a classical-angle merge `φ`
; dispatched per case. Exercises reduceAngleSwitchPhi's direct-default base edge:
; the base angle rides the SWITCH-BLOCK (`entry`) φ edge (`region.Pred`), not an
; `Arm` edge — `region.SwitchDefaultDirect` selects it.
;
; Net angle = base (entry/default 0.9) + per-case controlled difference, plus the
; per-case gate body; no OR-fold (empty default).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[HV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ:[a-zA-Z0-9_.]+]], i32 1)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 2)
; Per-case gate bodies:
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[HV]], double 1.100000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HV]], double 2.200000e-01)
; Angle: unconditional base (the entry/default angle 0.9), then per-case difference:
; CHECK:     call void @cqrt_rz_i32(i32 %[[HV]], double 9.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[HV]], double 0x3FB9999999999998)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HV]], double 1.100000e+00)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[HV]])
; CHECK-NOT: cqrt_alloc_i1
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: switch
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 1, label %c1
                                i32 2, label %c2 ]
c1:
  %g1 = call i32 @cq_phi_si32(i32 %v, double 1.100000e-01)
  br label %merge
c2:
  %g2 = call i32 @cq_phi_si32(i32 %v, double 2.200000e-01)
  br label %merge
merge:
  %ang = phi double [ 9.000000e-01, %entry ], [ 1.000000e+00, %c1 ], [ 2.000000e+00, %c2 ]
  %r = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
