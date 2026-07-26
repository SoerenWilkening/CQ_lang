; control_predmux_accept_i1phi_branch_in_andtree.ll — ACCEPT (bd q2wk =
; 3c6m.14 L6 Inc 5, PRD §4.4b rule (A), the COMPOSITION case).
;
; Inc 5 rule (A) admits a region-internal, non-entry i1 PHI as a condition-tree
; NODE. The ship-floor fixtures pin the phi as the WHOLE branch condition; this
; one pins that the phi also composes as an OPERAND of an `and i1` tree:
;
;     %p = phi i1 [ %ca, %ia ], [ %cb, %ib ]      ; the Inc-5 node
;     %c3 = icmp slt i32 %q, 100                  ; a plain compare leaf
;     %t  = and i1 %p, %c3
;     br i1 %t, label %tarm, label %farm
;
; Two things are load-bearing here and neither is covered by a whole-condition
; fixture:
;   1. isSupportedCondTree's and/or RECURSION must thread the PhiCondScope down
;      every recursive call — a scope dropped at the `and` node makes the phi
;      leg fall to the null-scope grammar (`null S ⇒ false`) and the region
;      declines at gate=E6-condtree, i.e. the widening would silently not
;      compose. (This fixture is exactly that regression's tripwire.)
;   2. buildNegation must De-Morgan through a MIXED tree — one operand a
;      converted phi (an ∨ of ∧-terms by then, since convertPhis runs on
;      %ijoin in topo order BEFORE literal() reads the terminator), the other a
;      plain compare — all the way down to inverse-PREDICATE compare leaves,
;      never a materialized NOT (PRD §4.3, the no-NOT invariant).
;
; The three-incoming merge phi forces BOTH polarities of `%t` to be built (the
; select chain needs EP(tarm) = BP(ijoin) ∧ %t and EP(farm) = BP(ijoin) ∧ ¬%t),
; so the false edge is genuinely used and the negation path is exercised — it
; is not reachable-but-dead. Rule (B) is NOT exercised: %p is already tainted
; through its compare incomings, so E6's taint check passes on stock taint.
;
; BEFORE Inc 5: gate=E6-condtree at `br i1 %t` → `nested control flow under
; quantum control`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %inner, label %sideb
inner:
  %c2 = icmp eq i32 %q, 7
  br i1 %c2, label %ia, label %ib
ia:
  %ca = icmp slt i32 %q, 3
  br label %ijoin
ib:
  %cb = icmp sgt i32 %q, 8
  br label %ijoin
ijoin:
  %p  = phi i1 [ %ca, %ia ], [ %cb, %ib ]
  %c3 = icmp slt i32 %q, 100
  %t  = and i1 %p, %c3
  br i1 %t, label %tarm, label %farm
tarm:
  %vt = add i32 %q, 3
  br label %merge
farm:
  %vf = mul i32 %q, 5
  br label %merge
sideb:
  %u  = mul i32 %q, 9
  br label %merge
merge:
  %rm = phi i32 [ %vt, %tarm ], [ %vf, %farm ], [ %u, %sideb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; %p converts to (EP(ia) ∧ ca) ∨ (EP(ib) ∧ cb), and `%t` = that ∧ c3. The TRUE
; literal keeps every leaf in its written polarity (slt 3 / sgt 8 / slt 100);
; the FALSE literal is ¬(%p ∧ c3) = ¬%p ∨ ¬c3, pushed through the phi's ∨/∧
; tree to inverted-predicate leaves (sge 3 / sle 8 / sge 100, plus sle 5 and
; eq 7 for the ¬EP legs) — the mixed-tree De Morgan, no NOT anywhere:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_sle_i32_hl(i32 %[[Q]], i32 8)
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 100)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 8)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 100)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: phi i1
; CHECK-NOT: select i1
