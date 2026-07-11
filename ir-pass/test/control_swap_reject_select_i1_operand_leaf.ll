; control_swap_reject_select_i1_operand_leaf.ll — DECLINE (3c6m.12
; design-review MINOR — the boolean-NOT evasion): a leaf compare OVER i1
; values (`icmp eq i1 %c1, false` = ¬c1) would smuggle a NOT node past the
; and/or tree grammar, and its mint passes a raw i1 into the i32 handle slot —
; sound only when the inner i1 producer independently data-lowers (an
; unlowerable producer would leave an ill-typed call for the VERIFIER to catch
; instead of a loud source-located decline). Non-canonical (InstCombine
; rewrites i1 eq/ne to xor/not forms and folds the not into the predicate), so
; the i1-operand leaf fence declines it at detection.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cq_template_icmp_eq_i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %n   = icmp eq i1 %c1, false             ; i1-operand leaf = boolean NOT
  %c2  = icmp slt i32 %q, 100
  %c   = or i1 %n, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
