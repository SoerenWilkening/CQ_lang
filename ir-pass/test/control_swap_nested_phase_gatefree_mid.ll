; control_swap_nested_phase_gatefree_mid.ll — ACCEPT spec (§3.1 step-6 GATE-FREE
; Mid degenerate; was control_swap_defer_nested.ll, converted at WI-3 / MD3).
;
; `if (q > 5) { if (q > 3) { rz(q, a); } }`. The outer arm block (%mid) holds a
; second tainted-condition `br` but NO intervening gate — the inner condition
; reads the UN-gated %q directly (criterion-5 mint-from-rail is satisfied trivially:
; the inner cond reads exactly the routed %q, which lives on rail1 post-route-in).
; Criterion 6 (tree homogeneity) holds VACUOUSLY over the empty Mid gate set, so
; this ACCEPTS. Through WI-1/WI-2 it declined transitionally `nested control flow`
; (no emitter); WI-3 lands NestedRouteEmit and it now LOWERS — the distinctive
; shape: outer route-in with NO intervening cqrt_rz before the inner mint, the
; rail/rotation WIDTH recovered from the inner-arm gate (Mid contributes none).
; ZERO controlled gates, NO cqrt_toffoli, NO phi i32, EXACTLY FOUR cqrt_free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %c2 = icmp sgt i32 %q, 3
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; 1 outer mint + route-in
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; 3 inner mint FROM RAIL1 — NO intervening cqrt_rz (gate-free Mid)
; CHECK-NOT: call void @cqrt_rz
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R1]], i32 3)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[R1]], i32 %[[R2]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R2]], double %a)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[R1]], i32 %[[R2]])
; 4 inner clean-up (LIFO): free rail2, STRIP f2 vs rail1, free f2
; CHECK:     call void @cqrt_free(i32 %[[R2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[R1]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; 5 outer route-back + clean-up
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; CHECK:     call void @cqrt_free(i32 %[[R1]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

; Hard postconditions.
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: phi i32

; Exactly four frees (rail2, %f2, rail1, %f1) — no fifth from uncompute.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; CNT-COUNT-4: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
