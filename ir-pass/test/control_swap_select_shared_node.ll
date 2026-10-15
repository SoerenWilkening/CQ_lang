; control_swap_select_shared_node.ll — ACCEPT (3c6m.12 design-review probe): a
; shared INTERIOR node (DAG) — `and(%o, or(%o, %c3))` reuses the or-node `%o`
; both as the root's left control and inside the right child. The node's
; ancilla mints ONCE (per-Value memo) and is a READ-ONLY control of the right
; child's network and the root's toffoli; the strip visits each UNIQUE node
; exactly once in reverse post-order (one inverse network + one free per
; ancilla — the double-free/hidden-measurement hazard the review named is
; structurally excluded by the deduped mint/strip lists).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp slt i32 %q, 100
  %o   = or i1 %c1, %c2
  %c3  = icmp eq i32 %q, 42
  %o2  = or i1 %o, %c3                     ; right child reuses node %o
  %cc  = and i1 %o, %o2                    ; root reuses node %o again
  %sel = select i1 %cc, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; the shared node %o mints its ancilla EXACTLY ONCE:
; CHECK:     %[[GO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[GO]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[GO]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[GO]])
; CHECK:     %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 42)
; CHECK:     %[[GO2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[GO]], i32 %[[GO2]])
; CHECK:     call void @cqrt_cnot(i32 %[[F3]], i32 %[[GO2]])
; CHECK:     call void @cqrt_toffoli(i32 %[[GO]], i32 %[[F3]], i32 %[[GO2]])
; CHECK:     %[[GR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[GO]], i32 %[[GO2]], i32 %[[GR]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[GR]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[GR]])
; CHECK:     call void @cqrt_xorc_i32_controlled(i32 %[[GR]], i32 %[[OUT]], i32 {{.+}})
; CHECK:     call void @cqrt_x(i32 %[[GR]])
; LIFO: root, then o2, then the SHARED o exactly once, then leaves reversed:
; CHECK:     call void @cqrt_toffoli(i32 %[[GO]], i32 %[[GO2]], i32 %[[GR]])
; CHECK:     call void @cqrt_free(i32 %[[GR]])
; CHECK:     call void @cqrt_toffoli(i32 %[[GO]], i32 %[[F3]], i32 %[[GO2]])
; CHECK:     call void @cqrt_cnot(i32 %[[F3]], i32 %[[GO2]])
; CHECK:     call void @cqrt_cnot(i32 %[[GO]], i32 %[[GO2]])
; CHECK:     call void @cqrt_free(i32 %[[GO2]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[GO]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[GO]])
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[GO]])
; CHECK:     call void @cqrt_free(i32 %[[GO]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F3]], i32 %[[Q]], i32 42)
; CHECK:     call void @cqrt_free(i32 %[[F3]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 100)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no second alloc/inverse/free for the shared node after the region (CALL
; forms — the module-appended `declare` lines legitimately name the symbols):
; CHECK-NOT: call i32 @cqrt_alloc_i1
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: select i1
