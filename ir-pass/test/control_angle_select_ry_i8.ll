; control_angle_select_ry_i8.ll — ACCEPT at a SUB-i32 width (bd drbq Inc 2b).
;
; The second half of the HANDLE-TYPING pin (see
; `control_angle_select_ry_f64_fcmp.ll`, whose header also records the measured
; limit of the claim: the work-list insert POSITION is kept to avoid a transient
; malformed call, and does NOT change the final IR — mutation M15 measured
; byte-identical output with the twin appended instead). Here the register's
; logical type is `i8` while its handle is `i32`. All three emitted `cqrt_ry_i8`
; calls (the unconditional gate and, since bd dm7f.6, two controlled ones) take an
; `i32` handle and the classical compare literal stays `i8` — the ABI's
; width-only rule (Rule 15: a runtime handle is ALWAYS `i32`, the literal carries
; the width).
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`, SelectClassify gate 3) — Rule 12 red-green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i8 @cq_theta_c(i8, double)
declare i8 @cq_measure_c(i8)

define i8 @example(i8 %u0, i8 %u1) {
entry:
  %q = call i8 @cq_theta_c(i8 %u0, double 5.000000e-01)
  %r = call i8 @cq_theta_c(i8 %u1, double 3.000000e-01)
  %c = icmp eq i8 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i8 @cq_theta_c(i8 %r, double %ang)
  %mr = call i8 @cq_measure_c(i8 %t)
  %mq = call i8 @cq_measure_c(i8 %q)
  %s = add i8 %mr, %mq
  ret i8 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u0)
; CHECK-NEXT: call void @cqrt_ry_i8(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u1)
; CHECK-NEXT: call void @cqrt_ry_i8(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i8_hl(i32 %[[Q]], i8 5)
; CHECK-NEXT: call void @cqrt_ry_i8_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i8_controlled(i32 %[[F]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i8_hl_unc(i32 %[[F]], i32 %[[Q]], i8 5)
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
; NOROUTE-NOT: cqrt_ry_i8(i8
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: select

; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
