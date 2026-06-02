; lowering_control_switch_gated.ll — Phase 4.1 WP18 (PRD §8.5, epic `-aht.3`),
; positive. The one multi-way shape that does NOT fold into the
; switch→select-chain (WP15) or angle-select-chain (WP16): a cascade of arms
; with ARBITRARY SIDE-EFFECTING gate bodies — distinct gate SEQUENCES per case
; (case 2 applies TWO `cq_phi`s; case 1 and default one each), not a value or a
; rotation angle. There is no value to select; each arm's gates become
; `_controlled` on its eq-flag (the WP8 symmetric two-content-arm diamond
; generalized to an N-way false-arm chain). `clang -O1` keeps this as a
; `SwitchInst` with gate-body arms reconverging on an N-way φ (confirmed by the
; `-aht.3` diagnose-first spike).
;
; Lowering (`lowerGatedSwitch`): per-case eq-flags `f1=(q==1)`, `f2=(q==2)`;
; the default fires on ¬(f1∨f2) (the OR-fold `f_conj` + a `cqrt_x` bracket — the
; "none matched" control); each arm's `cq_phi` gates become
; `cqrt_rz_i32_controlled` on its flag (case 2's two gates both on `f2`); the
; N-way φ dissolves to the in-place handle; the flags uncompute reverse-LIFO
; (`cqrt_toffoli_inv` then the `_hl_inv` compares); the switch is linearized
; away. Arms are mutually exclusive, so exactly one fires per basis state — the
; switch semantics. Every flag ancilla is balanced; no residual `switch`/`phi`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[HV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 1)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 2)
; CHECK:     %[[FC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[FC]])
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FC]], i32 %[[HV]], double 9.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[HV]], double 1.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HV]], double 2.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HV]], double 3.000000e-01)
; CHECK:     call void @cqrt_toffoli_inv(i32 %[[F1]], i32 %[[F2]], i32 %[[FC]])
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 2)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 1)
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
  switch i32 %q, label %dflt [
    i32 1, label %c1
    i32 2, label %c2
  ]
c1:
  %v1 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c2:
  %v2a = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  %v2b = call i32 @cq_phi_si32(i32 %v2a, double 3.000000e-01)
  br label %merge
dflt:
  %vd = call i32 @cq_phi_si32(i32 %v, double 9.000000e-01)
  br label %merge
merge:
  %vm = phi i32 [ %v1, %c1 ], [ %v2b, %c2 ], [ %vd, %dflt ]
  %m = call i32 @cq_measure_si32(i32 %vm)
  ret i32 %m
}
