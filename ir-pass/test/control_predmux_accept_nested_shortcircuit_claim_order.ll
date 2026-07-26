; control_predmux_accept_nested_shortcircuit_claim_order.ll — ACCEPT, and a
; deliberately RECORDED BASELINE (bd q2wk, PRD §4.4b Cost note 2).
;
; This input compiles to a CORRECT circuit both before and after increment 5 —
; it is here because Inc 5 changed WHICH region PredMux claims first, and that
; makes the emitted circuit materially BIGGER. Nothing in the suite pinned that,
; so the change was invisible; the Rule-13 round found it by construction and
; this fixture is the pin.
;
; THE SHIFT. PredMux claims one region per call, scanning blocks in function
; order. BEFORE Inc 5 the OUTER region (entry → merge) held `br i1 %p` on an i1
; phi, so it left at `E6-condtree`; the scan fell through to the INNER
; short-circuit region {sc, rhs} → j1, which converted %p with BP(sc) = ⊤ — no
; edge-predicate network materialized at all — and the outer region picked up the
; already-simplified tree on the next fixpoint round. AFTER Inc 5 the outer
; region passes E6 and is claimed FIRST, swallowing the nest, so BP(j1) =
; EP(sc→rhs) ∨ EP(sc→j1) becomes real gates.
;
; MEASURED on this exact input (BEFORE → AFTER): cqrt_toffoli 5 → 13,
; cqrt_cnot 0 → 5, cqrt_alloc_i1 3 → 7; the OR-network reconstruction is the
; cnot/cnot/toffoli triple plus the extra conjunction ancillae. Both circuits
; were hand-verified to compute the identical predicate
; (g6=c0∧c1, g8=c0∧¬c1, g9=g6∨g8=c0, g11=c0∧c1∧c2, g12=g9∧g11=c0∧c1∧c2), so this
; is an EMISSION change, not a correctness one — the qubits-not-scarce,
; trace-only regime makes it a cost, not a defect.
;
; It is DISCLOSED rather than fixed: the fix is to prefer the INNERMOST claimable
; region in `flattenPredMuxRegions`, which is a driver-wide claim-order change
; affecting every shape and needing its own Rule-13 clearance. Filed as an
; optimization follow-on. If that lands, THIS FIXTURE'S EXPECTATIONS SHOULD SHRINK
; back toward the BEFORE stream — regenerate it deliberately and say so, do not
; treat a smaller stream here as a regression.
;
; The inner region satisfies the W witness on its own (its merge %j1 carries two
; phis), which is what makes the claim order observable at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 5
  br i1 %c0, label %sc, label %merge
sc:
  %c1 = icmp slt i32 %q, 3
  br i1 %c1, label %rhs, label %j1
rhs:
  %c2 = icmp eq i32 %q, 7
  %e2 = add i32 %q, 9
  br label %j1
j1:                                   ; 2 merge phis ⇒ the inner region is
  %p  = phi i1  [ false, %sc ], [ %c2, %rhs ]   ; W-witnessed on its own
  %pe = phi i32 [ 4, %sc ], [ %e2, %rhs ]
  br i1 %p, label %ta, label %tb
ta:
  %v1 = add i32 %pe, 1
  br label %merge
tb:
  %v2 = mul i32 %pe, 2
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %v1, %ta ], [ %v2, %tb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; The five compare leaves and both De Morgan inversions (the no-NOT invariant):
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
;
; The OR-network reconstruction of BP(j1) is what the outer-first claim
; materializes and the inner-first claim used to fold away — its cnot pair is the
; signature of this baseline (a2b0-style a⊕b⊕ab), absent from the BEFORE stream:
; CHECK-DAG: call void @cqrt_cnot(
; CHECK-DAG: call void @cqrt_toffoli(
; CHECK-DAG: call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
;
; CHECK-NOT: br i1
; CHECK-NOT: phi
; CHECK-NOT: select i1
