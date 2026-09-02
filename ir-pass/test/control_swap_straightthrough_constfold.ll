; control_swap_straightthrough_constfold.ll — ACCEPT spec, issue a8c0: the
; straight-through const-fold re-anchor (the Pred-edge analog of tryEqFoldArm).
;
; `if (q != 0) q = cq_phi(q, a); measure(q);` — the idiomatic conditional phase.
; `clang -O1` reaches the else (straight-through) edge ONLY when `q == 0`, so it
; value-propagates the merge's Pred-edge incoming to the literal `0`: the merge is
; `phi [phase(q), 0]`. The classifier's `Base == Routed` gate then fails — `Routed`
; is the folded `0`, `Base` is the qubit — a verify-clean OVER-DECLINE of a clean
; phase arm (`phi [phase(q), 0] ≡ phi [phase(q), q]` because `q == 0` on that edge).
;
; `straightThroughConstFoldHandle` re-recognizes it: the condition `icmp eq q, 0`
; proves `q == 0` on the straight-through (true) edge, the folded constant equals
; the compare literal, and the arm rotates the proven handle — so it re-anchors
; `Routed`/`RoutedBase` to `q` and the diamond lowers through `emitRegion`
; VERBATIM: flag from `icmp eq`, CSWAP q into a |0> rail (¬flag `cqrt_x` bracket —
; the arm fires on `q != 0`, the FALSE edge, Rule 9), the arm Rz on the rail, CSWAP
; back, free the rail, strip with `icmp_eq_inv(q)` — ZERO controlled gates, NO
; surviving folded constant, NO `phi i32`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 0
  br i1 %c, label %merge, label %arm      ; q==0 -> merge (straight-through); else arm
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ 0, %entry ]   ; straight-through FOLDED to 0
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; Flag from the EQUALITY compare on the qubit (NOT the folded constant).
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 0)
; The arm fires when q != 0 (the FALSE edge), so its gate run is X-bracketed.
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; Arm body: ONE controlled Rz, IN PLACE on q (drbq Inc 2a). The §5 straight-
; through const-fold re-anchor is what puts %[[Q]] at arg 0 — `clang -O1` folded
; the arm's `cq_phi` base to the constant 0, and hoist-and-defer READS arg 0, so
; without the re-anchor the rotation would be dropped outright.
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; Strip the boolean with icmp_eq_inv(q) and reclaim the flag.
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; q (NOT the phi, NOT the folded 0) is measured — RAUW merge-phi -> q.
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; Zero copies / data mux; no surviving phi or folded phase.
; CHECK-NOT: cq_phi
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag; no work rail since drbq Inc 2a), no second.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No swap route survives — window `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
