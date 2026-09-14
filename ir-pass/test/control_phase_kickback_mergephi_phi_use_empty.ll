; control_phase_kickback_mergephi_phi_use_empty.ll — ACCEPT (bd `3qps`, Track P).
; THE PREP φ WHOSE ONLY USER IS THE KICKBACK'S OWN `br`, so that after this
; region's `flattenRegion` the φ is USE-EMPTY while the prep that owns it has not
; been emitted yet.
;
; ⚠ IT WAS WRITTEN AS THE PIN FOR `RegionFlatten`'s φ GUARD, AND THE MEASUREMENT
; SAID NO. `RegionFlatten` erases a use-empty condition once the branch is gone,
; guarded by `!isCondRailLeaf(Cond) && !isCondRailPhiShape(Cond)`; Track M added
; the second conjunct as DEFENCE IN DEPTH, recorded that it had NO SUBJECT, and
; wrote its retirement trigger as "the first widening which gives a
; φ-conditioned region a `Pred`/`MergeBB` of its own". This increment IS that
; widening, and this module is the sharpest case it admits — a φ whose ONLY user
; is this region's own `br`, so it is use-empty the moment the branch goes, while
; the PREP that owns it has not been emitted yet.
;
; THE COUNTERFACTUAL WAS RUN AND CAME BACK NEGATIVE (2026-09-14, Track P): with
; the `isCondRailPhiShape` conjunct REVERTED and the pass rebuilt, this module —
; and `control_phase_kickback_mergephi_rail.ll` and
; `control_phase_kickback_mergephi_tree_leaf.ll` — lower to BYTE-IDENTICAL IR,
; exit 0, clean under `DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib`. So the
; guard STILL has no subject, and this file must not claim otherwise. Do not read
; that as licence to delete the conjunct: an unexercised guard on a
; use-after-free path is cheap, and the ONE thing this measurement establishes is
; that the emission ORDER keeps the φ out of its way — not that nothing could
; ever put it there.
;
; ⚠ THE LESSON IS THE RULE-11 ONE: a retirement trigger is a place to LOOK, never
; evidence that the thing triggered. bd `boi6`'s trigger was written perfectly and
; still fired on a shape whose guard turned out not to be load-bearing. What this
; file pins is therefore the narrower, measured fact — a prep φ with NO consumer
; but the branch lowers correctly and leaves nothing behind.
;
; The emitted stream is the ordinary one: one diagonal `cqrt_rz_i1` on the user's
; prepped register, nothing minted, nothing bracketed, nothing freed.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PHI < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MINT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b0)
  ret i1 %m
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H1]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H0]])

; NOX-NOT: call void @cqrt_x(
; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_copy
; NOX-NOT: cqrt_toffoli
; FCNT-NOT: call void @cqrt_free(
; PHI-NOT: = phi
; MINT-NOT: cq_template_
; MINT-NOT: _unc(
