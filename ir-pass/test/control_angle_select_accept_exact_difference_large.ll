; control_angle_select_accept_exact_difference_large.ll — ACCEPT: two HUGE angles
; whose difference is EXACT. The fence is on delta, not on magnitude.
;
; `A = 2^60`, `B = 2^59`, so `A - B = 2^59` is representable with no rounding at
; all: `delta = 0` exactly. Both arms are enormous (2^60 rad is ~1.8e18 full
; turns) and both are FINITE, so the arm-finiteness clause, the
; difference-finiteness clause and the rounding clause all pass, and the shape
; lowers.
;
; WHY THIS FIXTURE EXISTS (bd drbq Inc 2b round-1 Rule-13 review, lens L7-F1/F2):
; the obvious cheap version of the round-1 fence is a magnitude cap ("decline big
; angles"), and it would be WRONG in both directions — it would decline this
; exactly-realizable shape while still accepting `1e-20 / 1.0`, whose arms are
; tiny and whose composed true-arm angle is 0.0. The shipped clause asks the
; TwoSum residual of `A - B`, which is the quantity that actually bounds the
; emitted unitary's error, and this fixture is the one that goes RED if anyone
; re-spells it as a bound on `|A|`, `|B|` or `|A-B|`.
;
; The neighbouring cell that DECLINES is one binade up:
; `control_angle_select_reject_overflow_difference.ll` uses +/-DBL_MAX, where the
; difference overflows to +inf. Same clause family, opposite side.
;
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`).
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
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  ; 0x43B0000000000000 = 2^60 ; 0x43A0000000000000 = 2^59
  %ang = select i1 %c, double 0x43B0000000000000, double 0x43A0000000000000
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
; the twin at B = 2^59 ...
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 0x43A0000000000000)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; ... and the difference is ALSO exactly 2^59, with no rounding anywhere
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x43A0000000000000)
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
