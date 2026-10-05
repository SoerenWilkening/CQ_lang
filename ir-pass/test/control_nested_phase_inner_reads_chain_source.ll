; control_nested_phase_inner_reads_chain_source.ll — ACCEPT (bd
; test_C_libtooling-7xsh). The i32 twin of control_swap_nested_phase_derived.ll,
; in the shape bd 7xsh recorded: a depth-2 phase nest whose OUTER condition is a
; DERIVED chain `d = q*3` and whose INNER compare reads the chain's SOURCE `q`.
; Hand IR on purpose: `clang -O1` folds `q*3 > 5` to `q > 1` (an integer derived
; compare exercises nothing from C; the f64 twin is the C-derived witness).
;
; THE LEAK THIS FIXES. `d` is an M-B interior rail (consumers: the outer mint and
; the outer strip), discharged after the outer strip with `q` BORROWED. Clause (d)
; (`borrowedParentsUnmoved`) proves `q`'s label unmoved over the window
; [mul, outer strip], and refused the INNER strip `icmp_slt_i32_hl_unc(f2, q, 9)`
; as a mutation of `q` (`preservesBorrowedParent` admitted no `_unc`). Measured by
; instrumentation, not inferred: that strip was the ONLY refused user. `d` stood
; allocated and entangled with `q` (stage 2b: 1 template rail left dirty).
;
; WHY ADMITTING THE STRIP IS SOUND. The strip XORs [q<9] onto its slot-0 flag and
; READS `q`: it is Σ_v |v><v|_q ⊗ X_f2^{[v<9]}, block-diagonal in q's basis, so q's
; label is unchanged — all clause (d) asks. It is admitted only as an
; emitter-RECORDED strip (`DischargedFlagGates`) reading `q` outside slot 0
; (`isRecordedStripReaderOf`, the predicate `isInteriorConsumer` clause (c) uses).
; The leak twin, lowering_uncompute_interior_leak_unrecorded_strip_reads_parent.ll,
; keeps an UNRECORDED `_unc` reading the parent refused.
;
; HAND TRACE OF THE STREAM BELOW, Ry(.5)|u0> = Σ_v a_v|v> on q:
;   mul_hl(q,3)               r = 3v
;   icmp_sgt_hl(r,5)          f1 = [3v>5];  rz_i1(f1,b): phase e^{±ib/2} by f1
;   icmp_slt_hl(q,9)          f2 = [v<9];   g = f1∧f2 (toffoli), rz_i1(g,a),
;                             toffoli back, g = 0, free(g)
;   icmp_slt_hl_unc(f2,q,9)   f2 = 0 (q unmoved), free(f2)
;   icmp_sgt_hl_unc(f1,r,5)   f1 = 0
;   mul_hl_unc(r,q,3)         r = 3v ⊕ 3v = 0: q's label is v throughout the
;                             window (only label readers of q ran in it)
;   free(r), free(f1)         both |0> in a product state — nothing learned
;   measure(q)                Σ_v a_v e^{iφ(v)}|v>: P(v) = |a_v|^2, phases kept
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = mul i32 %q, 3
  %c1 = icmp sgt i32 %d, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK-LABEL: define i32 @example(i32 %u0, double %a, double %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT:  %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[D]], i32 5)
; CHECK-NEXT:  call void @cqrt_rz_i1(i32 %[[F1]], double %b)
; CHECK-NEXT:  %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT:  %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_rz_i1(i32 %[[G]], double %a)
; CHECK-NEXT:  call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[D]], i32 5)
; The derived chain, discharged after its last reader (the outer strip) against
; the unmoved source:
; CHECK-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 3)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  ret i32 %[[M]]

; Exactly four frees (g, f2, the chain rail d, f1); the source is never freed.
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
