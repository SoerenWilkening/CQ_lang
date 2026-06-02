; lowering_control_switch_gated_emptydefault.ll — Phase 4.x WP18 follow-on
; (test_C_libtooling-509), POSITIVE. When the `default` arm is empty
; (`default: break;`), `clang -O1` routes the default edge STRAIGHT to the merge
; (no distinct default block), so the merge gains a predecessor that is the
; switch block itself. The gated-switch detection now recovers the common merge
; from the CASE arms and recognizes this default-direct-to-merge shape
; (`region.SwitchDefaultDirect`).
;
; LOWERING: each case gate becomes `_controlled` on its eq-flag, exactly as the
; distinct-default form. Because the default has NO gate body, the "no case
; matched" control is implicit (the absence of any case gate) — so the OR-fold
; ancillas (`cqrt_alloc_i1` + `cqrt_toffoli`) and the ¬OR default substitution
; are SKIPPED entirely. The N-way handle φ dissolves to the in-place handle; the
; per-case eq-flags uncompute reverse-LIFO; the switch is linearized away. (Was a
; first-cut boundary the WP12 guard diagnosed; this lowers it.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[HV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ:[a-zA-Z0-9_.]+]], i32 1)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 2)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[HV]], double 1.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HV]], double 2.000000e-01)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 2)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 1)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[HV]])
; No OR-fold ancillas for an empty default, and no residual switch/phi:
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
  switch i32 %q, label %merge [
    i32 1, label %c1
    i32 2, label %c2
  ]
c1:
  %v1 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c2:
  %v2 = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  br label %merge
merge:
  %vm = phi i32 [ %v, %entry ], [ %v1, %c1 ], [ %v2, %c2 ]
  %m = call i32 @cq_measure_si32(i32 %vm)
  ret i32 %m
}
