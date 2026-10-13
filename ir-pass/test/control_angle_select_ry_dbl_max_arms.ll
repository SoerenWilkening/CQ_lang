; control_angle_select_ry_dbl_max_arms.ll — ACCEPT: both arms FINITE and of
; opposite sign at `DBL_MAX` (bd test_C_libtooling-dm7f.6, owner ruling
; 2026-10-03).
;
;     cq_theta(&r, (q == 5) ? DBL_MAX : -DBL_MAX);
;
; The cell that showed the retired by-difference stream MANUFACTURING an infinity
; from two finite arms (`fl(DBL_MAX - (-DBL_MAX)) = +inf`). The X-bracket route
; (owner ruling 2026-10-13) performs no arithmetic: `DBL_MAX` fires on f = 1 and
; `-DBL_MAX` inside the bracket on f = 0. Every slot holds a finite double the
; source names, and no infinity appears anywhere (NOINF).
;
; THIS FILE WAS `control_angle_select_reject_overflow_difference.ll` (drbq Inc-2b
; round-1 finding L7-F2).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOINF < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 0x7FEFFFFFFFFFFFFF, double 0xFFEFFFFFFFFFFFFF
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
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x7FEFFFFFFFFFFFFF)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0xFFEFFFFFFFFFFFFF)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; NOINF-NOT: 0x7FF0000000000000
; NOINF-NOT: 0xFFF0000000000000
; NOINF-NOT: fsub
