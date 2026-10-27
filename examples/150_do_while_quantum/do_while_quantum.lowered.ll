; HAND-WRITTEN. Rules: 14 (quantum-dependent exit, cutoff K), 9, 7, 5.
; Checked: x + n (measured).
; Clean: every trip rail except a_K; the |1> seed and the n seed are freed directly.
; Kept: a_K, the predicate computed by the last trip's test (the first rail popped by the reverse loop; rule 14: a_K
; = 1 means a fifth body would have run, which is observable). The user register x stays allocated.
; Rotations: (Ry, x, tx, 1).
; A do-while: the body runs before the test, so trip 0's body is unconditional (its predicate is the |1> seed) and the
; test at the END of trip j produces the predicate of trip j+1: a_{j+1} = a_j & (x_{j+1} > k), on the CARRIED value
; (where the loop has already exited the carried x is frozen and a_j = 0 absorbs the test). The loop is re-rolled to K = 4
; bodies and K tests; both carried values advance by a select on a_j (rule 9). Each trip pushes its rails; both results
; are copied out (alloc + copy) and a reverse loop pops and uncomputes every trip LIFO, skipping a_K on its first
; iteration.
source_filename = "do_while_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @do_while_quantum(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %9  [n before trip 0]
  %8 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of trip 0's body (a do-while body runs unconditionally once)
  br label %9

9:
  %10 = phi i32 [ 0, %5 ], [ %21, %9 ]    ; IR: trip index, bounded by K  [K]
  %11 = phi i32 [ %6, %5 ], [ %17, %9 ]    ; IR: %8 = phi i32 [ %6, %5 ], [ %11, %7 ]
  %12 = phi i32 [ %7, %5 ], [ %18, %9 ]    ; IR: %9 = phi i32 [ 0, %5 ], [ %12, %7 ]
  %13 = phi i32 [ %8, %5 ], [ %20, %9 ]    ; IR: predicate of this trip's body
  %14 = call i32 @cq_template_mul_i32_hl(i32 %11, i32 %2)    ; IR: %10 = mul nsw i32 %8, %2
  %15 = call i32 @cq_template_add_i32_hl(i32 %14, i32 %3)    ; IR: %11 = add nsw i32 %10, %3
  %16 = call i32 @cq_template_add_i32_hl(i32 %12, i32 1)    ; IR: %12 = add nuw nsw i32 %9, 1
  %17 = call i32 @cq_template_select_i32(i32 %13, i32 %15, i32 %11)    ; IR: next %8 = a ? %11 : %8
  %18 = call i32 @cq_template_select_i32(i32 %13, i32 %16, i32 %12)    ; IR: next %9 = a ? %12 : %9
  %19 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %17, i32 %4)    ; IR: %13 = icmp sgt i32 %11, %4  (on the carried x)
  %20 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the next trip's body
  call void @cqrt_and_i1(i32 %13, i32 %19, i32 %20)    ; IR: br i1 %13 taken: a_{j+1} = a_j & cond
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %19)
  %21 = add nuw nsw i32 %10, 1
  %22 = icmp ult i32 %21, 4    ; IR: K-bounded br i1 %13, label %7, label %14  [K]
  br i1 %22, label %9, label %23

23:
  %24 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %15 = cq_measure_si32(%11): the carried x  [copied-out result]
  call void @cqrt_copy_i32(i32 %17, i32 %24)    ; IR: %11 of the last trip
  %25 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %16 = cq_measure_si32(%12): the carried n  [copied-out result]
  call void @cqrt_copy_i32(i32 %18, i32 %25)    ; IR: %12 of the last trip
  br label %26

26:
  %27 = phi i32 [ 0, %23 ], [ %41, %40 ]    ; IR: reverse trip index
  %28 = phi i32 [ %17, %23 ], [ %37, %40 ]    ; IR: %8 written by this trip
  %29 = phi i32 [ %18, %23 ], [ %36, %40 ]    ; IR: %9 written by this trip
  %30 = phi i32 [ %20, %23 ], [ %35, %40 ]    ; IR: predicate produced by this trip's test
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = icmp eq i32 %27, 0    ; IR: reverse index 0 is trip K-1: the predicate its test produced is a_K, the output rail (rule 14)
  br i1 %38, label %40, label %39

39:
  call void @cqrt_and_i1(i32 %35, i32 %31, i32 %30)    ; IR: uncompute the predicate produced by this trip (trips 0..K-2)
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  br label %40

40:
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %31, i32 %28, i32 %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %31)    ; IR: release %13 (|0>)
  call void @cq_template_select_i32_unc(i32 %29, i32 %35, i32 %32, i32 %36)    ; IR: uncompute next %9
  call void @cqrt_free(i32 %29)    ; IR: release next %9 (|0>)
  call void @cq_template_select_i32_unc(i32 %28, i32 %35, i32 %33, i32 %37)    ; IR: uncompute next %8
  call void @cqrt_free(i32 %28)    ; IR: release next %8 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %32, i32 %36, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %32)    ; IR: release %12 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %33, i32 %34, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %33)    ; IR: release %11 (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %34, i32 %37, i32 %2)    ; IR: uncompute %10
  call void @cqrt_free(i32 %34)    ; IR: release %10 (|0>)
  %41 = add nuw nsw i32 %27, 1
  %42 = icmp ult i32 %41, 4    ; IR: K  [K]
  br i1 %42, label %26, label %43

43:
  call void @cqrt_free(i32 %35)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %36)    ; IR: release incoming 0 of phi %9 (never written, |0>)
  %44 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %15 = cq_measure_si32(%11)
  %45 = call i32 @cqrt_measure_i32(i32 %25)    ; IR: %16 = cq_measure_si32(%12)
  %46 = add nsw i32 %45, %44    ; IR: %17 = add nsw i32 %16, %15  (classical)
  ret i32 %46    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
