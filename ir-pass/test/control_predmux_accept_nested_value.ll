; control_predmux_accept_nested_value.ll — ACCEPT (3c6m.14 L6 Inc 1): the
; minimal PURE-VALUE depth-2 nest — `r=q+3; if(q>5){ r=q+1; if(q<9){ r=q+2; }}`
; — every arm is speculatable dataflow (no rotations/calls/stores), the merge
; phi has THREE incomings, and the outer arm hosts a nested tainted branch
; (witness W1 + W3). Today this declines `nested control flow under quantum
; control`; PredMux flattens it to edge-predicated select chains
; (PRD-3c6m.14 §4), which lower via the shipped 4.4/3c6m.12 substrate:
;   EP(entry→merge) = ¬c1 (inverted compare, sle)
;   EP(outer→merge) = c1 ∧ ¬c2 (sge)   [Toffoli conjunction]
;   EP(inner→merge) = c1 ∧ c2          [Toffoli conjunction]
;   rm = sel(EP_entry, r0, sel(EP_outer, r1, r2))
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = add i32 %q, 3
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %r1 = add i32 %q, 1
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %inner, label %merge
inner:
  %r2 = add i32 %q, 2
  br label %merge
merge:
  %rm = phi i32 [ %r0, %entry ], [ %r1, %outer ], [ %r2, %inner ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; The whole verified stream is pinned (this is the smallest PredMux fixture).
; The three arm values speculate as straight-line templates; the chain is
;   out  = (c1 ∧ q≥9) ? r1 : r2        [inner select, Toffoli conjunction]
;   out5 = (q≤5)      ? r0 : out       [outer select, inverted-leaf flag]
; — the unused fallback predicate (c1 ∧ q<9) is dead-swept, so NO slt-9
; compare and only ONE conjunction ancilla appear.
; CHECK: %u0.stable = freeze i32 %u0
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK:     %[[R0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 3)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 1)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 2)
; CHECK:     %[[C1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[NC2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 9)
; CHECK:     %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[C1]], i32 %[[NC2]], i32 %[[G]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[R1]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[R2]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     %[[NC1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[OUT5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[NC1]], i32 %[[R0]], i32 %[[OUT5]])
; CHECK:     call void @cqrt_x(i32 %[[NC1]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[NC1]], i32 %[[OUT]], i32 %[[OUT5]])
; CHECK:     call void @cqrt_x(i32 %[[NC1]])
; bd r2j3.32: the inner merge rail `%out` is the outer merge's copy source and
; has no other reader, so it is reversed right after the outer core -- its core
; re-emitted in reverse under the SAME ancilla G -- and only then does its
; network strip run (deferred), and `%out` is freed at |0>:
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[R2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[R1]], i32 %[[OUT]])
; the conjunction ancilla self-inverts and frees at |0>, then the leaves strip:
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[C1]], i32 %[[NC2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_sge_i32_hl_unc(i32 %[[NC2]], i32 %[[Q]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[NC2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[C1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK:     call void @cq_template_icmp_sle_i32_hl_unc(i32 %[[NC1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[NC1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT5]])
; No CFG diamond and no live phi/select survives:
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: select i1
