; control_predmux_accept_willtaint_cmp_over_phi.ll — ACCEPT (3c6m.14 L6 Inc 5,
; bd q2wk; PRD §4.4b rule (B) ALONE — rule (A) is deliberately NOT exercised:
; no i1 phi appears anywhere in this region, and the blocked condition is an
; ordinary `icmp` that isSupportedCondTree already admitted before Inc 5).
;
; The hypotf.f32 scale-accumulator shape. clang -O1 lowers hypotf's successive
; `if (ha > …) { k += 68; … }` rescale guards to merges over CONSTANT scale
; deltas, then tests the accumulator with `icmp eq i32 %k, 0` and branches on
; it. Both accumulator phis are constant / constant-derived, so the compare is
; UNTAINTED at claim time even though every edge that selects between them is a
; tainted quantum decision — and the SOLE gate that blocked the region was E6's
; taint check on that branch condition (gate=E6-classicalbr, "classical control
; inside a tainted region").
;
; Inc 5 widens exactly that gate with the SHARED predicate
; `valueWillTaintAfterFlatten` (Rule 14 — the same question the Inc-3 QROM index
; gate asks): a condition that is region-internal and transitively derived from
; a region-internal PHI is not classical control, it is the region's OWN tainted
; decision re-materialized — `convertPhis` rewires that phi onto the (tainted)
; edge predicates, so the compare is tainted the instant the flatten runs.
;
; A condition derived from OUTSIDE the region (an argument, a pre-region
; classical value) is still classical and still declines — pinned by
; control_predmux_leave_classical_branch.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %big, label %small        ; tainted region root (ipdom = merge)
big:
  %c2 = icmp slt i32 %q, 2
  br i1 %c2, label %hi, label %lo            ; genuinely tainted inner branch
hi:
  br label %k1
lo:
  br label %k1
k1:
  ; the scale accumulator: all-constant incomings ⇒ UNTAINTED phi
  %k  = phi i32 [ 68, %hi ], [ 0, %lo ]
  %c3 = icmp sgt i32 %q, 9
  br i1 %c3, label %rescale, label %k2       ; a second tainted inner branch
rescale:
  %kadj = add nsw i32 %k, -68                ; untainted arithmetic over the phi
  br label %k2
k2:
  %kk = phi i32 [ %kadj, %rescale ], [ %k, %k1 ]   ; second untainted i32 phi
  %z  = icmp eq i32 %kk, 0                   ; UNTAINTED compare — the E6 blocker
  br i1 %z, label %scaled, label %merge      ; ← rule (B): tainted after flatten
scaled:
  %vs = mul i32 %q, 7
  br label %merge
small:
  %vb = mul i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %vs, %scaled ], [ %q, %k2 ], [ %vb, %small ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; The whole nest flattens: the tainted leaf compares are minted as flags, the
; accumulator merges become controlled copies over the tainted edge predicates,
; and the `icmp eq %kk, 0` that read classical at claim time is lowered as a
; TAINTED compare template — the proof that rule (B)'s promise is kept.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 2)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 9)
; CHECK-DAG: call i32 @cq_template_icmp_eq_i32_hl(
; CHECK:     call i32 @cqrt_measure_i32(
; CHECK-NOT: br i1
; CHECK-NOT: phi i32
; CHECK-NOT: phi i1
; CHECK-NOT: select i1
