; control_angle_select_ry_ne_swapped.ll — ACCEPT: the `!=` source, which reaches
; the pass as `icmp eq` with the SELECT OPERANDS SWAPPED (bd drbq Inc 2b).
;
;     if (q != 5) cq_theta(&r, .9); else cq_theta(&r, .3);
;
; `clang -O1` canonicalizes `q != 5` to `icmp eq i32 %q, 5` and then swaps the
; select's arms rather than inverting the condition (measured — probe p7). THE
; POINT OF THIS FIXTURE IS THAT NOTHING SPECIAL HAPPENS: a select ALWAYS means
; "true value when the flag is 1", so the f = 1 gate takes the TRUE operand
; `.3` and the bracketed f = 0 gate the FALSE operand `.9` (the `q != 5` arm's
; angle), exactly the if/else in-place arm's stream (bd dm7f.6; the by-difference
; stream this file first pinned took `fl(.3 - .9)`). A swap mutant would put
; `.9` first.
; There is no polarity case and NO `cqrt_x` bracket
; anywhere in this stream — unlike the `br`-diamond paths, where Rule 9's
; false-successor canonicalization forces one.
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
; LOWERED IN THE X-BRACKET FORM (bd dm7f.6, owner ruling 2026-10-13): mint,
; `cqrt_ry_<W>_controlled(f, h, A)`, `cqrt_x(f); ..._controlled(f, h, B);
; cqrt_x(f)`, strip, ONE `cqrt_free`. The `cqrt_x` pair is on the flag ancilla;
; it expresses the f = 0 gate, not a polarity fix.
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
; f = 1 (`q == 5`) takes the TRUE operand `.3`; the bracketed f = 0 gate the FALSE
; operand `.9`, the `q != 5` arm's own angle
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
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
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: select

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
