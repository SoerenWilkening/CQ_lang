; HAND-WRITTEN. Rules: 14, 4, 5, 7, 2.
; Checked: acc = sum over i < n, j < m of (x ^ (i * c + j)) (measured).
; Clean: every inner trip's xor and sum rails (popped and uncomputed by the nested mirror) and the |0> seed of acc
; (never written, freed directly, rule 7).
; Kept: the user register x; the copied-out result rail (measured).
; Rotations: Ry(th) on x.
; Both bounds are classical (rule 14): the lowering is the same nested classical loop; the quantum body pushes its
; handles, and a nested reverse loop pops and uncomputes them, inner trips from m-1 down to 0 inside outer trips from
; n-1 down to 0. The classical i * c + j is recomputed in the mirror from the trip indices. n <= 0 takes the classical
; edge and measures the seed rail itself.
source_filename = "nested_loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nested_loops(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %12 / %16  [acc before any trip]
  %8 = icmp sgt i32 %2, 0    ; IR: %7 = icmp sgt i32 %2, 0
  br i1 %8, label %11, label %9    ; IR: br i1 %7, label %8, label %15

9:
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %17 = cq_measure_si32(%16), %16 = 0 from %5
  ret i32 %10    ; IR: ret i32 %17

11:
  %12 = phi i32 [ 0, %5 ], [ %26, %24 ]    ; IR: %11 = phi i32 [ 0, %8 ], [ %20, %18 ]  (classical)
  %13 = phi i32 [ %7, %5 ], [ %25, %24 ]    ; IR: %12 = phi i32 [ 0, %8 ], [ %19, %18 ]
  %14 = icmp sgt i32 %3, 0    ; IR: %9 = icmp sgt i32 %3, 0
  %15 = mul nsw i32 %12, %4    ; IR: %14 = mul nsw i32 %11, %4  (classical)
  br i1 %14, label %16, label %24    ; IR: br i1 %9, label %13, label %18

16:
  %17 = phi i32 [ 0, %11 ], [ %22, %16 ]    ; IR: %23 = phi i32 [ 0, %13 ], [ %28, %22 ]  (classical)
  %18 = phi i32 [ %13, %11 ], [ %21, %16 ]    ; IR: %24 = phi i32 [ %12, %13 ], [ %27, %22 ]
  %19 = add nsw i32 %17, %15    ; IR: %25 = add nsw i32 %23, %14  (classical)
  %20 = call i32 @cq_template_xor_i32_hl(i32 %6, i32 %19)    ; IR: %26 = xor i32 %25, %6
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %18)    ; IR: %27 = add nsw i32 %26, %24
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %20)
  %22 = add nuw nsw i32 %17, 1    ; IR: %28 = add nuw nsw i32 %23, 1
  %23 = icmp eq i32 %22, %3    ; IR: %29 = icmp eq i32 %28, %3
  br i1 %23, label %24, label %16    ; IR: br i1 %29, label %18, label %22

24:
  %25 = phi i32 [ %13, %11 ], [ %21, %16 ]    ; IR: %19 = phi i32 [ %12, %10 ], [ %27, %22 ]
  %26 = add nuw nsw i32 %12, 1    ; IR: %20 = add nuw nsw i32 %11, 1
  %27 = icmp eq i32 %26, %2    ; IR: %21 = icmp eq i32 %20, %2
  br i1 %27, label %28, label %11    ; IR: br i1 %21, label %15, label %10

28:
  %29 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %16 = phi i32 [ %19, %18 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %25, i32 %29)    ; IR: %16
  br label %30

30:
  %31 = phi i32 [ %12, %28 ], [ %45, %43 ]    ; IR: outer trip being undone, from the last down to 0
  %32 = phi i32 [ %25, %28 ], [ %44, %43 ]
  %33 = mul nsw i32 %31, %4    ; IR: %14 of that trip (classical)
  %34 = add nsw i32 %3, -1
  br i1 %14, label %35, label %43

35:
  %36 = phi i32 [ %34, %30 ], [ %41, %35 ]    ; IR: inner trip being undone, from m-1 down to 0
  %37 = phi i32 [ %32, %30 ], [ %40, %35 ]
  %38 = add nsw i32 %36, %33    ; IR: %25 of that trip (classical)
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  call void @cq_template_add_i32_unc(i32 %37, i32 %39, i32 %40)    ; IR: uncompute %27
  call void @cqrt_free(i32 %37)    ; IR: release the %27 rail (|0>)
  call void @cq_template_xor_i32_hl_unc(i32 %39, i32 %6, i32 %38)    ; IR: uncompute %26
  call void @cqrt_free(i32 %39)    ; IR: release the %26 rail (|0>)
  %41 = add nsw i32 %36, -1
  %42 = icmp sge i32 %41, 0
  br i1 %42, label %35, label %43

43:
  %44 = phi i32 [ %32, %30 ], [ %40, %35 ]
  %45 = add nsw i32 %31, -1
  %46 = icmp sge i32 %45, 0
  br i1 %46, label %30, label %47

47:
  call void @cqrt_free(i32 %44)    ; IR: release incoming 0 of phi %12 (never written, |0>)
  %48 = call i32 @cqrt_measure_i32(i32 %29)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %48    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_xor_i32_hl(i32, i32)
declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
