; control_angle_select_ry_ne_swapped.ll — ACCEPT: the `!=` source, which reaches
; the pass as `icmp eq` with the SELECT OPERANDS SWAPPED (bd drbq Inc 2b).
;
;     if (q != 5) r = cq_theta(r, .9); else r = cq_theta(r, .3);
;
; `clang -O1` canonicalizes `q != 5` to `icmp eq i32 %q, 5` and then swaps the
; select's arms rather than inverting the condition (measured — probe p7). THE
; POINT OF THIS FIXTURE IS THAT NOTHING SPECIAL HAPPENS: a select ALWAYS means
; "true value when the flag is 1", so the unconditional twin takes the FALSE
; operand (here `.9`, the `q != 5` arm's angle) and the controlled gate takes
; `A - B = .3 - .9 = -0.6`. There is no polarity case and NO `cqrt_x` bracket
; anywhere in this stream — unlike the `br`-diamond paths, where Rule 9's
; false-successor canonicalization forces one.
;
; SHAPE (exactly what `clang -O1` produces — SimplifyCFG merges the two arms of
; `if (c) r = R(r, A); else r = R(r, B);` into ONE call with a `select` on the
; ANGLE, so the branch CFG is gone before the pass runs, Rule 9).
;
; LOWERED BY DIFFERENCE (control-in-place-PRD §12.3): `R(h, B)` unconditional,
; the ordinary flag mint, ONE `cqrt_{ry,rz}_<W>_controlled(f, h, A-B)`, the
; ordinary `_unc` strip, ONE `cqrt_free`. Exact IN REAL ARITHMETIC by angle
; additivity on one axis (`R(A) = R(B).R(A-B)`; for `Rz = diag(1,e^{i.theta})` the
; two diagonals multiply entrywise, so there is no global-phase residue either) —
; in IEEE double the emitted true-arm angle is `B + fl(A-B)`, so
; `|delta| <= 1/2 ulp(A-B)`; constant arms are fenced at the placeholder
; `kAngleSelectMaxRoundingRad` = 2^-40 rad, and a RUN-TIME arm DECLINES — the
; accept class is CONSTANT arms only, because for a run-time arm the compiler
; would synthesize an `fsub` the source never wrote whose error is unbounded in
; absolute radians and whose result can be `inf`/`NaN` from two FINITE arms
; (round-1 Rule-13 review lens L7-F1 for the bound; the Rule-13 CLEARANCE
; review, finding F-11 / owner option (2), for the narrowing — an earlier
; version of this line said "runtime arms carry the bound"; see
; `control_angle_select_accept_rounding_flagship_bound.ll`). No CFG
; surgery, no route, no work rail, no `cqrt_x` bracket (a select always means
; "A when the flag is 1", so there is no polarity case at all).
;
; ORACLE DISPOSITION: RED on the pre-2b binary — it declines `rotation angle
; under quantum control` at SelectClassify's gate 3 (Rule 12 red-green).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 3.000000e-01, double 9.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; the unconditional twin takes the FALSE operand — the `q != 5` arm's own angle
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; A - B = 0.3 - 0.9 = -0.6, NEGATIVE and pinned as folded BITS
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0xBFE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; NO `cqrt_x` — the swapped-operand select needs no bracket, which is exactly
; what distinguishes this path from the negated `br` arm.
; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: select

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
