; control_swap_select_or3_tree.ll — ACCEPT (3c6m.12 L4): the two-node condition
; TREE clang -O1 emits for a 3-way `||` — `or(%c3, or(%c1, %c2))` (root's LEFT
; child is the third compare, RIGHT child the inner node; measured shape,
; compound-cond-select-PRD §0). Pins the recursion: post-order mint (f3, then
; f1/f2, then the INNER ancilla g1, then the ROOT ancilla g2 whose network reads
; f3 and g1), and the exact-LIFO strip — root inverse first (g1 still allocated
; when the root's toffoli fires), then the inner node, then leaves in reverse
; mint order.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp slt i32 %q, 10
  %c2  = icmp sgt i32 %q, 90
  %c12 = or i1 %c1, %c2
  %c3  = icmp eq i32 %q, 50
  %c   = or i1 %c3, %c12
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; post-order: root's LEFT leaf c3 first, then the inner node's leaves c1/c2:
; CHECK:     %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 50)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 10)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 90)
; inner OR node:
; CHECK:     %[[G1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G1]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G1]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G1]])
; root OR node reads f3 and the INNER rail g1:
; CHECK:     %[[G2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F3]], i32 %[[G2]])
; CHECK:     call void @cqrt_cnot(i32 %[[G1]], i32 %[[G2]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F3]], i32 %[[G1]], i32 %[[G2]])
; merge on the root rail:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G2]])
; CHECK:     call void @cqrt_xorc_i32_controlled(i32 %[[G2]], i32 %[[OUT]], i32 %x)
; CHECK:     call void @cqrt_x(i32 %[[G2]])
; LIFO: root inverse (g1 alive), free g2; inner inverse, free g1; leaves reverse:
; CHECK:     call void @cqrt_toffoli(i32 %[[F3]], i32 %[[G1]], i32 %[[G2]])
; CHECK:     call void @cqrt_cnot(i32 %[[G1]], i32 %[[G2]])
; CHECK:     call void @cqrt_cnot(i32 %[[F3]], i32 %[[G2]])
; CHECK:     call void @cqrt_free(i32 %[[G2]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G1]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G1]])
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G1]])
; CHECK:     call void @cqrt_free(i32 %[[G1]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 90)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 10)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F3]], i32 %[[Q]], i32 50)
; CHECK:     call void @cqrt_free(i32 %[[F3]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NOT: cq_template_or_i1
; CHECK-NOT: select i1
