; control_angle_select_accept_rounding_at_bound.ll — ACCEPT: the by-difference
; rounding residual is EXACTLY the threshold, `|delta| = 2^-40 rad`.
;
; THIS FIXTURE AND ITS SIBLING `control_angle_select_reject_rounding_above_bound.ll`
; PIN THE THRESHOLD ITSELF (bd drbq Inc 2b, ROUND-2 Rule-13 review, lens R1 item
; 6). Before them the shipped fence was pinned by NOTHING: the two accept cells
; were `delta = -2^-54` (flagship) and `delta = 0` (exact), the two rounding
; declines were `delta = 0.858` and `delta = 1.0`, so the whole suite stayed green
; for ANY threshold in `(2^-54, 0.858]` — 33 binary orders of magnitude — and for a
; `>=` re-spelling of the comparison. That is a fence nobody can move by accident
; and nobody can move on purpose either, which is the wrong property for a
; constant the code itself calls a PLACEHOLDER on the owner's desk.
;
; THE TWO PROPERTIES THESE TWO FIXTURES PIN, and each reddens exactly one file:
;   * THE VALUE. `kAngleSelectMaxRoundingRad = 0x1p-40`. Halving it to `2^-41`
;     reddens THIS file (it would decline); doubling it to `2^-39` reddens the
;     SIBLING (it would accept).
;   * THE BOUNDARY SPELLING. The shipped test is
;     `Delta.compare(bound) != cmpGreaterThan`, i.e. `|delta| <= bound`. Re-spelling
;     it as a strict `<` (equivalently `>=` on the refusal side) reddens THIS file
;     and ONLY this file — the sibling is strictly above the bound and the two
;     existing rounding declines are 39 binades above it.
;
; THE ARITHMETIC, computed independently of the pass in a hand-written TwoSum C
; program (the same six round-to-nearest `double` operations the clause performs
; in `APFloat`):
;
;     A = 0x40D0000000000000 = 2^14  = 16384
;     B = 0x3D70000000000000 = 2^-40
;     ulp(16384) = 2^(14-52) = 2^-38, so B is a QUARTER of an ulp and
;     fl(A - B) = 16384 EXACTLY (round to nearest)
;     delta = A - (B + fl(A-B)) = 16384 - (2^-40 + 16384) = -2^-40
;
; so `|delta| = 2^-40` is EQUAL to the bound, and `<=` admits it. The emitted
; controlled angle is therefore `1.638400e+04` and the unconditional twin's angle
; is `B` verbatim — both pinned below, so a change to which side of the difference
; is rounded also reddens this file.
;
; A NOTE ON WHAT THIS DOES *NOT* SAY: 2^-40 rad is not a physically motivated
; number. It separates two measured populations (every ordinary-angle pair in this
; tree has `|delta| <= 2^-54` or exactly 0; every macroscopic case the round-1
; review found is >= 0.85 rad) and nothing more. If the owner rules that
; round-to-nearest angle arithmetic is IN the semantic model, the constant and both
; of these fixtures go; if the owner rules the other way, the two-controlled form
; replaces the `fsub` and they go too. See
; `docs/prd/phase-04-swap-route-control/CONTROL_IN_PLACE_INC2B_NOTES.md` §9.
;
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`).
;
; Reproducer from the round-2 review, lens R1
; (`review2b_r2/R1/probes/delta/p15_16384_2m40_theta.ll`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  ; 0x40D0000000000000 = 16384 = 2^14 ; 0x3D70000000000000 = 2^-40
  %ang = select i1 %c, double 0x40D0000000000000, double 0x3D70000000000000
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; the UNCONDITIONAL twin at B = 2^-40, verbatim
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 0x3D70000000000000)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; fl(A-B) = A = 16384 exactly; the whole of B is the residual, and it is AT the bound
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 1.638400e+04)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; the trailing negative that covers [last match, EOF] — where a leaked rotation on
; a frozen rail would sit (round-1 Rule-13 review, L6-N11).
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: select
; no inf/NaN was manufactured anywhere
; NOROUTE-NOT: double 0x7FF
; NOROUTE-NOT: double 0xFFF

; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
