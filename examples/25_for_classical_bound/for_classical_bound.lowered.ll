; HAND-WRITTEN. Rules: 14, 4, 5, 7, 2.
; Checked: acc after n trips of acc = acc * c + x (measured).
; Clean: every trip's product and sum rails (popped and uncomputed by the mirror) and the |0> seed of acc (never
; written, freed directly, rule 7).
; Kept: the user register x; the copied-out result rail (measured).
; Rotations: Ry(th) on x.
; The bound n is classical, so the loop stays a classical loop with no predicate (rule 14): each trip computes the next
; accumulator into a fresh rail and pushes its handles; after the result is copied out, a reverse loop pops and
; uncomputes every trip. n <= 0 takes the classical edge and measures the seed rail itself.
source_filename = "for_classical_bound.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @for_classical_bound(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %12 / %8  [acc before trip 0]
  %7 = icmp sgt i32 %2, 0    ; IR: %6 = icmp sgt i32 %2, 0
  br i1 %7, label %10, label %8    ; IR: br i1 %6, label %10, label %7

8:
  %9 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %9 = cq_measure_si32(%8), %8 = 0 from %4
  ret i32 %9    ; IR: ret i32 %9

10:
  %11 = phi i32 [ 0, %4 ], [ %15, %10 ]    ; IR: %11 = phi i32 [ %15, %10 ], [ 0, %4 ]  (classical)
  %12 = phi i32 [ %6, %4 ], [ %14, %10 ]    ; IR: %12 = phi i32 [ %14, %10 ], [ 0, %4 ]
  %13 = call i32 @cq_template_mul_i32_hl(i32 %12, i32 %3)    ; IR: %13 = mul nsw i32 %12, %3
  %14 = call i32 @cq_template_add_i32(i32 %13, i32 %5)    ; IR: %14 = add nsw i32 %13, %5
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  %15 = add nuw nsw i32 %11, 1    ; IR: %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %2    ; IR: %16 = icmp eq i32 %15, %2
  br i1 %16, label %17, label %10    ; IR: br i1 %16, label %7, label %10

17:
  %18 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %8 = phi i32 [ %14, %10 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %14, i32 %18)    ; IR: %8
  br label %19

19:
  %20 = phi i32 [ 0, %17 ], [ %24, %19 ]
  %21 = phi i32 [ %14, %17 ], [ %23, %19 ]    ; IR: %14 of the trip being undone
  %22 = call i32 @cqrt_pop()
  %23 = call i32 @cqrt_pop()
  call void @cq_template_add_i32_unc(i32 %21, i32 %22, i32 %5)    ; IR: uncompute %14
  call void @cqrt_free(i32 %21)    ; IR: release the %14 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %22, i32 %23, i32 %3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %22)    ; IR: release the %13 rail (|0>)
  %24 = add nuw nsw i32 %20, 1
  %25 = icmp eq i32 %24, %2
  br i1 %25, label %26, label %19

26:
  call void @cqrt_free(i32 %23)    ; IR: release incoming 0 of phi %12 (never written, |0>)
  %27 = call i32 @cqrt_measure_i32(i32 %18)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %27    ; IR: ret i32 %9
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
