; control_predmux_accept_i1phi_branch_cond.ll — ACCEPT (3c6m.14 L6 Inc 5,
; bd q2wk; PRD §4.4b SUB-RULE (A)). The canonical census shape: an i1 PHI at an
; INTERNAL merge, two incoming edges — one an i1 CONSTANT, one an icmp over the
; tainted value — consumed as the CONDITION OF A CONDITIONAL BRANCH inside the
; region. This is openlibm s_log1p.c's `if (hx > 0 || hx <= (int32_t)0xbfd2bec4)`
; after clang -O1 declined to if-convert the short circuit: the `||` survives as
; a CFG diamond plus `%or = phi i1 [ true, %lhs ], [ %cmp, %rhs ]` feeding
; `br i1 %or`.
;
; Sibling fixture control_predmux_accept_i1phi_cond.ll (Inc 2) pins the same phi
; feeding a SELECT condition; this one pins the BRANCH-condition consumer, which
; is a different gate — isSupportedCondTree via E6, not the substrate flag-mint
; grammar at a select. Before Inc 5 that phi was not a condition-tree node, so
; E6 declined `E6-condtree` at `br i1 %or` and the whole region fell to the loud
; `nested control flow under quantum control`.
;
; SUB-RULE (B) IS DELIBERATELY NOT IN PLAY: `%c2` is a compare over the tainted
; handle, so `%or` is ALREADY tainted and the E6 classical-branch gate (which is
; checked BEFORE the cond-tree gate) never consults valueWillTaintAfterFlatten.
; This fixture therefore isolates (A). (B) is pinned by its own sibling.
;
; SHAPE NOTE (why the outer `%g` guard exists, i.e. why this is still minimal):
; rule (A) condition 2 requires the phi's parent to be INSIDE the region and not
; the region ENTRY, and recoverRegion's merge is the entry's ipdom — which is not
; part of InRegion. A bare short-circuit rooted at its own LHS has ipdom == the
; phi block, putting the phi at R.Merge instead of inside. One enclosing tainted
; guard with a bypass arm is the smallest CFG that lands the phi block strictly
; inside the region.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=FLAT %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %g  = icmp sgt i32 %q, 5
  br i1 %g, label %lhs, label %side
lhs:                                       ; short-circuit LHS: `hx > 0 || …`
  %c1 = icmp sgt i32 %q, 0
  br i1 %c1, label %lor.end, label %rhs
rhs:                                       ; short-circuit RHS
  %c2 = icmp slt i32 %q, -3
  br label %lor.end
lor.end:                                   ; INTERNAL merge — the (A) phi
  %or = phi i1 [ true, %lhs ], [ %c2, %rhs ]
  br i1 %or, label %then, label %merge     ; …consumed as a BRANCH condition
then:
  %a = add i32 %q, 7
  br label %merge
side:
  %b = mul i32 %q, 3
  br label %merge
merge:
  %r = phi i32 [ %a, %then ], [ %q, %lor.end ], [ %b, %side ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; %or converts to boolean algebra ∨ᵢ (EP(eᵢ) ∧ vᵢ) = (g∧c1 ∧ true) ∨ (g∧¬c1 ∧ c2),
; and the `then`/`merge` edge literals need BOTH polarities of it. Every negation
; is pushed to the leaves as an INVERSE PREDICATE (the no-NOT invariant), so the
; flag mint shows ¬g = sle 5, ¬c1 = sle 0, and — the Inc-5 discriminator, minted
; only because the phi became a cond-tree node — ¬c2 = sge -3:
; CHECK: %u0.stable = freeze i32 %u0
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK-DAG: call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 7)
; CHECK-DAG: call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 0)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 0)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 -3)
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 -3)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: phi i1
; CHECK-NOT: select i1

; The trailing CHECK-NOTs above only scan from the last positive match to EOF;
; the FLAT prefix pins the residual-free property over the WHOLE function — the
; diamond is gone, not merely absent from the tail.
; FLAT:     define i32 @probe(
; FLAT-NOT: br i1
; FLAT-NOT: phi
; FLAT-NOT: select i1
