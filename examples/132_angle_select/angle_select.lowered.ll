; HAND-WRITTEN. Rules: 11, 15, 9, 8, 5, 2.
; Checked: phi_angle_select and nested_angle_select: x; theta_angle_select and shared_angle_select: r + x (measured).
; Clean: every select flag (x > k, x > k1, x > k2), every angle rail A and nested_angle_select's inner angle rail, all
; uncomputed and freed.
; Kept: the user register x of each function; r (rotated by the angle rail, measured) in theta_angle_select and
; shared_angle_select.
; Rotations: phi_angle_select: (Ry, x, th, 1); (P, A, val(A), 1) with A = select(x > k, a, b). theta_angle_select:
; (Ry, x, th, 1); (Ry, r, val(A), 1) with A = select(x > k, a, b). nested_angle_select: (Ry, x, th, 1); (P, A, val(A), 1)
; with A = select(x > k1, a, select(x > k2, b, c)). shared_angle_select: (Ry, x, th, 1); (P, A, val(A), 1);
; (Ry, r, val(A), 1) with the one A = select(x > k, a, b).
; An ANGLE SELECT is a QUANTUM ANGLE (rule 11): the angle depends on a quantum flag, so it is computed into an f64 rail
; by the ordinary select template (rule 9; the arms a, b, c are runtime-classical doubles, so cq_template_select_f64_ll,
; and a select of selects nests: the inner select's rail is the else arm of the outer one, select_f64_lh), and ONE
; primitive consumes the rail (rule 15): cqrt_rz_qangle(A) for cq_phi (register-free; no quantum predicate is in scope,
; so the phase e^{i val(A)} lands on each branch of A and stays on the branches of x when A and the flag are
; uncomputed) and
; cqrt_ry_i32_qangle(r, A) for cq_theta on the seeded register r. The compiler never expands the select into per-arm
; controlled rotations; the N-bit ladder is the backend's. One select read by two consumers (shared_angle_select) is
; one angle rail read by both primitives and uncomputed once, after the second. Each angle chain is uncomputed LIFO and
; freed (rule 5), then the flags.
source_filename = "angle_select.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @phi_angle_select(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %7 = icmp sgt i32 %6, %2  [the select's flag]
  %8 = call i32 @cq_template_select_f64_ll(i32 %7, double %3, double %4)    ; IR: %8 = select i1 %7, double %3, double %4  [angle rail A]
  call void @cqrt_rz_qangle(i32 %8)    ; IR: cq_phi(%8)  [phase e^{i val(A)}, no quantum predicate in scope]
  call void @cq_template_select_f64_ll_unc(i32 %8, i32 %7, double %3, double %4)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the angle rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %6, i32 %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %9 = cq_measure_si32(%6)
  ret i32 %9    ; IR: ret i32 %9
}

define i32 @theta_angle_select(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %8 = icmp sgt i32 %7, %2  [the select's flag]
  %9 = call i32 @cq_template_select_f64_ll(i32 %8, double %4, double %5)    ; IR: %9 = select i1 %8, double %4, double %5  [angle rail A]
  %10 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %10 = cq_theta_si32(%3, %9)  [register r, seeded with r0]
  call void @cqrt_ry_i32_qangle(i32 %10, i32 %9)    ; IR: %10 = cq_theta_si32(%3, %9)  [Ry(val(A)) on r]
  call void @cq_template_select_f64_ll_unc(i32 %9, i32 %8, double %4, double %5)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the angle rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %11 = cq_measure_si32(%10)
  %12 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %12 = cq_measure_si32(%7)
  %13 = add nsw i32 %12, %11    ; IR: %13 = add nsw i32 %12, %11  (classical)
  ret i32 %13    ; IR: ret i32 %13
}

define i32 @nested_angle_select(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5, double noundef %6) {
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %8 = cq_theta_si32(%0, %1)  [Ry]
  %9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %8, i32 %2)    ; IR: %9 = icmp sgt i32 %8, %2  [outer select flag]
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %8, i32 %3)    ; IR: %10 = icmp sgt i32 %8, %3  [inner select flag]
  %11 = call i32 @cq_template_select_f64_ll(i32 %10, double %5, double %6)    ; IR: %11 = select i1 %10, double %5, double %6  [inner angle rail, unguarded]
  %12 = call i32 @cq_template_select_f64_lh(i32 %9, double %4, i32 %11)    ; IR: %12 = select i1 %9, double %4, double %11  [angle rail A]
  call void @cqrt_rz_qangle(i32 %12)    ; IR: cq_phi(%12)  [phase e^{i val(A)}, no quantum predicate in scope]
  call void @cq_template_select_f64_lh_unc(i32 %12, i32 %9, double %4, i32 %11)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the angle rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %11, i32 %10, double %5, double %6)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the inner angle rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %8, i32 %3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %9, i32 %8, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %13 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %13 = cq_measure_si32(%8)
  ret i32 %13    ; IR: ret i32 %13
}

define i32 @shared_angle_select(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %8 = icmp sgt i32 %7, %2  [the select's flag]
  %9 = call i32 @cq_template_select_f64_ll(i32 %8, double %4, double %5)    ; IR: %9 = select i1 %8, double %4, double %5  [angle rail A, read by both consumers]
  call void @cqrt_rz_qangle(i32 %9)    ; IR: cq_phi(%9)  [phase e^{i val(A)}, no quantum predicate in scope]
  %10 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %10 = cq_theta_si32(%3, %9)  [register r, seeded with r0]
  call void @cqrt_ry_i32_qangle(i32 %10, i32 %9)    ; IR: %10 = cq_theta_si32(%3, %9)  [Ry(val(A)) on r]
  call void @cq_template_select_f64_ll_unc(i32 %9, i32 %8, double %4, double %5)    ; IR: uncompute %9 (once, after both consumers)
  call void @cqrt_free(i32 %9)    ; IR: release the angle rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %11 = cq_measure_si32(%10)
  %12 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %12 = cq_measure_si32(%7)
  %13 = add nsw i32 %12, %11    ; IR: %13 = add nsw i32 %12, %11  (classical)
  ret i32 %13    ; IR: ret i32 %13
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_qangle(i32, i32)
declare void @cqrt_rz_qangle(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_f64_ll(i32, double, double)
declare void @cq_template_select_f64_ll_unc(i32, i32, double, double)
declare i32 @cq_template_select_f64_lh(i32, double, i32)
declare void @cq_template_select_f64_lh_unc(i32, i32, double, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
