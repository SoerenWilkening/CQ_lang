; control_angle_select_rz_cond_register.ll — ACCEPT, AND IT IS THE STEM
; SEPARATOR (bd drbq Inc 2b; control-in-place-PRD §3c / §12.1).
;
;     int q = cq_theta(3,.5);
;     q = cq_phi(q, q == 5 ? .9 : .3);      // rotate the CONDITION register
;
; The rotated register IS the register the condition reads. For the `cq_phi`
; stem that is fine and needs no fence: Rz is DIAGONAL, so neither the
; unconditional `rz(q,B)` nor the controlled `crz(f,q,A-B)` moves any
; computational-basis label, and the strip `icmp_eq_unc(f, q, 5)` therefore
; recomputes the SAME predicate the mint read and returns the flag to |0>.
;
; ITS `cq_theta` TWIN DECLINES, and the pair is the invariant — read this
; fixture together with `control_angle_select_reject_cond_register.ll`, which is
; the SAME IR with the stem changed and which declines `condition predates a
; non-diagonal gate`. An in-place Ry RELABELS the register, so after it the flag
; is no longer a function of `q`'s basis and the strip would leave a dirty,
; entangled ancilla (Rules 6/8).
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
; 3qlq: migrated from register cq_phi (angle select -> void call on the select (PRD P2))

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; ONE rail for the whole function: the register, its own condition, and the gate
; all name it.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[Q]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double 0x3FE3333333333334)
; the strip reads the SAME register the controlled Rz just phased — valid because
; a diagonal gate leaves its basis label untouched
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: cqrt_ry_i32_controlled
; NOROUTE-NOT: select

; ONE alloc (the register) and ONE free (the flag).
; CNT-COUNT-1: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
