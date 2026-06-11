; control_swap_reject_stalecond_chained_theta_sibling.ll — DECLINE: the
; condition reads a CHAINED theta whose wire is re-rotated by a SIBLING theta
; scheduled BEFORE the compare (test_C_libtooling-6vk, surface S4 — the
; condition-side twin one theta hop above
; control_swap_reject_stalecond_chained_theta.ll).
;
; The condition `%c = (%qc > 5)` reads the chained theta `%qc = cq_theta(%q,
; 1.25)`; a SIBLING chained theta `%qs = cq_theta(%q, 0.25)` re-rotates `%q`'s
; physical wire, and is scheduled BEFORE the compare so the positional
; compare→branch scan does not see it. The swap-route emitter mints the flag at
; the BRANCH, so it would read the post-`%qs` basis — the wrong arm fires AND
; `icmp_inv` cannot strip the flag (the MINT_AT_COMPARE P2 family; the one-hop
; version control_swap_reject_stalecond_chained_theta.ll is a PERMANENT
; decline). condProvenance collects `%qc` but stops AT the theta source
; (never entering its tainted arg-0), so before test_C_libtooling-6vk the
; condition-seeded wire walk stopped at `%qc` and the sibling `%qs` (a user of
; `%q`, not `%qc`) was invisible — exit 0, the phase region accepted and
; lowered from the stale wire. The fix crosses the chained-theta arg-0 hop to
; the wire origin `%q`, exempts the on-ancestry producers (`%qc`, `%q`), and
; flags the OFF-ancestry sibling `%qs`. Guard:
; ArmClassify::wireGainsNonDiagonalGate via WireWalk::findNonDiagonalWireGate
; (position-free). Phase arm, so the routed-base guard does not apply — the
; defect is the condition-side mint.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qc = call i32 @cq_theta_si32(i32 %q, double 1.250000e+00)   ; chained theta — condition reads this
  %qs = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; SIBLING chained Ry, BEFORE the compare
  %c  = icmp sgt i32 %qc, 5
  br i1 %c, label %arm, label %merge
arm:
  %qa = call i32 @cq_phi_si32(i32 %qc, double %a)              ; phase arm (Rz, diagonal)
  br label %merge
merge:
  %qm = phi i32 [ %qa, %arm ], [ %qc, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
