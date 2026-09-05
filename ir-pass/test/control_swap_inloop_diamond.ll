; control_swap_inloop_diamond.ll — ACCEPT (bd test_C_libtooling-8h7d.5, Phase 7.3
; Increment 3; owner ruling 2026-08-29). A FLAT (depth-1) tainted-condition PHASE
; diamond that lives wholly inside a classically-bounded loop body, with a
; loop-CARRIED routed base — the merge feeds the backedge and the routed `%q` is a
; loop-header phi. Source shape:
;
;     for (...) { if (q > 5) { q = cq_phi(q, b); } }   // q loop-carried
;
; THIS FILE WAS `control_swap_reject_inloop_diamond.ll` UNTIL 2026-08-29, AND THE
; FLIP IS THE INCREMENT. The d8jl guard declined every flat region on a CFG cycle
; for a STRUCTURAL reason — `RegionFlatten` erases the merge, which inside a loop
; can be the LATCH, dangling the header phi. Two things changed:
;   * the erase has repaired that since bd dugh (2026-07-04, AFTER d8jl was
;     written): `flattenRegion` runs `Pred->replaceSuccessorsPhiUsesWith(Merge,
;     Pred)` before the erase, which repoints exactly the header-phi incoming the
;     broken-module report was about — `Pred` becomes the new latch;
;   * `ControlDetect::flatRegionRollableInLoop` now ADMITS only a region whose
;     blocks all sit at one depth of a REDUCIBLE `LoopInfo` loop with a single
;     latch and no second cycle through the entry. Everything else keeps the
;     decline, irreducible cycles first (see the sibling
;     control_swap_reject_inloop_diamond_irreducible.ll, still RED).
;
; WHAT THE ROLLED FORM IS. IR size is independent of the trip count (PRD 7.3
; §2.1): ONE copy of the stream, inside the intact loop, and only the runtime
; trace grows. The loop-carried header phi is collapsed to its root mint by the
; round-2 rail analysis (`collapseFlattenedLoopRails`), which runs AFTER the
; flatten because that is the first point at which the merge phi is gone and the
; rail peels. The register `%h` is one physical qubit for the whole loop; the only
; ancilla left (the flag) is minted, used, stripped and freed INSIDE the iteration,
; so nothing dirty crosses the back edge.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` fires as ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route — work-rail
; alloc, both `cqrt_cswap`s, the rail free — is gone entirely. Everything else
; below (flag mint, strip, flag free, the rolled CFG, the exit measure) is
; byte-identical to the routed form.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %q, %merge ]       ; loop-carried routed base
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]      ; classical induction
  %c1 = icmp sgt i32 %q, 5                             ; TAINTED (quantum) condition
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)  ; phase arm (Rz)
  br label %merge
merge:
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n                      ; classical loop bound
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; The rail is minted ONCE, outside the loop:
; CHECK:     entry:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
;
; ...and the ROLLED per-iteration stream lands in the surviving loop block, whose
; header phi is now classical-only (the rail phi was collapsed):
; CHECK:     loop:
; CHECK:     %{{.*}} = phi i32 [ 0, %entry ], [ %{{.*}}, %loop ]
; CHECK-NOT: phi i32 [ %[[H]]
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double %b)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; The loop is still a loop — ROLLED, not unrolled (one back edge, one stream):
; CHECK:     br i1 %{{.*}}, label %exit, label %loop
; CHECK:     exit:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; The old misleading messages must be gone, and nothing may dangle:
; CHECK-NOT: classical-condition phi
; CHECK-NOT: control flow inside a loop body
;
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
