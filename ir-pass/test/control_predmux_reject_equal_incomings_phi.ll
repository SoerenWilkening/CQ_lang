; control_predmux_reject_equal_incomings_phi.ll — DECLINE (bd q2wk, PRD §4.4b
; rule (B), residual (c)). The sibling of
; control_predmux_reject_degenerate_phi_classical.ll: there the phi has ONE
; incoming block, here it has TWO — so the `In.size() > 1` reasoning that
; explains the degenerate case does NOT cover this one, which is exactly why the
; Rule-13 round called it out as separately unpinned.
;
; `%ph` has two unique incoming BLOCKS but only ONE distinct incoming VALUE.
; `convertPhis`' select-chain path seeds `Acc = In.back().second` and then skips
; every incoming with `In[I].second == Acc` (the bd-adia `select(EP,x,x) = x`
; guard), so the phi is RAUW'd straight to that one value — here the FUNCTION
; ARGUMENT `%arg`, genuinely classical and a runtime (non-constant) value. A
; region-internal phi that converts to nothing tainted is precisely the shape
; rule (B) must NOT admit on its "the flatten will taint it" proof.
;
; `valueWillTaintAfterFlatten` therefore recurses into the sole value instead of
; answering true at the phi, so this leaves at `gate=E6-classicalbr` with the
; region UNTOUCHED (detect-before-mutate) and `ControlDetect` owns the decline.
;
; Reachability is thin — `clang -O1` folds a trivially-equal phi away — so this
; needs the phi to be materialized late (a prior fixpoint round's
; `simplifyFlattenResiduesInFunction` RAUW making two arms syntactically equal).
; It is pinned anyway: the residual class is what rule (B)'s soundness argument
; is quantified over, and an unpinned member of it can silently widen.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0, i32 %arg) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %A, label %B

A:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %A1, label %A2

A1:
  br label %A3
A2:
  br label %A3

A3:                                    ; 2 unique preds, ONE distinct value
  %ph = phi i32 [ %arg, %A1 ], [ %arg, %A2 ]
  %cc = icmp eq i32 %ph, 0             ; classical RUNTIME condition after RAUW
  br i1 %cc, label %J, label %Ag

Ag:
  %ga = mul i32 %q, 7
  br label %J

B:
  %b = add i32 %q, 3
  br label %J

J:
  %r = phi i32 [ %ga, %Ag ], [ %q, %A3 ], [ %b, %B ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
; Nothing lowered — the region is LEFT unclaimed, so no rail is allocated and no
; template is minted before the decline.
; CHECK-NOT: cqrt_
; CHECK-NOT: cq_template_
