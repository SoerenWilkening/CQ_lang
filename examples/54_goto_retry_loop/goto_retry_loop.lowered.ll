; HAND-WRITTEN. Rules: 14, 8, 7, 5, 2.
; Checked: y = x_K * c (%24, the product of the carried x after K trips, measured as %44).
; Clean: every trip rail except a_K: the path flags, cont, the two candidate updates, the inner and carried selects
; (popped and uncomputed by the reverse loop), the trip predicates 1..K-1, and the |1> seed (%7, popped as %36) freed
; directly, all freed.
; Kept: x (%6, the rotated register); y (%24, measured); the LAST trip predicate a_K (%18 of trip 3, %28 of the first
; reverse trip), an output rail by rule 14.
; Rotations: (Ry, x, th, 1).
; Both gotos reach the header through one latch block (%12) that merges the two continue paths, so this is one rolled
; K-bounded loop (as example 05) whose CONTINUE predicate is the disjunction of the two path conditions:
; cont = (x > k) | (x*c > m), one or_i1 into a fresh |0> flag (rule 8; the second goto's own path predicate
; !(x > k) & (x*c > m) is not materialised, the OR absorbs it). The latch value is x' = p1 ? x-k : x>>1, selected into
; the carried x only under the trip predicate a_j = a_{j-1} & cont_j, seeded |1>. y is the value of x*c at the exit: the
; carried x stops changing once the loop has exited, so after K trips y = x_K * c, computed once and measured. K = 4
; (the literal 4 below).
; Output rail (rule 14): a_K is kept allocated, neither uncomputed nor freed: a_K = 1 means the retry loop was still
; continuing after K trips. The predicates of trips 1..K-1 are uncomputed; the reverse loop skips the predicate
; uncompute on its first iteration (reverse index 0) by a classical branch. The |1> seed is freed directly (rule 7).
source_filename = "goto_retry_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @goto_retry_loop(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching recompute the first time (always 1)
  br label %8

8:
  %9 = phi i32 [ 0, %5 ], [ %21, %8 ]    ; IR: trip index, bounded by K  [K]
  %10 = phi i32 [ %6, %5 ], [ %20, %8 ]    ; IR: %8 = phi i32 [ %6, %5 ], [ %13, %12 ]
  %11 = phi i32 [ %7, %5 ], [ %18, %8 ]    ; IR: predicate of reaching this trip's header
  %12 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %10, i32 %2)    ; IR: %9 = icmp sgt i32 %8, %2  [path 1 predicate, block %10]
  %13 = call i32 @cq_template_sub_i32_hl(i32 %10, i32 %2)    ; IR: %11 = sub nsw i32 %8, %2
  %14 = call i32 @cq_template_mul_i32_hl(i32 %10, i32 %3)    ; IR: %15 = mul nsw i32 %8, %3  (block %14, pure, hoisted)
  %15 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %14, i32 %4)    ; IR: %16 = icmp sgt i32 %15, %4
  %16 = call i32 @cq_template_ashr_i32_hl(i32 %10, i32 1)    ; IR: %18 = ashr i32 %8, 1
  %17 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: block %12 is reached = path 1 OR path 2: cont = %9 | %16 (rule 8)
  call void @cqrt_or_i1(i32 %12, i32 %15, i32 %17)    ; IR: cont ^= %9 | %16
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip's back edge
  call void @cqrt_and_i1(i32 %11, i32 %17, i32 %18)    ; IR: br label %7 from %12 taken
  %19 = call i32 @cq_template_select_i32(i32 %12, i32 %13, i32 %16)    ; IR: %13 = phi i32 [ %11, %10 ], [ %18, %17 ]
  %20 = call i32 @cq_template_select_i32(i32 %18, i32 %19, i32 %10)    ; IR: next %8 = a ? %13 : %8
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %19)
  %21 = add nuw nsw i32 %9, 1
  %22 = icmp ult i32 %21, 4    ; IR: K-bounded br label %7  [K]
  br i1 %22, label %8, label %23

23:
  %24 = call i32 @cq_template_mul_i32_hl(i32 %20, i32 %3)    ; IR: %15 = mul nsw i32 %8, %3 of the exiting trip  [result rail]
  br label %25

25:
  %26 = phi i32 [ 0, %23 ], [ %41, %40 ]    ; IR: reverse trip index
  %27 = phi i32 [ %20, %23 ], [ %37, %40 ]    ; IR: %8 written by this trip
  %28 = phi i32 [ %18, %23 ], [ %36, %40 ]    ; IR: predicate of this trip
  %29 = call i32 @cqrt_pop()
  %30 = call i32 @cqrt_pop()
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %27, i32 %28, i32 %29, i32 %37)    ; IR: uncompute next %8
  call void @cqrt_free(i32 %27)    ; IR: release next %8 (|0>)
  call void @cq_template_select_i32_unc(i32 %29, i32 %35, i32 %34, i32 %31)    ; IR: uncompute %13
  call void @cqrt_free(i32 %29)    ; IR: release %13 (|0>)
  %38 = icmp eq i32 %26, 0    ; IR: reverse index 0 is trip K: its predicate a_K is the output rail (rule 14)
  br i1 %38, label %40, label %39

39:
  call void @cqrt_and_i1(i32 %36, i32 %30, i32 %28)    ; IR: uncompute the predicate of this trip (trips 1..K-1)
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  br label %40

40:
  call void @cqrt_or_i1(i32 %35, i32 %32, i32 %30)    ; IR: uncompute cont
  call void @cqrt_free(i32 %30)    ; IR: release cont (|0>)
  call void @cq_template_ashr_i32_hl_unc(i32 %31, i32 %37, i32 1)    ; IR: uncompute %18
  call void @cqrt_free(i32 %31)    ; IR: release %18 (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %32, i32 %33, i32 %4)    ; IR: uncompute %16
  call void @cqrt_free(i32 %32)    ; IR: release %16 (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %33, i32 %37, i32 %3)    ; IR: uncompute %15
  call void @cqrt_free(i32 %33)    ; IR: release %15 (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %34, i32 %37, i32 %2)    ; IR: uncompute %11
  call void @cqrt_free(i32 %34)    ; IR: release %11 (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %35, i32 %37, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %35)    ; IR: release %9 (|0>)
  %41 = add nuw nsw i32 %26, 1
  %42 = icmp ult i32 %41, 4    ; IR: K  [K]
  br i1 %42, label %25, label %43

43:
  call void @cqrt_free(i32 %36)    ; IR: release the |1> seed directly (rule 7: known basis state)
  %44 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %20 = cq_measure_si32(%15)
  ret i32 %44    ; IR: ret i32 %20
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_or_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_ashr_i32_hl(i32, i32)
declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
