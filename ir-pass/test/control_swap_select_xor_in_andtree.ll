; control_swap_select_xor_in_andtree.ll — ACCEPT (bd 3c6m.67): an `xor i1` node
; NESTED inside an `and i1` tree — `((q>5) ^ (q<100)) && (q != 7)`.
;
; THIS IS THE SHAPE THE FOUR CENSUS CELLS ACTUALLY PRESENT, and the reason the
; widening had to land in BOTH grammars rather than only in the select emitter.
; PredMux flattens a claimed region into selects whose condition is
; `and(BP, lit)` — the block predicate conjoined with the edge literal — so the
; ulp-direction `xor` from `src/s_nextafterl.c:55` never reaches
; `collectCondTree` as a bare root. It arrives as an INTERIOR NODE of a bigger
; and/or tree, exactly like this. A widening that admitted only a root xor would
; have relocated the decline from the branch to the flattened select and
; measured as no progress at all.
;
; Pins the post-order emission contract across MIXED node kinds: children before
; parents on the way in (xor's ancilla G1 is complete before the and's toffoli
; reads it), and — the part that is verify-clean-invisible if permuted — the
; parent uncomputing BEFORE its children on the way out, so G1 is still
; allocated when the and-node strip reads it as a control.
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
  %cx  = xor i1 %c1, %c2
  %c3  = icmp ne i32 %q, 7
  %c   = and i1 %cx, %c3
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; post-order: the xor's two leaves, then the xor node, THEN the and's right leaf:
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; CHECK:     %[[G1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G1]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G1]])
; CHECK:     %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 7)
; the AND node reads the xor's ancilla as a control — one toffoli, and ONLY one:
; CHECK:     %[[G2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[G1]], i32 %[[F3]], i32 %[[G2]])
; the merge rides the ROOT ancilla G2:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G2]])
; CHECK:     call void @cqrt_xorc_i32_controlled(i32 %[[G2]], i32 %[[OUT]], i32 {{.+}})
; CHECK:     call void @cqrt_x(i32 %[[G2]])
; exact LIFO — the PARENT (and) strips first, while G1 is still allocated:
; CHECK:     call void @cqrt_toffoli(i32 %[[G1]], i32 %[[F3]], i32 %[[G2]])
; CHECK:     call void @cqrt_free(i32 %[[G2]])
; then the CHILD (xor): its two cnots reversed, no toffoli, then its free:
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G1]])
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G1]])
; CHECK:     call void @cqrt_free(i32 %[[G1]])
; then the leaves in reverse mint order (F3, F2, F1):
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[F3]], i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F3]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 100)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NOT: cq_template_xor_i1
; CHECK-NOT: select i1
