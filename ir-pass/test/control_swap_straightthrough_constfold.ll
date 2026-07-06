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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
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
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; Route-in on ¬flag (arm fires when q != 0 = the FALSE edge): cqrt_x brackets.
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; Arm body: the Rz VERBATIM/UNCONTROLLED on the routed rail.
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; Route-back (adjoint of the split, same flag + brackets), then free the |0> rail.
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; Strip the boolean with icmp_eq_inv(q) and reclaim the flag.
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[Q]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; q (NOT the phi, NOT the folded 0) is measured — RAUW merge-phi -> q.
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; Zero controlled gates / copies / data mux; no surviving phi or folded phase.
; CHECK-NOT: cq_phi
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — two (work rail + flag), no third anywhere.
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
