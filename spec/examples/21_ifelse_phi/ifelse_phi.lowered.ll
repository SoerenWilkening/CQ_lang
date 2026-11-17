; HAND-WRITTEN. Rules: 8, 9, 4, 5, 2.
; Checked: r = (x > k) ? x + c : x * s (measured).
; Clean: the flag (x > k) and both arm values x + c, x * s.
; Kept: the user register x; the merged result rail r (measured).
; Rotations: Ry(th) on x; P(p1) on (x > k); P(p2) on NOT (x > k).
; One flag for the condition: the then-arm phase goes on the flag, the else-arm phase on the negated flag
; (X-bracketed, rule 8); the two arm values are computed unguarded and merge by one select on the flag into a fresh
; rail (rule 9). The arms are uncomputed after the merge, the flag last.
source_filename = "ifelse_phi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ifelse_phi(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6) {
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %8 = cq_theta_si32(%0, %1)  [Ry]
  %9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %8, i32 %2)    ; IR: %9 = icmp sgt i32 %8, %2  [path predicate of %10; its negation is the predicate of %12]
  call void @cqrt_rz_i1(i32 %9, double %5)    ; IR: block %10: cq_phi(%5)
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket: block %12 runs under NOT %9
  call void @cqrt_rz_i1(i32 %9, double %6)    ; IR: block %12: cq_phi(%6)
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket
  %10 = call i32 @cq_template_add_i32_hl(i32 %8, i32 %3)    ; IR: %11 = add nsw i32 %8, %3
  %11 = call i32 @cq_template_mul_i32_hl(i32 %8, i32 %4)    ; IR: %13 = mul nsw i32 %8, %4
  %12 = call i32 @cq_template_select_i32(i32 %9, i32 %10, i32 %11)    ; IR: %15 = phi i32 [ %11, %10 ], [ %13, %12 ]  [result rail]
  call void @cq_template_mul_i32_hl_unc(i32 %11, i32 %8, i32 %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %11)    ; IR: release the %13 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %8, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %9, i32 %8, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %13 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %16 = cq_measure_si32(%15)
  ret i32 %13    ; IR: ret i32 %16
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
