; HAND-WRITTEN. Rules: 9, 8, 4, 5, 2.
; Checked: r (measured, %13 -> %14).
; Clean: the outer flag %8 = (x > k1), the arm value %9 = x + c, the inner flag %10 = (r < k2), the all-classical select
; %11 = (%10 ? s : 1) and the product %12, all uncomputed LIFO and freed before the measurement.
; Kept: x (%7, the rotated register) and the result rail %13 (measured); nothing else.
; Rotations: (Ry, x, th, 1).
; Nested value arms (rule 9): both arms are pure, so their code is hoisted and computed unguarded into fresh rails. -O1
; folds the inner `if (r < k2) r = r * s` into `r * (r < k2 ? s : 1)`: that all-classical select on the inner flag is one
; select_i32_ll template (both data operands literals), the product is a two-handle mul, and the outer merge
; `x > k1 ? product : x` is one select_i32 template into the fresh result rail %13. No gate fires under control; every
; intermediate is uncomputed by its template's _unc in reverse order and freed.
source_filename = "nested_value_arms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nested_value_arms(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %8 = icmp sgt i32 %7, %2
  %9 = call i32 @cq_template_add_i32_hl(i32 %7, i32 %4)    ; IR: %9 = add nsw i32 %7, %4
  %10 = call i32 @cq_template_icmp_slt_i32_hl(i32 %9, i32 %3)    ; IR: %10 = icmp slt i32 %9, %3
  %11 = call i32 @cq_template_select_i32_ll(i32 %10, i32 %5, i32 1)    ; IR: %11 = select i1 %10, i32 %5, i32 1  (both arms classical)
  %12 = call i32 @cq_template_mul_i32(i32 %11, i32 %9)    ; IR: %12 = mul nsw i32 %11, %9
  %13 = call i32 @cq_template_select_i32(i32 %8, i32 %12, i32 %7)    ; IR: %13 = select i1 %8, i32 %12, i32 %7  [result rail]
  call void @cq_template_mul_i32_unc(i32 %12, i32 %11, i32 %9)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %11, i32 %10, i32 %5, i32 1)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %10, i32 %9, i32 %3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %7, i32 %4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %14 = call i32 @cqrt_measure_i32(i32 %13)    ; IR: %14 = cq_measure_si32(%13)
  ret i32 %14    ; IR: ret i32 %14
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
