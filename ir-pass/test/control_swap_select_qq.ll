; control_swap_select_qq.ll — ACCEPT: tainted-condition integer-data `select`,
; TWO quantum operands (the §5b shape). Graduated from
; control_swap_defer_select_qq.ll (Rule 12 deliberate baseline).
;
; `(q>5) ? q : q+1` — both operands are tainted handles, `%q1 = q+1` a FRESH
; out-of-place value (distinct lineage, gate 6 accepts; add is a basis
; permutation not a coherence-creating gate, gate 5 accepts). The stream is §5a
; with NO materialization: both copies read existing handles (`%q` and the
; lowered `cq_template_add_i32_hl` result), confirming `materialize` is the
; identity on a quantum handle and emits NO cqrt_alloc for a quantum operand.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q1  = add nsw i32 %q, 1                 ; fresh out-of-place tainted operand
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 %q1
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; both operands are handles — the false operand is the distinct add result:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[Q1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 1)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q1]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; both copies read existing handles — NO cqrt_alloc for a quantum operand:
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; CHECK-NOT: cqrt_ry{{.*}}_controlled
; CHECK-NOT: phi i32

; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
