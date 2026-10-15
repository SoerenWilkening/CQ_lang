; control_swap_select_freeze_folded.ll — ACCEPT (3c6m.12 L4 probe, measured
; behavior): a foldable i1 `freeze` around one leaf of a compound condition.
; The 7.1 Increment-B integer-freeze fold (`isLocalIntegerIdentityFreeze`,
; declineTaintEscapes) RAUWs the identity freeze away BEFORE detection, so the
; tree walk sees the plain `or(c1, c2)` and the region lowers as the standard
; compound stream. An UNFOLDABLE integer freeze (operand independently
; escaped / result would escape) never reaches the walk either — it declines
; at the escape guard (`lowering_reject_freeze_escaped_return.ll` /
; `lowering_reject_freeze_measured_fanout.ll`); `collectCondTree`'s freeze
; rejection is defense-in-depth only (compound-cond-select-PRD §4).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c1f = freeze i1 %c1
  %c2  = icmp slt i32 %q, 100
  %c   = or i1 %c1f, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; CHECK:     %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     call void @cqrt_xorc_i32_controlled(i32 %[[G]], i32 %[[OUT]], i32 {{.+}})
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     call void @cqrt_free(i32 %[[G]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; the freeze is GONE — folded, not lowered and not declined:
; CHECK-NOT: freeze
; CHECK-NOT: select i1
