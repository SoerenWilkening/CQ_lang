; HAND-WRITTEN. Rules: 10, 8, 5, 2.
; Checked: r + x (measured) in each function.
; Clean: the flag (x > k).
; Kept: the user register x; r (rotated under control, frozen, measured).
; Rotations: controlled_rotation: Ry(t1) on x; Ry(t2) on r under (x > k). controlled_rotation_ifelse: Ry(t1) on x;
; Ry(ta) on r under (x > k); Ry(tb) on r under NOT (x > k).
; A rotation under a quantum condition is a controlled Ry on the single target rail seeded with r0 (rule 10); the else
; arm is the same gate under the negated flag (an X bracket on the flag, rule 8). One rail for r in both arms, no
; merge copy; the flag is uncomputed after its last controlled gate.
source_filename = "controlled_rotation.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @controlled_rotation(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %7 = icmp sgt i32 %6, %2  [path predicate of block %8]
  %8 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %11 = phi i32 [ %9, %8 ], [ %3, %5 ]  [register r, starts as %3]
  call void @cqrt_ry_i32_controlled(i32 %7, i32 %8, double %4)    ; IR: block %8: %9 = cq_theta_si32(%3, %4)  [Ry under the predicate]
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %6, i32 %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %12 = cq_measure_si32(%11)
  %10 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %13 = cq_measure_si32(%6)
  %11 = add nsw i32 %10, %9    ; IR: %14 = add nsw i32 %13, %12  (classical)
  ret i32 %11    ; IR: ret i32 %14
}

define i32 @controlled_rotation_ifelse(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %8 = icmp sgt i32 %7, %2  [path predicate of %9; its negation is the predicate of %11]
  %9 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %14 = phi i32 [ %10, %9 ], [ %12, %11 ]  [register r, starts as %3 in both arms]
  call void @cqrt_ry_i32_controlled(i32 %8, i32 %9, double %4)    ; IR: block %9: %10 = cq_theta_si32(%3, %4)
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket: block %11 runs under NOT %8
  call void @cqrt_ry_i32_controlled(i32 %8, i32 %9, double %5)    ; IR: block %11: %12 = cq_theta_si32(%3, %5)
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %15 = cq_measure_si32(%14)
  %11 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %16 = cq_measure_si32(%7)
  %12 = add nsw i32 %11, %10    ; IR: %17 = add nsw i32 %16, %15  (classical)
  ret i32 %12    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
