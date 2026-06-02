; lowering_control_multiway_if.ll — Phase 4.1 §8.3 (epic `-aht.1`), positive.
; The multi-way value `if/else if/else` "comes along for free": when `-O1`
; emits the value dispatch as a nested `select` chain DIRECTLY (no `switch`),
; it is byte-for-byte the same normal form WP15's `normalizeTaintedSwitch`
; produces — so the EXISTING select-mux path (`dissolveSelect`) lowers it with
; no extra code. This pins that a directly-`-O1`-emitted N-way chain lowers
; identically to the switch-sourced one (lowering_control_switch_lower.ll),
; closing the general N-way value-merge case Phase 4.3 left to 4.1.
;
;   y = (u==1) ? 10 : ((u==2) ? 20 : 99)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 2)
; CHECK:     call i32 @cqrt_alloc_i32(i32 99)
; CHECK:     call i32 @cq_template_add_i32_hl_controlled(
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp eq i32 %u, 1
  %c2 = icmp eq i32 %u, 2
  %inner = select i1 %c2, i32 20, i32 99
  %y = select i1 %c1, i32 10, i32 %inner
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
