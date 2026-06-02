; lowering_control_angle_switch.ll — Phase 4.1 WP16 (PRD §8.4, epic `-aht.1`),
; positive. The angle-parameter slice of N-way dispatch: a `switch`/`if-else-if`
; whose arms differ only in a ROTATION ANGLE. `-O1` sinks it to
; `rz(u, <select-chain over q>)` — the WP10 angle-select generalized from a
; single select to a CHAIN. Ry/Rz are angle-additive and the eq-flags are
; mutually exclusive, so the nested select equals `a_default + Σ_k f_k·(a_k −
; a_default)`: an unconditional base `Rz(a_default)` plus one
; flag-controlled-difference `Rz(a_k − a_default)` per case, each in its own
; compare compute/uncompute bracket.
;
;   ang = (u==2) ? a2 : ((u==1) ? a1 : ad)   ; feeds rz(u, ang)
;
; The chain head (consumed by the rotation) owns the lowering; the inner select
; is skipped at detection and dissolved by the head's chain walk. Single-select
; angle fixtures (lowering_control_angle_rotdiff.ll) are unaffected — their
; false arm is the base angle, not a select, so they take the WP10 path.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double
; CHECK:     call void @cqrt_rz_i32(i32 %[[H]], double %ad)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 2)
; CHECK:     %[[D2:[a-zA-Z0-9_.]+]] = fsub double %a2, %ad
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[H]], double %[[D2]])
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[H]], i32 2)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK:     %[[D1:[a-zA-Z0-9_.]+]] = fsub double %a1, %ad
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[H]], double %[[D1]])
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[H]], i32 1)
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a1, double %a2, double %ad) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp eq i32 %u, 1
  %c2 = icmp eq i32 %u, 2
  %inner = select i1 %c1, double %a1, double %ad   ; inner chain member
  %ang = select i1 %c2, double %a2, double %inner  ; head — feeds the rotation
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
