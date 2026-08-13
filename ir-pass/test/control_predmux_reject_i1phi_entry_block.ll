; control_predmux_reject_i1phi_entry_block.ll — DECLINE (bd q2wk = 3c6m.14 L6
; Inc 5, PRD §4.4b rule (A) condition 2): THE BROKEN-MODULE FENCE.
;
; Inc 5 admits an i1 PHI as a branch-condition-tree node — but only one the
; flatten will actually CONVERT. `RegionFlattener::run()` converts the phis of
; every region block EXCEPT `R.Entry`, so a phi defined in the region ENTRY
; block (the block whose tainted terminator roots the claim) SURVIVES the
; flatten AS A PHI. If E6 admitted it, `buildNegation` would then reach a node
; that is neither cmp/and/or/xor nor an i1 constant while building the
; false-edge literal — a BROKEN MODULE, not a decline. `isConvertiblePhiCond`
; therefore rejects `PB == S->Entry` outright, and the tainted diamond falls to
; the control detector's loud decline (over-declining is safe; over-accepting
; here is not even a miscompile, it is invalid IR).
;
; The phi below is admissible on EVERY other Inc-5 condition — i1 typed, inside
; the region, 2 unique incoming blocks, all incomings on the strict
; `isBooleanCondTree` grammar (i1 constants) — and its consuming branch clears
; the widened sub-rule (B) gate too (`%ep` is untainted but region-internal-phi
; derived, so `valueWillTaintAfterFlatten` says the flatten would taint it).
; The E6 walk therefore reaches this terminator with W/E2/E3/E4/E7 all already
; satisfied: the ENTRY-BLOCK placement is the sole load-bearing rejection. The
; accept twin is control_predmux_accept_i1phi_branch_allconst.ll, the same
; all-constant i1-phi-fed branch with the phi one block DEEPER than the entry.
;
; The classical `%g` guard exists only to give the region entry a predecessor
; (a phi needs one) — it is untainted, so it can never root a claim of its own
; and can never pull %rentry into some larger region's interior.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %g  = icmp sgt i32 %u0, 0            ; classical (arg-derived): roots no claim
  br i1 %g, label %pa, label %pb
pa:
  br label %rentry
pb:
  br label %rentry

rentry:                                ; ← the CLAIMED region entry (tainted %ct)
  %ep = phi i1 [ true, %pa ], [ false, %pb ]   ; ← the ENTRY-BLOCK phi
  %ct = icmp sgt i32 %q, 5
  br i1 %ct, label %arm, label %merge
arm:
  br i1 %ep, label %t, label %f        ; ← entry phi as an interior branch cond
t:
  %vt = add i32 %q, 1
  br label %ajoin
f:
  %vf = mul i32 %q, 3
  br label %ajoin
ajoin:
  %av = phi i32 [ %vt, %t ], [ %vf, %f ]
  %aw = add i32 %av, 7
  br label %merge

merge:                                 ; 2 merge phis = the PredMux claim witness
  %rm = phi i32 [ %av, %ajoin ], [ %q, %rentry ]
  %rn = phi i32 [ %aw, %ajoin ], [ 0, %rentry ]
  %sum = add i32 %rm, %rn
  %m  = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; Nothing lowered: the region is LEFT unclaimed (detect-before-mutate), so no
; rail is allocated and no template is minted before the decline.
; CHECK-NOT: cqrt_
; CHECK-NOT: cq_template_
