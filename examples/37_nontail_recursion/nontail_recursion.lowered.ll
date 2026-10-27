; HAND-WRITTEN. Rules: 18, 14, 5, 7.
; Checked: sumdown(x, k, a) (the clone's result rail %6, measured as %7).
; Clean: every level rail except a[K]; the |1> seed (%5 of the clone, popped as %30) and the accumulator seed |0> are freed
; directly (rule 7).
; Kept: x (%5 of the caller, the rotated register); the result rail %6 (measured); the last level predicate a[K] (%12 of
; level 3), an output rail by rule 14.
; Rotations: (Ry, x, th, 1).
; clang -O1 turned x + sumdown(x / a) into an accumulator loop (the recursion is not tail-recursive in the source), so
; the clone __cq_q_sumdown_100 (mask left to right, §1.4) is the rolled K-bounded predicated loop of example 09 (K = 4;
; the literal 4 is K): level j runs under a[j] = a[j-1] & (x[j] > k); after K levels the exit block adds the final
; accumulator and x once (their values no longer change once the predicate is 0).
; Output rail (rule 14): the LAST level predicate a[K] is kept allocated, neither uncomputed nor freed, as in 09; the
; reverse loop skips the predicate uncompute on its first iteration (reverse index 0 = level K).
; As in 09 the loop tests at its header, so a[K] = a[K-1] & (x[K] > k) is the test admitting a (K+1)-th level (an
; exact-K bottom-out reads 0, a deeper one 1); x / a has no LLVM range bound (a may be 1), so the cutoff is K.
source_filename = "nontail_recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nontail_recursion(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_sumdown_100(i32 %5, i32 %2, i32 %3)    ; IR: %6 = call @sumdown(%5, %2, %3), quantum clone (arg 0 quantum)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

define internal fastcc i32 @__cq_q_sumdown_100(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %5  [accumulator before level 0]
  %5 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test (always 1)
  br label %6

6:
  %7 = phi i32 [ 0, %3 ], [ %17, %6 ]    ; IR: recursion level, bounded by K  [K]
  %8 = phi i32 [ %0, %3 ], [ %14, %6 ]    ; IR: %6 = phi i32 [ %0, %3 ], [ %9, %8 ]
  %9 = phi i32 [ %4, %3 ], [ %16, %6 ]    ; IR: %5 = phi i32 [ 0, %3 ], [ %10, %8 ]
  %10 = phi i32 [ %5, %3 ], [ %12, %6 ]    ; IR: predicate of reaching this level's test
  %11 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %8, i32 %1)    ; IR: %7 = icmp ugt i32 %6, %1
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %8 at this level
  call void @cqrt_and_i1(i32 %10, i32 %11, i32 %12)    ; IR: br i1 %7, label %8 taken
  %13 = call i32 @cq_template_udiv_i32_hl(i32 %8, i32 %2)    ; IR: %9 = udiv i32 %6, %2
  %14 = call i32 @cq_template_select_i32(i32 %12, i32 %13, i32 %8)    ; IR: next %6 = a ? %9 : %6
  %15 = call i32 @cq_template_add_i32(i32 %9, i32 %8)    ; IR: %10 = add i32 %5, %6
  %16 = call i32 @cq_template_select_i32(i32 %12, i32 %15, i32 %9)    ; IR: next %5 = a ? %10 : %5
  call void @cqrt_push(i32 %8)
  call void @cqrt_push(i32 %9)
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %15)
  %17 = add nuw nsw i32 %7, 1
  %18 = icmp ult i32 %17, 4    ; IR: K-bounded br i1 %7, label %8, label %11  [K]
  br i1 %18, label %6, label %19

19:
  %20 = call i32 @cq_template_add_i32(i32 %16, i32 %14)    ; IR: %12 = add i32 %5, %6  (block %11, on the final values)
  %21 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %12  [result rail of the call]
  call void @cqrt_copy_i32(i32 %20, i32 %21)    ; IR: copy the result out
  call void @cq_template_add_i32_unc(i32 %20, i32 %16, i32 %14)    ; IR: uncompute %12
  call void @cqrt_free(i32 %20)    ; IR: release the %12 rail (|0>)
  br label %22

22:
  %23 = phi i32 [ 0, %19 ], [ %36, %35 ]    ; IR: reverse level index
  %24 = phi i32 [ %14, %19 ], [ %32, %35 ]    ; IR: %6 written by this level
  %25 = phi i32 [ %16, %19 ], [ %31, %35 ]    ; IR: %5 written by this level
  %26 = phi i32 [ %12, %19 ], [ %30, %35 ]    ; IR: predicate of this level
  %27 = call i32 @cqrt_pop()
  %28 = call i32 @cqrt_pop()
  %29 = call i32 @cqrt_pop()
  %30 = call i32 @cqrt_pop()
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %25, i32 %26, i32 %27, i32 %31)    ; IR: uncompute next %5
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_add_i32_unc(i32 %27, i32 %31, i32 %32)    ; IR: uncompute %10
  call void @cqrt_free(i32 %27)    ; IR: release the %10 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %24, i32 %26, i32 %28, i32 %32)    ; IR: uncompute next %6
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_udiv_i32_hl_unc(i32 %28, i32 %32, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %28)    ; IR: release the %9 rail (|0>)
  %33 = icmp eq i32 %23, 0    ; IR: reverse index 0 is level K: its predicate a[K] is the output rail (rule 14)
  br i1 %33, label %35, label %34
34:
  call void @cqrt_and_i1(i32 %30, i32 %29, i32 %26)    ; IR: uncompute the level predicate (levels 1..K-1)
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  br label %35
35:
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %29, i32 %32, i32 %1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %29)    ; IR: release the %7 rail (|0>)
  %36 = add nuw nsw i32 %23, 1
  %37 = icmp ult i32 %36, 4    ; IR: K  [K]
  br i1 %37, label %22, label %38

38:
  call void @cqrt_free(i32 %30)    ; IR: release the |1> seed directly (rule 7: a known basis state is freed as is)
  call void @cqrt_free(i32 %31)    ; IR: release incoming 0 of phi %5 (never written, |0>)
  ret i32 %21    ; IR: ret i32 %12
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_udiv_i32_hl(i32, i32)
declare void @cq_template_udiv_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
