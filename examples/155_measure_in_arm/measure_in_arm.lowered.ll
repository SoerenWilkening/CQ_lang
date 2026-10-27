; HAND-WRITTEN. Rules: 2, 5, 8, 9.
; Checked: the returned int R = m + x_m with m = (x_m > k) ? y_m : c (classical: x and y measured).
; Clean: the flag F = (x > k) and the select rail m, uncomputed after x's measurement (classical collapse, rule 2).
; Kept: the user registers x and y (both measured).
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1).
; A cq_measure INSIDE A QUANTUM ARM (rule 2). A measurement is never conditioned on quantum data: the cq_measure of y
; is executed UNCONDITIONALLY at its program point, so y is collapsed on the F = 0 branch as well, a deviation from the
; C program's branch-conditioned measurement that is the user's responsibility (the compiler may warn). The flag F is
; never measured. At the arm's merge F still reads the unmeasured x, so m = F ? y_m : c is a quantum select (rule 9)
; into a fresh rail. Then x is measured. From that point F and m depend only on measured rails and classical values,
; so CLASSICAL COLLAPSE (rule 2) applies: m's select and F's compare are uncomputed while x's rail still holds its
; outcome (§1.3: a measured rail may be read as an operand), and F, m and R are recomputed by ordinary classical
; instructions from the outcomes. The function returns a plain int; no handle escapes. 140 is the same collapse with
; the measurement before the merge.
source_filename = "measure_in_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @measure_in_arm(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %8 = cq_theta_si32(%2, %3)  [Ry]
  %9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %4)    ; IR: %9 = icmp sgt i32 %7, %4  [flag F: path predicate of block %10]
  %10 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: block %10: %11 = cq_measure_si32(%8)  [executed unconditionally (rule 2): never conditioned on F]
  %11 = call i32 @cq_template_select_i32_ll(i32 %9, i32 %10, i32 %5)    ; IR: %13 = phi i32 [ %11, %10 ], [ %5, %6 ]  [m = F ? y_m : c, a quantum select while x is unmeasured]
  %12 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %14 = cq_measure_si32(%7)  [from here F and m depend only on measured rails: classical collapse]
  call void @cq_template_select_i32_ll_unc(i32 %11, i32 %9, i32 %10, i32 %5)    ; IR: classical collapse: uncompute m's rail
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %9, i32 %7, i32 %4)    ; IR: uncompute F against x's rail, which holds the outcome %12
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  %13 = icmp sgt i32 %12, %4    ; IR: %9 recomputed classically from the outcome x_m
  %14 = select i1 %13, i32 %10, i32 %5    ; IR: %13 = phi ...: m recomputed classically
  %15 = add nsw i32 %12, %14    ; IR: %15 = add nsw i32 %14, %13  (classical)
  ret i32 %15    ; IR: ret i32 %15  (a plain int)
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
