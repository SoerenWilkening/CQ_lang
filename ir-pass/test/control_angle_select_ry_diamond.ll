; control_angle_select_ry_diamond.ll — ACCEPT spec, the FLAGSHIP angle-select by
; difference (control-in-place-PRD §12.3, bd test_C_libtooling-drbq Inc 2b).
;
;     int q = 3; cq_theta(&q,.5); int r = 7; cq_theta(&r,.25);
;     if (q == 5) cq_theta(&r, .9); else cq_theta(&r, .3);
;
; This is the shape the increment exists for: the C `if/else` with a rotation on
; ONE register in each arm. It never reaches the swap-route emitter at all,
; because there is no diamond left by the time the pass runs.
;
; SHAPE (exactly what `clang -O1` produces — SimplifyCFG merges the two arms of
; `if (c) r = R(r, A); else r = R(r, B);` into ONE call with a `select` on the
; ANGLE, so the branch CFG is gone before the pass runs, Rule 9).
; ⚠ bd test_C_libtooling-fmt3 (2026-09-28): for `cq_theta` the sentence above is
; no longer true. `include/CQ.h` puts `nomerge` on every `cq_theta_*`, so `-O1` keeps
; that if/else an if/else (it lowers through the in-place Ry arm, the same unitary).
; THIS select shape now comes from C only when the select is written out,
; `cq_theta(&r, c ? A : B)` (`tests/e2e/slice_control_angle_select_ry*_ternary.c`,
; measured to give the pre-fmt3 fold's function bodies). The IR and this fixture are
; unchanged; only the C spelling that reaches them moved.
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
; THE CENTRAL WITNESS IS BYTE IDENTITY, NOT THIS FIXTURE. The stream below is
; byte-for-byte the MANUAL by-difference twin
;     cq_theta(&r, .3); if (q == 5) cq_theta(&r, .9 - .3);
; which is an ordinary Inc-1 in-place DIAMOND the PRE-2b binary already lowers.
; Measured on the C forms of both, whole `define` bodies identical, and gated at
; the e2e layer by `e2e-angle-select-ry-twin-identical`. In particular the
; folded difference constant is `0x3FE3333333333334` — the APFloat subtract the
; IRBuilder constant folder performs equals `clang`'s own evaluation of
; `0.9 - 0.3` bit for bit, which is what makes the diff EXACT and not merely
; close.
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
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; THE WHOLE EMITTED STREAM, AS AN ADJACENCY CHAIN. `CHECK-NEXT` throughout,
; deliberately: the Inc-1 round-1 review (lens L6 §1) measured that a loose
; `CHECK`-only form lets an injected `cqrt_x` or `cqrt_cswap` pass GREEN, and a
; fixture whose stated assertion is not the assertion FileCheck evaluates is not
; an assertion.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; the UNCONDITIONAL twin at the FALSE-arm angle B — emitted BEFORE the mint, which
; is what makes the stream identical to the manual by-difference diamond's
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; flag mint, unchanged from every other control path
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; the DIFFERENCE gate, in place on r's own register. The constant is the folded
; `0.9 - 0.3` — pinned as BITS, not as a decimal, because that identity is the
; witness.
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; strip + free: the Ry landed on a rail disjoint from every condition rail (S8),
; so icmp_inv(q) returns the flag to |0> and it is freed clean
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; NO route, no work rail, no select or data mux left standing, and no SECOND
; uncontrolled Ry at the TRUE-arm angle (emitting `ry(r,.9)` unconditionally
; would fire the true arm on both branches — the shape the difference form
; exists to avoid). Anchored at `define` so FileCheck scans the whole body.
; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: select
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; EXACT counts: two allocs (the two source registers, no work rail), ONE free
; (the flag), ONE controlled rotation.
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
