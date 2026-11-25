; HAND-WRITTEN. Rules: 6, 2, 3, 4, 5, 8.
; Checked: y' + x (measured).
; Clean: the compare flag f = (x > k) and its zext z, both uncomputed and freed.
; Kept: none (x and y' are user registers; y' is the y rail).
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1); (Ry, y' = y + [x > k], t, 1).
; -O1 folds `if (x > k) y += 1` into `y + zext(x > k)` (no branch, no phi): a plain add of the zext rail. Rule 6's
; in-place update: the old y is dead and y' = y + z is a bijection in y for fixed z, so the add is ONE core gate,
; add_i32(z, y), on the y rail, which is y' from there on (no template, no fresh rail, no clean-up, no free of y). y' is
; then the register of the second cq_theta (rule 2: a rotation of an existing handle is in place). z and f are uncomputed
; before that Ry (their sources x, f are unchanged). Nothing dirty survives into the rotation, so no record of the
; pre-rotation value of y' can dephase it.
source_filename = "value_arm_then_rotate.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @value_arm_then_rotate(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %8 = cq_theta_si32(%2, %3)  [Ry]
  %9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %4)    ; IR: %9 = icmp sgt i32 %7, %4
  %10 = call i32 @cq_template_zext_i1_to_i32(i32 %9)    ; IR: %10 = zext i1 %9 to i32
  call void @cqrt_add_i32(i32 %10, i32 %8)    ; IR: %11 = add nsw i32 %8, %10  [rule 6, in-place update: y is dead after the add, so y' IS the y rail: y += z]
  call void @cq_template_zext_i1_to_i32_unc(i32 %10, i32 %9)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %9, i32 %7, i32 %4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cqrt_ry_i32(i32 %8, double %5)    ; IR: %12 = cq_theta_si32(%11, %5)  [Ry in place on y'; every garbage rail is already clean]
  %11 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %13 = cq_measure_si32(%12)
  %12 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %14 = cq_measure_si32(%7)
  %13 = add nsw i32 %12, %11    ; IR: %15 = add nsw i32 %14, %13  (classical)
  ret i32 %13    ; IR: ret i32 %15
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_add_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
