; control_angle_select_ry_runtime_arms.ll — ACCEPT: a Ry angle select whose two
; arms are RUN-TIME classical doubles (bd test_C_libtooling-dm7f.6; owner rulings
; 2026-10-03 item (2) and 2026-10-13 `owner-ruling-angle-select-xbracket`).
;
;     int f(double x, double y) { ... cq_theta(&r, (q == 5) ? x : y); ... }
;
; THE STREAM is the X-bracket form on the minted flag ancilla, the stream the
; if/else in-place Ry arm emits for the same program:
;
;     f = [q == 5]; ry_c(f, r, x); x(f); ry_c(f, r, y); x(f); strip f; free f
;
; f = 1 fires Ry(x) only, f = 0 Ry(y) only. Each arm reaches exactly ONE gate
; slot verbatim, so no arithmetic, no freeze (no arm is read twice) and no
; `fneg` appear: `@plain` (parameters without `noundef`) and `@nund` (`noundef`
; parameters, what clang emits for C) lower identically.
;
; THIS FILE WAS `control_angle_select_reject_runtime_arms.ll` (constant arms
; only, drbq Inc-2b clearance finding F-11, whose subject was the retired
; by-difference `fl(A-B)`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.ll
; RUN: %filecheck %s --check-prefix=NOSUB < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @plain(i32 %u0, i32 %u1, double %x, double %y) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %x, double %y
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

define i32 @nund(i32 %u0, i32 %u1, double noundef %x, double noundef %y) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %x, double %y
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; CHECK-LABEL: define i32 @plain(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double %x)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double %y)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

; CHECK-LABEL: define i32 @nund(
; CHECK:      %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q2]], double 5.000000e-01)
; CHECK-NEXT: %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R2]], double 3.000000e-01)
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q2]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[R2]], double %x)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[R2]], double %y)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[Q2]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])

; One flag per function, freed once; the rotated register is frozen (never freed).
; CNT-LABEL:   define i32 @plain(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
; CNT-LABEL:   define i32 @nund(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; NOSUB-NOT: fsub
; NOSUB-NOT: fneg
; NOSUB-NOT: freeze
