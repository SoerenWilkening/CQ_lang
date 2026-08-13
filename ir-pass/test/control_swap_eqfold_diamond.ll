; control_swap_eqfold_diamond.ll — ACCEPT spec, equality-folded `br` diamond
; (4.5 WI-5; additive `tryEqFoldArm` D1–D7 clause).
;
; `if (q == 7) { rz(q, a); rz(q, b); }`. `clang -O1` KNOWS `q == 7` inside the
; arm, so it CONST-FOLDS the gate's arg-0 handle to the literal: the arm gate is
; `cq_phi(i32 7, θ)`, not `cq_phi(i32 %q, θ)`. `classifyArms`'s phase spine then
; bottoms at the `ConstantInt 7` instead of the routed handle, so the old
; classifier declined `control flow`. `tryEqFoldArm` re-recognizes it as a pure
; PHASE arm over the icmp's tainted operand (D1 equality predicate · D2 folded
; const base · D3 the icmp's non-const operand IS the routed handle · D4 literal
; == folded const · D5 routed operand tainted · D6 pure spine · D7 classical
; angles) and re-anchors the routed handle, so the diamond lowers through
; `emitRegion` VERBATIM (§4D): flag from the tainted `icmp eq`, CSWAP q into a
; |0> rail, the arm Rz gates VERBATIM/UNCONTROLLED on the rail (re-anchor BY
; PHYSICS — only arg-1/the angle is read, the folded arg-0 const is discarded),
; CSWAP back, free the |0> rail, strip the boolean with `icmp_eq_inv(q)` — ZERO
; controlled gates, NO surviving folded `cq_phi`, NO `phi i32`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; Independent EXACT free-count scan: two cqrt_free (work rail + flag), no third.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 7,   double %a)   ; arg-0 CONST-FOLDED to 7
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; br: mint the flag from the EQUALITY compare, then route q into a |0> work rail
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 7)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; arm body: VERBATIM, UNCONTROLLED Rz gates on the routed rail (re-anchor by
; physics — only the angle is read, the folded arg-0 const is discarded)
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %b)
; phi: route the active result back into q (adjoint of the split, same %flag)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; rail is |0> (Rz|0>=|0>): clean free — NOT a measurement
; CHECK:     call void @cqrt_free(i32 %[[T]])
; strip the boolean: q==q0, so icmp_eq_inv(q) returns the flag to |0>; reclaim it
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; q (not the phi) is measured — RAUW merge-phi -> q
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free: EXACTLY two frees total — no third after the flag free
; CHECK-NOT: call void @cqrt_free
; re-anchor: NO surviving const-folded cq_phi (it would RAUW to the const at
; RotationLowering -> a wrong data-mux); zero controlled gates / copies / data mux
; CHECK-NOT: cq_phi
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — two (work rail + flag), no third anywhere.
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
