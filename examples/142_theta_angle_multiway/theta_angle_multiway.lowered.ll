; HAND-WRITTEN. Rules: 11, 15, 9, 13, 20, 4, 5, 2.
; Checked: r + x (measured) in each function.
; Clean: every flag (x > k1, x > k2; the case flags (x & 3) == 0, 1, 2), every angle rail (the inner selects and A),
; the scrutinee / index x & 3 (theta_switch_angle, theta_table_angle), all uncomputed and freed.
; Kept: the user register x of each function; r (seeded with r0, rotated by the angle rail, measured).
; Rotations: theta_nested_angle_select: (Ry, x, th, 1); (Ry, r, val(A), 1) with A = select(x > k1, a, select(x > k2,
; b, c)). theta_switch_angle: (Ry, x, th, 1); (Ry, r, val(A), 1) with A = select((x & 3) == 0, p0, select((x & 3) == 1,
; p1, select((x & 3) == 2, p2, p3))). theta_table_angle: (Ry, x, th, 1); (Ry, r, val(A), 1) with A = tab[x & 3],
; tab = {0.1, 0.2, 0.3, 0.4}.
; A MULTI-WAY ANGLE for cq_theta is a QUANTUM ANGLE (rule 11): whatever picks the angle, it is computed into an f64 rail
; by ordinary templates and ONE cqrt_ry_i32_qangle(r, A) consumes it (rule 15); the compiler never expands it into
; per-arm controlled Ry, the N-bit ladder is the backend's. The three sources of the angle: a select of selects nests
; its selects (rule 9: the inner select on the inner flag, computed unguarded, is the else arm of the outer one;
; runtime-classical arms are literals, select_f64_ll / _lh); a switch over a quantum scrutinee is the select chain over
; its case eq flags (rule 13; the default is unreachable, so the last case 3 is the complement, needs no flag and is the
; innermost arm, as 49); a constant table read at a quantum index is one QROM load cq_template_qrom_load_f64 on the
; logical index rail x & 3 (rule 20; the zext and the GEP are address arithmetic, never emitted), as 184 does. The
; register r keeps its classical seed via cqrt_alloc and is rotated once. Afterwards the angle chain is uncomputed LIFO
; and freed, then the flags and the scrutinee (rule 5).
source_filename = "theta_angle_multiway.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@theta_table_angle.tab = internal unnamed_addr constant [4 x double] [double 1.000000e-01, double 2.000000e-01, double 3.000000e-01, double 4.000000e-01], align 16

define i32 @theta_nested_angle_select(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6, double noundef %7) {
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %9, i32 %2)    ; IR: %10 = icmp sgt i32 %9, %2  [outer select flag]
  %11 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %9, i32 %3)    ; IR: %11 = icmp sgt i32 %9, %3  [inner select flag]
  %12 = call i32 @cq_template_select_f64_ll(i32 %11, double %6, double %7)    ; IR: %12 = select i1 %11, double %6, double %7  [inner angle rail, unguarded]
  %13 = call i32 @cq_template_select_f64_lh(i32 %10, double %5, i32 %12)    ; IR: %13 = select i1 %10, double %5, double %12  [angle rail A]
  %14 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: %14 = cq_theta_si32(%4, %13)  [register r, seeded with r0]
  call void @cqrt_ry_i32_qangle(i32 %14, i32 %13)    ; IR: %14 = cq_theta_si32(%4, %13)  [Ry(val(A)) on r]
  call void @cq_template_select_f64_lh_unc(i32 %13, i32 %10, double %5, i32 %12)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the angle rail (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %12, i32 %11, double %6, double %7)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the inner angle rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %11, i32 %9, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %9, i32 %2)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  %15 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %15 = cq_measure_si32(%14)
  %16 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %16 = cq_measure_si32(%9)
  %17 = add nsw i32 %16, %15    ; IR: %17 = add nsw i32 %16, %15  (classical)
  ret i32 %17    ; IR: ret i32 %17
}

define i32 @theta_switch_angle(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4, double noundef %5, double noundef %6) {
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %8 = cq_theta_si32(%0, %1)  [Ry]
  %9 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %9 = and i32 %8, 3  [scrutinee]
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 0)    ; IR: switch i32 %9: i32 0 -> %14  [case-0 flag]
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 1)    ; IR: switch i32 %9: i32 1 -> %10  [case-1 flag]
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 2)    ; IR: switch i32 %9: i32 2 -> %11  [case-2 flag; case 3 -> %13 is the complement (default %12 unreachable): no flag]
  %13 = call i32 @cq_template_select_f64_ll(i32 %12, double %5, double %6)    ; IR: %15 = phi: [ %5, %11 ] else [ %6, %13 ]  (innermost: case 2 against case 3)
  %14 = call i32 @cq_template_select_f64_lh(i32 %11, double %4, i32 %13)    ; IR: %15 = phi: [ %4, %10 ]  (case 1)
  %15 = call i32 @cq_template_select_f64_lh(i32 %10, double %3, i32 %14)    ; IR: %15 = phi: [ %3, %7 ]  (case 0)  [angle rail A]
  %16 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %16 = cq_theta_si32(%2, %15)  [register r, seeded with r0]
  call void @cqrt_ry_i32_qangle(i32 %16, i32 %15)    ; IR: %16 = cq_theta_si32(%2, %15)  [Ry(val(A)) on r]
  call void @cq_template_select_f64_lh_unc(i32 %15, i32 %10, double %3, i32 %14)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the angle rail (|0>)
  call void @cq_template_select_f64_lh_unc(i32 %14, i32 %11, double %4, i32 %13)    ; IR: uncompute the case-1 merge
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_select_f64_ll_unc(i32 %13, i32 %12, double %5, double %6)    ; IR: uncompute the innermost merge
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %9, i32 2)    ; IR: uncompute the case-2 flag
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %9, i32 1)    ; IR: uncompute the case-1 flag
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 0)    ; IR: uncompute the case-0 flag
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %8, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %17 = cq_measure_si32(%16)
  %18 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %18 = cq_measure_si32(%8)
  %19 = add nsw i32 %18, %17    ; IR: %19 = add nsw i32 %18, %17  (classical)
  ret i32 %19    ; IR: ret i32 %19
}

define i32 @theta_table_angle(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %5 = and i32 %4, 3  [logical index rail; %6 = zext and %7 = GEP are address arithmetic]
  %6 = call i32 @cq_template_qrom_load_f64(ptr @theta_table_angle.tab, i64 4, i32 %5)    ; IR: %7 = getelementptr tab, %6; %8 = load double, ptr %7  [QROM: constant table, quantum index; angle rail A]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %9 = cq_theta_si32(%2, %8)  [register r, seeded with r0]
  call void @cqrt_ry_i32_qangle(i32 %7, i32 %6)    ; IR: %9 = cq_theta_si32(%2, %8)  [Ry(val(A)) on r]
  call void @cq_template_qrom_load_f64_unc(i32 %6, ptr @theta_table_angle.tab, i64 4, i32 %5)    ; IR: uncompute %8
  call void @cqrt_free(i32 %6)    ; IR: release the angle rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 3)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %10 = cq_measure_si32(%9)
  %9 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %11 = cq_measure_si32(%4)
  %10 = add nsw i32 %9, %8    ; IR: %12 = add nsw i32 %11, %10  (classical)
  ret i32 %10    ; IR: ret i32 %12
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_qangle(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_f64_ll(i32, double, double)
declare void @cq_template_select_f64_ll_unc(i32, i32, double, double)
declare i32 @cq_template_select_f64_lh(i32, double, i32)
declare void @cq_template_select_f64_lh_unc(i32, i32, double, i32)
declare i32 @cq_template_qrom_load_f64(ptr, i64, i32)
declare void @cq_template_qrom_load_f64_unc(i32, ptr, i64, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
