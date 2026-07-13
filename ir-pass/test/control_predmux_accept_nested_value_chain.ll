; control_predmux_accept_nested_value_chain.ll — ACCEPT (3c6m.14 L6 Inc 1):
; the exact IR previously pinned as the DECLINE
; `control_swap_reject_nested_value_pure.ll` — "declined `value-arm
; swap-route` until [the pure-value-nest] increment". 3c6m.14 IS that
; increment: PredMux flattens the depth-2 all-value nest to edge-predicated
; select chains, with the arm's CHAINED arithmetic (`q*7+11` then `*5+3`)
; speculating on derived handles and the `nsw` flags dropped (speculation
; discipline; bit-semantics unchanged — Rule 15). The reject twin (same name
; as before, now with a tainted-divisor `udiv` the E4 ladder leaves) re-pins
; the residual decline for genuinely off-target value nests.
;
;   out  = (q>5 ∧ q≥12) ? g : q      [inner select]
;   out8 = (q>5 ∧ q<12) ? h : out    [outer select]
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %t1 = mul nsw i32 %q, 7
  %g  = add nsw i32 %t1, 11
  %c2 = icmp slt i32 %q, 12
  br i1 %c2, label %arm, label %merge
arm:
  %t2 = mul nsw i32 %g, 5
  %h  = add nsw i32 %t2, 3
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; the speculated arm chain on derived handles:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[T1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 7)
; CHECK:     %[[G:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[T1]], i32 11)
; CHECK:     %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[G]], i32 5)
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[T2]], i32 3)
; inner select (q>5 ∧ q≥12) picks g over the raw source:
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 12)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[G]], i32 %[[OUT]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[Q]], i32 %[[OUT]])
; outer select (q>5 ∧ q<12) picks h over the inner out-rail:
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 12)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     %[[OUT8:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]], i32 %[[OUT8]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]], i32 %[[OUT8]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT8]])
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
