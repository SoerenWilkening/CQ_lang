; control_swap_reject_seq_then_nest.ll — DECLINE (bd hcrg decline partition): a
; sequential chain whose SECOND region is a depth-2 NEST, not a flat diamond.
;
; The hcrg emission ordering admits `A.Pred == B.MergeBB` for exactly one shape:
; both regions flat, childless, Depth-0 `BranchRegion`s. A nest is none of those
; — `NestedRouteEmit`/`flattenRegionTree` own a THREE-block teardown (Mid, the
; inner arm, and the SHARED merge) whose interaction with a preceding region's
; flatten has never been analysed, let alone cleared. `sequentialChainAlias`
; therefore refuses it and the pair declines LOUDLY.
;
; MEASURED, and worth knowing before reading this as over-conservative: the
; decline here fires EARLIER than the ordering check, inside `recoverRegionTree`
; — the nest's own prover walks the tree and rejects it before
; `lowerControlRegions` ever computes a precedence graph. That is defence in
; depth, not redundancy: the ordering predicate is what must stay narrow if a
; future increment ever teaches the nest prover this shape, and this fixture is
; what will notice when it does (the message would change, never go away).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b, double %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 9
  br i1 %c1, label %arm1, label %m1
arm1:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %m1
m1:                                    ; region 1's merge …
  %p1 = phi i32 [ %g1, %arm1 ], [ %q, %entry ]
  %c2 = icmp sgt i32 %p1, 5
  br i1 %c2, label %mid, label %mn     ; … hosting a depth-2 NEST's outer branch
mid:
  %g2 = call i32 @cq_phi_si32(i32 %p1, double %b)
  %c3 = icmp sgt i32 %g2, 3
  br i1 %c3, label %inner, label %mn
inner:
  %g3 = call i32 @cq_phi_si32(i32 %g2, double %c)
  br label %mn
mn:
  %pn = phi i32 [ %p1, %m1 ], [ %g2, %mid ], [ %g3, %inner ]
  %m = call i32 @cq_measure_si32(i32 %pn)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
