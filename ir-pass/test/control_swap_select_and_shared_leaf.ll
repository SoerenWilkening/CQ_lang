; control_swap_select_and_shared_leaf.ll — ACCEPT (3c6m.12 L4): a SHARED leaf —
; `and(or(a,b), or(a,c))` reuses compare `a` in both inner nodes (the post-CSE
; shape). The leaf mints ONCE (memoized) and its flag rail is a READ-ONLY
; control of both inner networks — safe by construction because the network
; never mutates its inputs (no transient X; compound-cond-select-PRD §1). The
; strip balances every mint exactly once: two ancilla inverses + THREE leaf
; strips (a, b, c each once).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a   = icmp sgt i32 %q, 5
  %b   = icmp slt i32 %q, 100
  %c   = icmp ne i32 %q, 42
  %o1  = or i1 %a, %b
  %o2  = or i1 %a, %c
  %cc  = and i1 %o1, %o2
  %sel = select i1 %cc, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; the shared leaf %a mints EXACTLY ONCE:
; CHECK:     %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[FB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; CHECK:     %[[G1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[FA]], i32 %[[G1]])
; CHECK:     call void @cqrt_cnot(i32 %[[FB]], i32 %[[G1]])
; CHECK:     call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G1]])
; CHECK:     %[[FC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 42)
; CHECK:     %[[G2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[FA]], i32 %[[G2]])
; CHECK:     call void @cqrt_cnot(i32 %[[FC]], i32 %[[G2]])
; CHECK:     call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FC]], i32 %[[G2]])
; the AND root:
; CHECK:     %[[GR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[G1]], i32 %[[G2]], i32 %[[GR]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[GR]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[GR]])
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[GR]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[GR]])
; LIFO strip: root toffoli + free, o2 inverse + free, o1 inverse + free, then
; leaves in reverse mint order (c, b, a) — the shared %a strips ONCE, LAST:
; CHECK:     call void @cqrt_toffoli(i32 %[[G1]], i32 %[[G2]], i32 %[[GR]])
; CHECK:     call void @cqrt_free(i32 %[[GR]])
; CHECK:     call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FC]], i32 %[[G2]])
; CHECK:     call void @cqrt_cnot(i32 %[[FC]], i32 %[[G2]])
; CHECK:     call void @cqrt_cnot(i32 %[[FA]], i32 %[[G2]])
; CHECK:     call void @cqrt_free(i32 %[[G2]])
; CHECK:     call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G1]])
; CHECK:     call void @cqrt_cnot(i32 %[[FB]], i32 %[[G1]])
; CHECK:     call void @cqrt_cnot(i32 %[[FA]], i32 %[[G1]])
; CHECK:     call void @cqrt_free(i32 %[[G1]])
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[FC]], i32 %[[Q]], i32 42)
; CHECK:     call void @cqrt_free(i32 %[[FC]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FB]], i32 %[[Q]], i32 100)
; CHECK:     call void @cqrt_free(i32 %[[FB]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FA]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[FA]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no stray re-mint of the shared leaf after the region (the strip balance above
; — exactly one sgt_inv + one free(FA) — pins the single-mint property):
; CHECK-NOT: call i32 @cq_template_icmp_sgt_i32_hl
; CHECK-NOT: select i1
