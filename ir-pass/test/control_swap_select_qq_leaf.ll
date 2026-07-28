; control_swap_select_qq_leaf.ll — ACCEPT (bd adia, 3c6m.55 Lever C): a Q+Q
; LEAF inside an accepted-grammar tree (`or(q0>5, q0>q1)`). The select-path
; flag mint is no longer HL-only: a both-operands-tainted leaf whose shared
; LOGICAL width resolves in-surface (`qqSelectLeafWidth` — HandleWidth-aware,
; i128/i80 fenced) mints the QQ compare template `cq_template_icmp_<pred>_<W>
; (h, h)` — the 7.1 Q+Q data-compare family, already frozen with `_inv`/`_unc`
; twins (NO new runtime symbol). The openlibm floorl mantissa test
; (`i0 > x's word`, two theta-derived words) is exactly this shape.
;
; Formerly control_swap_reject_select_qq_leaf.ll (the pre-adia HL-only
; decline); the strip still plays the exact-LIFO `_inv` twins and every flag
; rail is freed proven-|0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %x) {
entry:
  %q0  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q1  = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c1  = icmp sgt i32 %q0, 5
  %c2  = icmp sgt i32 %q0, %q1       ; Q+Q leaf — both operands tainted
  %c   = or i1 %c1, %c2
  %sel = select i1 %c, i32 %q0, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; The HL sibling leaf mints first (post-order), then the Q+Q leaf as the
; two-handle QQ form, then the OR node network onto a |0> ancilla.
; CHECK: %[[HL:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H0:.*]], i32 5)
; CHECK: %[[QQ:.*]] = call i32 @cq_template_icmp_sgt_i32(i32 %[[H0]], i32 %[[H1:.*]])
; CHECK: %[[G:.*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[HL]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[QQ]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[HL]], i32 %[[QQ]], i32 %[[G]])
; The 4.4 two-copy merge on the root flag (¬flag copy X-bracketed, §16.3).
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[H0]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %{{.*}}, i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; Exact-LIFO strip: node network self-inverse + free, then the QQ `_inv` twin,
; then the HL `_inv` twin — every flag rail freed proven-|0>.
; CHECK: call void @cqrt_toffoli(i32 %[[HL]], i32 %[[QQ]], i32 %[[G]])
; CHECK: call void @cqrt_free(i32 %[[G]])
; CHECK: call void @cq_template_icmp_sgt_i32_unc(i32 %[[QQ]], i32 %[[H0]], i32 %[[H1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[QQ]])
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[HL]], i32 %[[H0]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HL]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[OUT]])
