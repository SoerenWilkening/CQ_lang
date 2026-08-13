; control_predmux_accept_i1phi_branch_chained.ll — ACCEPT (3c6m.14 L6 Inc 5,
; bd q2wk; PRD §4.4b sub-rule (A), the RECURSIVE case). Two SEQUENTIAL
; short-circuit diamonds chained into `(c1 && c2) || c3`, exactly as clang -O1
; leaves a `||` it did not if-convert: `%p1 = phi i1 [false,%sc],[%c2,%rhs1]`
; feeds `br i1 %p1`, and the second join's `%p2 = phi i1 [%p1,%j1],[%c3,%rhs2]`
; feeds `br i1 %p2`. So an i1 phi used as a BRANCH CONDITION has ANOTHER
; region-internal i1 phi among its incomings.
;
; What this pins that the non-chained accept (control_predmux_accept_i1phi_cond.ll)
; cannot: `isConvertiblePhiCond` must RECURSE through a nested phi — its
; per-incoming check is the STRICT `isBooleanCondTree`, and Inc 5 threads the
; same `PhiCondScope` into it so a phi incoming is itself adjudicated by
; `isConvertiblePhiCond`. That recursion is what keeps CLAIM and EMIT in step:
; at CLAIM time %p1 is still a phi (so the grammar must admit a phi node), while
; at EMIT time `convertPhis` has already RAUW'd %p1 to its and/or tree (so the
; emit-side grammar sees a plain boolean tree). Drop the recursion and the claim
; rejects a shape the emitter handles fine — the two must not diverge in EITHER
; direction, since a claim the emitter cannot honour is a broken module, not a
; decline (PRD §4.4b conditions 1–4).
;
; %p1's parent %j1 is inside the region and is NOT the region entry (%entry is),
; so PredMux's `run()` really does convert it — condition 2 holds for both phis.
;
; BEFORE Inc 5 this declined at gate E6-condtree on `br i1 %p1` (a phi is not a
; condition-tree node), surfacing as `nested control flow under quantum control`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi i1'  --implicit-check-not='phi i32' --implicit-check-not='select i1' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 5
  br i1 %c0, label %sc, label %merge
sc:
  %c1 = icmp slt i32 %q, 3
  br i1 %c1, label %rhs1, label %j1
rhs1:
  %c2 = icmp eq i32 %q, 7
  br label %j1
j1:
  %p1 = phi i1 [ false, %sc ], [ %c2, %rhs1 ]
  br i1 %p1, label %j2, label %rhs2
rhs2:
  %c3 = icmp sgt i32 %q, 8
  br label %j2
j2:
  %p2 = phi i1 [ %p1, %j1 ], [ %c3, %rhs2 ]
  br i1 %p2, label %ta, label %tb
ta:
  %va = add i32 %q, 3
  br label %merge
tb:
  %vb = mul i32 %q, 5
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %va, %ta ], [ %vb, %tb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; The chain composes to a pure and/or network over compare LEAVES — every
; negation pushed to a leaf by De Morgan (the no-NOT invariant):
;   p1  = (c0 ∧ c1) ∧ c2                         [sgt 5, slt 3, eq 7]
;   ¬p1 = ¬c0 ∨ ¬c1 ∨ ¬c2                        [sle 5, sge 3, ne 7]
;   p2  = (EP(j1→j2) ∧ p1) ∨ (EP(j1→rhs2) ∧ c3)  [+ sgt 8]
; AND nodes are Toffolis, OR nodes the cnot/cnot/toffoli (a⊕b⊕ab) network, and
; the merge routes through controlled copies:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 8)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call void @cqrt_toffoli(
; CHECK-DAG: call void @cqrt_cnot(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
