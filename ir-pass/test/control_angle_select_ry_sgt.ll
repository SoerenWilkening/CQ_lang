; control_angle_select_ry_sgt.ll — ACCEPT: a non-equality predicate (`>`), which
; reaches the mint as `icmp sgt` (bd drbq Inc 2b).
;
;     if (q > 5) r = cq_theta(r, .9); else r = cq_theta(r, .3);
;
; Pins that the flag mint is the ORDINARY `lowerCompareToFlag` and carries no
; equality assumption: the accept predicate asks only `comparePredLowerable` +
; `compareFlagMintable`, the same two the `br` and `select` paths ask.
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
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; THE CONDITION REGISTER, ANCHORED AT ITS OWN ALLOC and never on a line of the
; stream under test (round-2 Rule-13 review, lens R2 N1 — see the note at the mint
; below for what stayed green without this).
; CHECK:      %[[QC:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[QC]], double 5.000000e-01)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; the CONDITION REGISTER: `%[[QC]]` was ANCHORED above at its own `cqrt_alloc`,
; so the mint and the strip must both name THAT rail — not merely the same one as
; each other (round-1 Rule-13 review L6-N3 closed mint-vs-strip DISAGREEMENT; the
; round-2 one, lens R2 N1, found that a CONSISTENTLY wrong condition rail — both
; lines rewritten to read the ROTATED register — still passed, because `%[[QC]]`
; was first bound HERE, on a line of the stream under test. On the Ry stem that
; mutant is also a Rule-6 hazard: the controlled Ry between mint and strip
; relabels the very rail being compared, so the strip does not recompute the
; predicate the mint read, the flag does not return to |0> and its `cqrt_free` is
; a hidden measurement).
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[QC]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[QC]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
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
; NOROUTE-NOT: select

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
