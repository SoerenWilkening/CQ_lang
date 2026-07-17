; control_swap_select_qqcond.ll — ACCEPT (bd adia, 3c6m.55 Lever C): a
; tainted-condition integer-data `select` whose condition is a Q+Q compare
; (BOTH operands tainted). `(q > y) ? q : x` with `%q`/`%y` both theta
; handles mints the QQ flag `cq_template_icmp_sgt_i32(h_q, h_y)` — the 7.1
; Q+Q data-compare template (frozen, `_inv`/`_unc` twins; NO new symbol) —
; then the ordinary 4.4 two-copy merge and the `_inv` strip + proven-|0> free.
;
; Formerly control_swap_reject_select_qqcond.ll (the pre-adia HL-only gate-2b
; decline).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp sgt i32 %q, %y                ; Q+Q condition (both tainted)
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_sgt_i32(i32 %[[HQ:.*]], i32 %[[HY:.*]])
; CHECK-NEXT: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[HQ]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[XS:.*]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[XS]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call i32 @cq_template_icmp_sgt_i32_inv(i32 %[[HQ]], i32 %[[HY]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[OUT]])
