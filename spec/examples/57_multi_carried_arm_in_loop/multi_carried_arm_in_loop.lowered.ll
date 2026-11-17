; HAND-WRITTEN. Rules: 14 (classical bound, quantum body), 9, 7, 4, 5.
; Checked: q (measured): the copied-out result %30 (-> %49) after the last trip, or the never-written |0> seed %7 (-> %10)
; when the loop runs zero trips.
; Clean: every trip rail (t, the flag t > ix, t + r, the three next values and the two select intermediates; %16..%24 of
; each trip, popped as %33..%41 in the reverse loop) and the two |0> seed rails for s and q (%6, %7 / %42, %43), all freed.
; Kept: ix (%5, the rotated register) and the copied-out q (%30, measured).
; Rotations: (Ry, ix, th, 1).
; The bound n is classical, so the loop stays a classical loop with no predicate chain (example 25): there is no trip
; predicate and hence no a_K output rail, the arm flag t > ix of each trip is uncomputed. -O1 already turned the arm into
; selects on that quantum flag. Three quantum values (ix, s, q) are carried; each trip computes its next values into
; fresh rails and pushes the old ones, the result q is copied out after the last trip and a reverse loop pops and
; uncomputes every trip. The classical carried r (r >>= 1) is needed by the reverse trip and cannot be recovered from the
; next r, so the forward trip pushes it on the same stack (a classical value on the handle stack). Where the loop never
; runs, q is the classical 0 rail itself. The two |0> seed rails (s, q before trip 0) are freed directly (rule 7).
source_filename = "multi_carried_arm_in_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @multi_carried_arm_in_loop(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register ix]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %15  [s before trip 0]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %14 / %8  [q before trip 0]
  %8 = icmp sgt i32 %3, 0    ; IR: %6 = icmp sgt i32 %3, 0  (classical)
  br i1 %8, label %11, label %9    ; IR: br i1 %6, label %10, label %7

9:
  call void @cqrt_free(i32 %6)    ; IR: s never written (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %9 = cq_measure_si32(%8), %8 = 0 from %4  (the classical-valued rail is the result)
  ret i32 %10    ; IR: ret i32 %9

11:
  %12 = phi i32 [ 0, %4 ], [ %27, %11 ]    ; IR: %12 = phi i32 [ %26, %10 ], [ 0, %4 ]  (classical)
  %13 = phi i32 [ %2, %4 ], [ %26, %11 ]    ; IR: %13 = phi i32 [ %25, %10 ], [ %2, %4 ]  (classical)
  %14 = phi i32 [ %5, %4 ], [ %25, %11 ]    ; IR: %11 = phi i32 [ %24, %10 ], [ %5, %4 ]
  %15 = phi i32 [ %6, %4 ], [ %20, %11 ]    ; IR: %15 = phi i32 [ %19, %10 ], [ 0, %4 ]
  %16 = phi i32 [ %7, %4 ], [ %22, %11 ]    ; IR: %14 = phi i32 [ %21, %10 ], [ 0, %4 ]
  %17 = call i32 @cq_template_add_i32_hl(i32 %15, i32 %13)    ; IR: %16 = add nsw i32 %13, %15  (commutative: classical operand moved to the _hl slot)
  %18 = call i32 @cq_template_icmp_sgt_i32(i32 %17, i32 %14)    ; IR: %17 = icmp sgt i32 %16, %11
  %19 = call i32 @cq_template_add_i32_hl(i32 %17, i32 %13)    ; IR: %18 = add nsw i32 %16, %13
  %20 = call i32 @cq_template_select_i32(i32 %18, i32 %15, i32 %19)    ; IR: %19 = select i1 %17, i32 %15, i32 %18
  %21 = call i32 @cq_template_select_i32_ll(i32 %18, i32 0, i32 %13)    ; IR: %20 = select i1 %17, i32 0, i32 %13  (both data operands classical)
  %22 = call i32 @cq_template_add_i32(i32 %21, i32 %16)    ; IR: %21 = add nsw i32 %20, %14
  %23 = call i32 @cq_template_select_i32_lh(i32 %18, i32 0, i32 %17)    ; IR: %22 = select i1 %17, i32 0, i32 %16
  %24 = call i32 @cq_template_sub_i32(i32 %14, i32 %23)    ; IR: %23 = sub nsw i32 %11, %22
  %25 = call i32 @cq_template_shl_i32_hl(i32 %24, i32 1)    ; IR: %24 = shl nsw i32 %23, 1
  call void @cqrt_push(i32 %13)    ; IR: the classical r of this trip, for the reverse trip
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  %26 = ashr i32 %13, 1    ; IR: %25 = ashr i32 %13, 1  (classical)
  %27 = add nuw nsw i32 %12, 1    ; IR: %26 = add nuw nsw i32 %12, 1  (classical)
  %28 = icmp eq i32 %27, %3    ; IR: %27 = icmp eq i32 %26, %3  (classical)
  br i1 %28, label %29, label %11    ; IR: br i1 %27, label %7, label %10

29:
  %30 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %8 = phi i32 [ %21, %10 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %22, i32 %30)    ; IR: %8
  br label %31

31:
  %32 = phi i32 [ %12, %29 ], [ %46, %31 ]    ; IR: trip being undone, from the last down to 0
  %33 = phi i32 [ %25, %29 ], [ %44, %31 ]    ; IR: %24 of this trip
  %34 = phi i32 [ %20, %29 ], [ %43, %31 ]    ; IR: %19 of this trip
  %35 = phi i32 [ %22, %29 ], [ %42, %31 ]    ; IR: %21 of this trip
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()    ; IR: the classical r of this trip
  call void @cq_template_shl_i32_hl_unc(i32 %33, i32 %36, i32 1)    ; IR: uncompute %24
  call void @cqrt_free(i32 %33)    ; IR: release %24 (|0>)
  call void @cq_template_sub_i32_unc(i32 %36, i32 %44, i32 %37)    ; IR: uncompute %23
  call void @cqrt_free(i32 %36)    ; IR: release %23 (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %37, i32 %40, i32 0, i32 %41)    ; IR: uncompute %22
  call void @cqrt_free(i32 %37)    ; IR: release %22 (|0>)
  call void @cq_template_add_i32_unc(i32 %35, i32 %38, i32 %42)    ; IR: uncompute %21
  call void @cqrt_free(i32 %35)    ; IR: release %21 (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %38, i32 %40, i32 0, i32 %45)    ; IR: uncompute %20
  call void @cqrt_free(i32 %38)    ; IR: release %20 (|0>)
  call void @cq_template_select_i32_unc(i32 %34, i32 %40, i32 %43, i32 %39)    ; IR: uncompute %19
  call void @cqrt_free(i32 %34)    ; IR: release %19 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %39, i32 %41, i32 %45)    ; IR: uncompute %18
  call void @cqrt_free(i32 %39)    ; IR: release %18 (|0>)
  call void @cq_template_icmp_sgt_i32_unc(i32 %40, i32 %41, i32 %44)    ; IR: uncompute %17
  call void @cqrt_free(i32 %40)    ; IR: release %17 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %41, i32 %43, i32 %45)    ; IR: uncompute %16
  call void @cqrt_free(i32 %41)    ; IR: release %16 (|0>)
  %46 = add nsw i32 %32, -1
  %47 = icmp sgt i32 %46, -1    ; IR: trips n-1 down to 0
  br i1 %47, label %31, label %48

48:
  call void @cqrt_free(i32 %43)    ; IR: release the s rail before trip 0 (never written, |0>)
  call void @cqrt_free(i32 %42)    ; IR: release the q rail before trip 0 (never written, |0>)
  %49 = call i32 @cqrt_measure_i32(i32 %30)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %49    ; IR: ret i32 %9
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32(i32, i32)
declare void @cq_template_icmp_sgt_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
