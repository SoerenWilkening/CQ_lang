; control_predmux_accept_w6_stranded_merge_condphi.ll — ACCEPT (bd oudq =
; 3c6m.14 L6 Inc 6, W6): the STRANDED-DOWNSTREAM claim witness.
;
; THE SHAPE (distilled from openlibm src/s_isnan.c:63 as it inlines into
; log1pl/log2l/logl.f80): a 2-block TRIANGLE (an if without an else — the entry
; branches to the arm and straight to the merge) whose MERGE hosts a sole
; 2-incoming i1 phi, and that merge's OWN tainted branch reads the phi as an
; `or` cond-tree NODE. The sibling accept fixture
; control_predmux_accept_w6_direct_condphi.ll pins the other live position, the
; phi as the whole condition. Two claims are in play and before Inc 6 BOTH were lost:
;
;   * the DOWNSTREAM region rooted at %isn leaves at `E6-condtree`, because
;     rule (A) condition 2 (bd q2wk) refuses a phi whose parent is the region
;     ENTRY — `RegionFlattener::run()` skips the entry, so such a phi would
;     survive the flatten AS A PHI and `buildNegation`'s terminal
;     `cast<BinaryOperator>` would run on a `PHINode` (an assert in +Asserts, an
;     unchecked bad cast in Release). Nothing else in the pipeline removes an
;     entry phi, so that leave is PERMANENT.
;   * the UPSTREAM diamond that DEFINES the phi leaves at `W-witness`: its merge
;     holds exactly one 2-incoming phi, and the phi is not scalar-fp, so neither
;     the ≥2-phi nor the >2-incoming nor the W5 fp witness fires.
;
; W6 closes it from the UPSTREAM side (the ticket's option (a) — root the claim
; one block earlier — rather than teaching the flatten to convert an entry phi,
; which is impossible: an entry phi's incoming EDGES come from outside the
; region, so there are no edge predicates to convert it against). Claiming the
; upstream diamond makes the phi a MERGE phi, `convertPhis(R.Merge)` rewrites it
; to the Inc-2 boolean algebra ∨ᵢ(EPᵢ ∧ vᵢ) = `and(%hi, %nan)` here, and the
; downstream branch is then an ordinary and/or-over-compare-leaves tree that the
; next fixpoint round claims normally.
;
; ANTI-OVERLAP: a br region whose MERGE ends in a tainted conditional branch is
; categorically declined by every shipped br owner — `ControlDetect`'s
; `recoverRegion` tests `hasTaintedCondBranch` on both successors before any
; shape match (a diamond's merge IS a successor), and repeats it explicitly for
; the if/else merge, returning `RegionShape::Nested`; `recoverRegionTree` then
; declines too (the merge-as-Mid candidate fails `Mid->getSinglePredecessor() ==
; Pred`, since the merge is reached from both the entry and the arm). So W6
; claims only shapes that decline today. The decline twin (a CLASSICAL merge
; branch, which IS a shipped-owner accept) is
; control_predmux_leave_w6_classical_merge_br.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=FLAT %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %hi = icmp eq i32 %q, 32767              ; tainted — roots the upstream claim
  br i1 %hi, label %chk, label %isn        ; diamond: arm = %chk, merge = %isn

chk:                                       ; the "mantissa non-zero" arm
  %lo  = icmp ne i32 %q, 0
  %hb  = icmp ugt i32 %q, 7
  %nan = or i1 %lo, %hb
  br label %isn

isn:                                       ; ← MERGE of the upstream diamond …
  %isnan = phi i1 [ false, %entry ], [ %nan, %chk ]
  %inf   = icmp eq i32 %q, 100
  %c1    = or i1 %inf, %isnan              ; ← the phi at an `or` TREE NODE
  br i1 %c1, label %out, label %body       ; … and ENTRY of the downstream region

body:                                      ; downstream region: a nested diamond
  %c2 = icmp slt i32 %q, 3                 ; (W1 nested-tainted witness)
  br i1 %c2, label %arm, label %join
arm:
  %va = add i32 %q, 11
  br label %join
join:
  %vj = phi i32 [ %va, %arm ], [ %q, %body ]
  %vw = mul i32 %vj, 5
  br label %out

out:
  %r = phi i32 [ %q, %isn ], [ %vw, %join ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The upstream diamond is CLAIMED, so `%isnan` becomes `hi ∧ (lo ∨ hb)` — the
; source predicate, verbatim — and the whole function flattens end to end. Both
; polarities of every leaf are minted (the no-NOT invariant pushes each negation
; to the leaves): the FINAL answer mux needs `inf`/`hi`/`lo`/`hb` positive, the
; interior join mux needs them all inverted.
; CHECK: %u0.stable = freeze i32 %u0
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 32767)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 32767)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 0)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK-DAG: call i32 @cq_template_icmp_ugt_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_ule_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 100)
; CHECK-DAG: call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q]], i32 100)
; The `or` nodes of that predicate are the 3c6m.12 (cnot,cnot,toffoli) triple and
; the `and` nodes are bare toffolis; the answer is the ordinary controlled-copy
; pair over the ¬flag `cqrt_x` bracket, and every conjunction ancilla is
; unwound + freed in LIFO order.
; CHECK:     call void @cqrt_cnot(
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_x(
; CHECK:     call void @cqrt_free(
; CHECK:     call i32 @cqrt_measure_i32(

; Both regions are gone: no CONDITIONAL CFG, no phi and no select anywhere in the
; function (the remaining blocks are joined by unconditional branches, which is
; exactly what `FLAT-NOT: br i1` asserts; the FLAT prefix scans the WHOLE body,
; not just the tail).
; FLAT:     define i32 @probe(
; FLAT-NOT: br i1
; FLAT-NOT: phi
; FLAT-NOT: select i1
