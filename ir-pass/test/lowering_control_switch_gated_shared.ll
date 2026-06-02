; lowering_control_switch_gated_shared.ll — Phase 4.x WP18 follow-on
; (test_C_libtooling-6qg), POSITIVE. A gated multi-arm `switch` with a SHARED arm
; block: two case values (1 and 3) target ONE body block (`clang` folds
; duplicate-body cases into a single block, so the remaining case set is sparse).
; The first WP18 cut declined this (one case-constant per arm); now the per-arm
; representation carries a case SET and the arm is controlled on the OR of its
; cases' eq-flags.
;
; Lowering (`lowerGatedSwitch`): eq-flags `f1=(q==1)`, `f3=(q==3)`, `f2=(q==2)`;
; the shared arm's flag is the OR-fold `f1∨f3` (one `cqrt_toffoli` De-Morgan
; bracket); the default fires on ¬((f1∨f3)∨f2) (a SECOND OR-fold over the arm
; flags, then a `cqrt_x` "none matched" bracket). The shared arm's `cq_phi` gate
; becomes `cqrt_rz_i32_controlled` on `f1∨f3` (so it fires for BOTH q==1 and
; q==3 — they share the body); case 2 on its own eq-flag; the default on ¬OR.
; The φ dissolves to the in-place handle; the OR-folds + compares uncompute
; reverse-LIFO; the switch is linearized away.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[HV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; Three per-case eq-flags — the shared arm contributes TWO (q==1, q==3):
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ:[a-zA-Z0-9_.]+]], i32 1)
; CHECK:     %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 3)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 2)
; The shared arm's OR-of-cases flag f1∨f3 (De-Morgan: ¬(¬f1∧¬f3)):
; CHECK:     %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F3]], i32 %[[FA]])
; The default's "none matched" OR over the arm flags ((f1∨f3)∨f2):
; CHECK:     %[[FO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[FA]], i32 %[[F2]], i32 %[[FO]])
; Default gate on ¬OR (cqrt_x bracket), then the shared arm on f1∨f3, case 2 on f2:
; CHECK:     call void @cqrt_x(i32 %[[FO]])
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FO]], i32 %[[HV]], double 9.000000e-01)
; CHECK:     call void @cqrt_x(i32 %[[FO]])
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FA]], i32 %[[HV]], double 1.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HV]], double 2.000000e-01)
; Uncompute: both OR-folds (reverse), then all three eq-compares (reverse):
; CHECK:     call void @cqrt_toffoli_inv(i32 %[[FA]], i32 %[[F2]], i32 %[[FO]])
; CHECK:     call void @cqrt_toffoli_inv(i32 %[[F1]], i32 %[[F3]], i32 %[[FA]])
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 2)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 3)
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
    i32 1, label %shared
    i32 3, label %shared
    i32 2, label %c2
  ]
shared:
  %v1 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c2:
  %v2 = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  br label %merge
dflt:
  %vd = call i32 @cq_phi_si32(i32 %v, double 9.000000e-01)
  br label %merge
merge:
  %vm = phi i32 [ %v1, %shared ], [ %v2, %c2 ], [ %vd, %dflt ]
  %m = call i32 @cq_measure_si32(i32 %vm)
  ret i32 %m
}
