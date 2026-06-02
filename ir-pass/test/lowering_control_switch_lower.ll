; lowering_control_switch_lower.ll — Phase 4.1 WP15 (PRD §8.2, epic `-aht.1`),
; positive. A tainted-scrutinee `switch i32 %u` with a clean VALUE-merge
; (empty `break`-terminated arms reconverging on a 3-way merge `φ` over
; constants) is rewritten — BEFORE control-region detection — into `icmp eq`
; flags + a nested `select` chain, which the EXISTING select-mux path lowers
; with zero new lowering code. This supersedes the WP12 diagnostic for the
; value-merge shape (the side-effecting/gated shape — lowering_control_switch.ll
; — still diagnoses). Mutual exclusivity of the eq-flags makes the nesting
; order-independent and correct.
;
;   switch %u {1:10, 2:20, default:99}  ⇒  f1 = (u==1); f2 = (u==2)
;                                           sel1 = f1 ? 10 : 99   (default base)
;                                           sel2 = f2 ? 20 : sel1
;
; Lowering: f1/f2 → `icmp_eq_<W>_hl` flags; sel1 [classical,classical] →
; `cqrt_alloc(99)` + `add_hl_controlled(f1, ·, 10−99=−89)`; sel2 (mixed mux.1,
; the false arm is the tainted sel1 handle) → `cqrt_alloc(20)` + a ¬f2 `cqrt_x`
; bracket around `add_controlled(f2, ·, sel1−20)`. Each flag is uncomputed
; (`icmp_eq_<W>_hl_inv`) at its region boundary. No residual `switch`/`phi`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 2)
; CHECK:     call i32 @cqrt_alloc_i32(i32 99)
; CHECK:     call i32 @cq_template_add_i32_hl_controlled(i32 %[[F1]], i32 %{{[a-zA-Z0-9_.]+}}, i32 -89)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[H]], i32 1)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 20)
; CHECK:     call i32 @cqrt_alloc_i32(i32 20)
; CHECK:     call void @cqrt_x(i32 %[[F2]])
; CHECK:     call i32 @cq_template_add_i32_controlled(i32 %[[F2]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[D]])
; CHECK:     call void @cqrt_x(i32 %[[F2]])
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[H]], i32 2)
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: switch
; CHECK-NOT: phi
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %u, label %dflt [
    i32 1, label %c1
    i32 2, label %c2
  ]
c1:
  br label %merge
c2:
  br label %merge
dflt:
  br label %merge
merge:
  %y = phi i32 [ 10, %c1 ], [ 20, %c2 ], [ 99, %dflt ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
