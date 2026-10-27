; HAND-WRITTEN. Rules: 13, 9, 8, 4, 5, 2.
; Checked: switch_value: r (x + a, x * b, x - c or x by x & 3); switch_phase: x (measured).
; Clean: the scrutinee x & 3, the three case flags, switch_value's three arm values and two inner merges.
; Kept: the user register x of each function; switch_value's outer merge rail r (measured).
; Rotations: switch_value: Ry(th) on x. switch_phase: Ry(th) on x; P(p0) on ((x & 3) == 0); P(p1) on ((x & 3) == 1);
; P(p2) on ((x & 3) == 2).
; A switch is one equality flag per case on the scrutinee (rule 13); the cases are mutually exclusive. Value arms merge
; by a chain of selects (default arm innermost, rule 9); phase arms are one kickback per case flag (rule 8). The
; default label is unreachable, so it gets no flag.
source_filename = "switch_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @switch_value(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %7 = and i32 %6, 3  [scrutinee]
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)    ; IR: switch i32 %7: i32 0 -> %8
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 1)    ; IR: switch i32 %7: i32 1 -> %10
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 2)    ; IR: switch i32 %7: i32 2 -> %12
  %11 = call i32 @cq_template_add_i32_hl(i32 %6, i32 %2)    ; IR: %9 = add nsw i32 %6, %2
  %12 = call i32 @cq_template_mul_i32_hl(i32 %6, i32 %3)    ; IR: %11 = mul nsw i32 %6, %3
  %13 = call i32 @cq_template_sub_i32_hl(i32 %6, i32 %4)    ; IR: %13 = sub nsw i32 %6, %4
  %14 = call i32 @cq_template_select_i32(i32 %10, i32 %13, i32 %6)    ; IR: %16 = phi: [ %13, %12 ] else [ %6, %5 ] (case 3)
  %15 = call i32 @cq_template_select_i32(i32 %9, i32 %12, i32 %14)    ; IR: %16 = phi: [ %11, %10 ]
  %16 = call i32 @cq_template_select_i32(i32 %8, i32 %11, i32 %15)    ; IR: %16 = phi: [ %9, %8 ]  [result rail]
  call void @cq_template_select_i32_unc(i32 %15, i32 %9, i32 %12, i32 %14)    ; IR: uncompute the inner merge
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %14, i32 %10, i32 %13, i32 %6)    ; IR: uncompute the innermost merge
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %13, i32 %6, i32 %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %12, i32 %6, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %12)    ; IR: release the %11 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %6, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %7, i32 2)    ; IR: uncompute case-2 flag
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %7, i32 1)    ; IR: uncompute case-1 flag
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)    ; IR: uncompute case-0 flag
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %17    ; IR: ret i32 %17
}

define i32 @switch_phase(i32 noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %7 = and i32 %6, 3  [scrutinee]
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)    ; IR: switch i32 %7: i32 0 -> %11 with %12 = %2
  call void @cqrt_rz_i1(i32 %8, double %2)    ; IR: cq_phi(%12) with %12 = %2
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)    ; IR: uncompute case-0 flag
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 1)    ; IR: switch i32 %7: i32 1 -> %8 -> %11 with %12 = %3
  call void @cqrt_rz_i1(i32 %9, double %3)    ; IR: cq_phi(%12) with %12 = %3
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %7, i32 1)    ; IR: uncompute case-1 flag
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 2)    ; IR: switch i32 %7: i32 2 -> %9 -> %11 with %12 = %4
  call void @cqrt_rz_i1(i32 %10, double %4)    ; IR: cq_phi(%12) with %12 = %4
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %7, i32 2)    ; IR: uncompute case-2 flag
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %14 = cq_measure_si32(%6)
  ret i32 %11    ; IR: ret i32 %14
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
