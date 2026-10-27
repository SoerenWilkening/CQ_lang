; HAND-WRITTEN. Rules: 9, 8, 4, 5.
; Checked: r (measured).
; Clean: the three flags, the five arm rails and the two inner merges, all freed.
; Kept: none.
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1); (Ry, z, tz, 1).
; Value arms nested three deep on three quantum conditions, four leaves. Rule 9: every arm is pure, so every leaf value
; is computed unguarded into fresh rails, and the phi is a chain of one select per level under that level's own flag,
; the complement arm innermost at each level: level 3 merges (z > c ? x + y + z : x * y), level 2 merges that against
; y - d under y > b, level 1 merges that against z + d under x > a. An inner select is only read where its parent's flag
; selects it, so the flags are NOT conjoined: no gate fires under a path predicate here (a conjunction flag would be
; needed only for a phase or a rotation inside the nest, as 137 / 152). Teardown is LIFO.
source_filename = "value_arm_depth3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @value_arm_depth3(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5, i32 noundef %6, i32 noundef %7, i32 noundef %8, i32 noundef %9) {
  %11 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %11 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %11, double %1)    ; IR: %11 = cq_theta_si32(%0, %1)  [Ry]
  %12 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %12 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %12, double %3)    ; IR: %12 = cq_theta_si32(%2, %3)  [Ry]
  %13 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: %13 = cq_theta_si32(%4, %5)  [register z]
  call void @cqrt_ry_i32(i32 %13, double %5)    ; IR: %13 = cq_theta_si32(%4, %5)  [Ry]
  %14 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %11, i32 %6)    ; IR: %14 = icmp sgt i32 %11, %6  [level-1 flag]
  %15 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %12, i32 %7)    ; IR: %16 = icmp sgt i32 %12, %7  [level-2 flag, block %15, pure: computed unguarded]
  %16 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %13, i32 %8)    ; IR: %18 = icmp sgt i32 %13, %8  [level-3 flag, block %17]
  %17 = call i32 @cq_template_add_i32(i32 %12, i32 %11)    ; IR: %20 = add nsw i32 %12, %11  (block %19)
  %18 = call i32 @cq_template_add_i32(i32 %17, i32 %13)    ; IR: %21 = add nsw i32 %20, %13  (block %19)
  %19 = call i32 @cq_template_mul_i32(i32 %12, i32 %11)    ; IR: %23 = mul nsw i32 %12, %11  (block %22)
  %20 = call i32 @cq_template_sub_i32_hl(i32 %12, i32 %9)    ; IR: %25 = sub nsw i32 %12, %9  (block %24)
  %21 = call i32 @cq_template_add_i32_hl(i32 %13, i32 %9)    ; IR: %27 = add nsw i32 %13, %9  (block %26)
  %22 = call i32 @cq_template_select_i32(i32 %16, i32 %18, i32 %19)    ; IR: %29 = phi: [ %21, %19 ] else [ %23, %22 ]  (level 3)
  %23 = call i32 @cq_template_select_i32(i32 %15, i32 %22, i32 %20)    ; IR: %29 = phi: level 3 else [ %25, %24 ]  (level 2)
  %24 = call i32 @cq_template_select_i32(i32 %14, i32 %23, i32 %21)    ; IR: %29 = phi: level 2 else [ %27, %26 ]  (level 1) [result rail]
  call void @cq_template_select_i32_unc(i32 %23, i32 %15, i32 %22, i32 %20)    ; IR: uncompute the level-2 merge
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %22, i32 %16, i32 %18, i32 %19)    ; IR: uncompute the level-3 merge
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %21, i32 %13, i32 %9)    ; IR: uncompute %27
  call void @cqrt_free(i32 %21)    ; IR: release the %27 rail (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %20, i32 %12, i32 %9)    ; IR: uncompute %25
  call void @cqrt_free(i32 %20)    ; IR: release the %25 rail (|0>)
  call void @cq_template_mul_i32_unc(i32 %19, i32 %12, i32 %11)    ; IR: uncompute %23
  call void @cqrt_free(i32 %19)    ; IR: release the %23 rail (|0>)
  call void @cq_template_add_i32_unc(i32 %18, i32 %17, i32 %13)    ; IR: uncompute %21
  call void @cqrt_free(i32 %18)    ; IR: release the %21 rail (|0>)
  call void @cq_template_add_i32_unc(i32 %17, i32 %12, i32 %11)    ; IR: uncompute %20
  call void @cqrt_free(i32 %17)    ; IR: release the %20 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %16, i32 %13, i32 %8)    ; IR: uncompute %18
  call void @cqrt_free(i32 %16)    ; IR: release the %18 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %15, i32 %12, i32 %7)    ; IR: uncompute %16
  call void @cqrt_free(i32 %15)    ; IR: release the %16 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %14, i32 %11, i32 %6)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  %25 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %30 = cq_measure_si32(%29)
  ret i32 %25    ; IR: ret i32 %30
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
