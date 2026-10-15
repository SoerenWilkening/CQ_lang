; control_swap_select_xor2.ll — ACCEPT (bd 3c6m.67): a compound `xor i1`
; condition over TWO HL-lowerable tainted compares on ONE wire — the
; `((q>5) ^ (q<100)) ? a : b` shape, which is the ULP-DIRECTION TEST openlibm's
; `src/s_nextafterl.c:55` / `s_nexttoward.c:54` / `s_nexttowardf.c:45` all use
; (`if((x>0.0) ^ (x<y))`). It is the ONE construct standing between four census
; cells and injection coverage, and NOTHING about it was ever hard: `xor` is a
; first-class frozen opcode at i1 (`tools/opcode_table.yaml`), the identical
; expression has always lowered as DATA, and the node's gate network is the OR
; node MINUS its toffoli. The exclusion was an ABSENCE OF A DECISION, not a
; decision — `collectCondTree`'s one-line `// off-grammar: xor / freeze / …`
; bail carried no rationale, in a function that documents its other two fences
; at 25 and 20 lines apiece (bd big5).
;
; THE NETWORK, and why it needs no new proof obligation. Per node the emitter
; mints a fresh `|0⟩` i1 ancilla G and computes onto it:
;   AND:  toffoli(L,Rv,G)                          G = L∧Rv
;   OR :  cnot(L,G); cnot(Rv,G); toffoli(L,Rv,G)   G = L⊕Rv⊕L·Rv = L∨Rv
;   XOR:  cnot(L,G); cnot(Rv,G)                    G = L⊕Rv        <-- STRICTLY
;                                                                      FEWER
; Controls stay READ-ONLY (no transient X on a leaf rail), both CNOTs are
; self-inverse, and the §5 reverse strip returns G to |0⟩ EXACTLY — so Rule 6
; holds by the SAME argument as OR, with one fewer gate to make it about.
;
; Ordered CHECKs pin the network order, the §16.3 bracket order AND the exact-
; LIFO strip order; every one of those is verify-clean-invisible if permuted
; (Rule 2). The `CHECK-NOT: cqrt_toffoli` is the load-bearing one: an XOR node
; that emitted OR's toffoli would compute `L∨Rv` and still verify, still print a
; plausible trace, and still pair every free — the textbook silent miscompile.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WHOLE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp slt i32 %q, 100
  %c   = xor i1 %c1, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; leaf flags, mint order = post-order leaf discovery (c1 then c2):
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; the XOR node ancilla + its input-preserving network — TWO cnots, NO toffoli:
; CHECK:     %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; the §16.3 merge on the ROOT flag (bracket encloses ONLY the false copy):
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     call void @cqrt_xorc_i32_controlled(i32 %[[G]], i32 %[[OUT]], i32 %x)
; CHECK:     call void @cqrt_x(i32 %[[G]])
; exact-LIFO strip: the inverse network (the two cnots in REVERSE, still no
; toffoli), free the ancilla, THEN the leaf strips in reverse mint order:
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_free(i32 %[[G]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 100)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
;
; WHOLE-FILE negatives (own prefix so they scan the ENTIRE module, not just the
; tail after the last positive CHECK — a trailing CHECK-NOT would have proved
; nothing about the network above it, which is exactly where a stray toffoli
; would sit). An XOR node emits NO toffoli ANYWHERE — that is the whole point of
; the node case — and the dead `xor`/compares are cascade-erased rather than
; lowered into the trace as a data-path op.
; WHOLE-NOT: cqrt_toffoli
; WHOLE-NOT: cq_template_xor_i1
; WHOLE-NOT: select i1
