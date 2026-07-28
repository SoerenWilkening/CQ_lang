; control_swap_select_or2.ll — ACCEPT (3c6m.12 L4): a compound `or i1` condition
; over TWO HL-lowerable tainted compares on ONE wire — the `(q>5 || q<100)?a:b`
; clang -O1 fold (compound-cond-select-PRD §2/§3). The root flag is a COMPUTED
; conjunction rail: per-leaf `cq_template_icmp_*_hl` flags, one `|0⟩` i1 ancilla,
; the input-preserving OR network `cnot(f1,g); cnot(f2,g); toffoli(f1,f2,g)`
; (g = f1⊕f2⊕f1f2 = f1∨f2 — controls are READ-ONLY; no transient X on the leaf
; rails). The copies ride the root exactly as the single-flag §16.3 proof; the
; strip is exact LIFO — inverse network, free the ancilla, then `_inv` strips in
; REVERSE mint order (f2 first), each followed by its free. Ordered CHECKs pin
; the network order, the §16.3 bracket order, AND the LIFO strip order — all
; verify-clean-invisible if permuted (Rule 2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp slt i32 %q, 100
  %c   = or i1 %c1, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; leaf flags, mint order = post-order leaf discovery (c1 then c2):
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; the OR node ancilla + input-preserving network:
; CHECK:     %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; the §16.3 merge on the ROOT flag (bracket encloses ONLY the false copy):
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; exact-LIFO strip: inverse network first (toffoli, then cnots in reverse), free
; the ancilla, THEN the leaf strips in reverse mint order (f2 before f1):
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_free(i32 %[[G]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 100)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; the dead `or`/compares are cascade-erased; no data-path or_i1 template fires:
; CHECK-NOT: cq_template_or_i1
; CHECK-NOT: select i1
