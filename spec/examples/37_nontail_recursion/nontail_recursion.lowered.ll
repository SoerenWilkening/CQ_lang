; HAND-WRITTEN. Rules: 18, 14, 5, 7.
; Checked: sumdown(x, k, a) (the clone's result rail %6, measured as %7).
; Clean: every level rail except a_K: the first test and a_0 (uncomputed after the reverse loop), each level's quotient,
; sum, next-value selects, test and chain predicate a_1..a_{K-1} (popped and uncomputed by the reverse loop), the exit
; block's final sum (uncomputed at once after the copy-out); the |1> seed (%5 of the clone) and the accumulator seed |0>
; (%4) are freed directly (rule 7).
; Kept: x (%5 of the caller, the rotated register); the result rail %6 (measured); a_K (%18 of the K-th trip), the
; output rail of rule 14: the test admitting a (K+1)-th level, 1 iff the recursion had not bottomed out after K levels.
; Rotations: (Ry, x, th, 1).
; clang -O1 turned x + sumdown(x / a) into an accumulator loop (the recursion is not tail-recursive in the source) that
; tests at its header, so the clone __cq_q_sumdown_100 (mask left to right, §1.4) is the rolled K-bounded predicated
; loop of example 09 (K = 4; the literal 4 is K), re-rolled to body-then-test (rule 14): the FIRST header test x_0 > k is
; computed before the loop as trip 0 of the chain, a_0 = seed & (x_0 > k); trip j (j = 1..K) runs the recursive step
; under a_{j-1} (x = x / a, acc = acc + x, each carried value advanced by a select on a_{j-1}) and then the NEXT header
; test on the new x, a_j = a_{j-1} & (x_j > k). After K levels the exit block adds the final accumulator and x once
; (their values no longer change once the predicate is 0).
; Output rail (rule 14): a_K, the chain's last rail (the test after the K-th body), is kept allocated, neither uncomputed
; nor freed, as in 09: an exact-K bottom-out reads 0, a deeper recursion 1. The reverse loop pops trips K..1 and skips the
; predicate uncompute on its first iteration (reverse index 0 = trip K); a_0 and the first test are uncomputed after it.
; x / a has no LLVM range bound (a may be 1), so the cutoff is K.
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
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %5  [accumulator before the first level]
  %5 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test (always 1)
  %6 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %0, i32 %1)    ; IR: %7 = icmp ugt i32 %6, %1 at the first level: trip 0 of the chain, before the loop
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_0 = predicate of block %8 at the first level
  call void @cqrt_and_i1(i32 %5, i32 %6, i32 %7)    ; IR: br i1 %7, label %8 taken at the first level
  br label %8

8:
  %9 = phi i32 [ 0, %3 ], [ %19, %8 ]    ; IR: recursion level, bounded by K  [K]
  %10 = phi i32 [ %0, %3 ], [ %14, %8 ]    ; IR: %6 = phi i32 [ %0, %3 ], [ %9, %8 ]
  %11 = phi i32 [ %4, %3 ], [ %16, %8 ]    ; IR: %5 = phi i32 [ 0, %3 ], [ %10, %8 ]
  %12 = phi i32 [ %7, %3 ], [ %18, %8 ]    ; IR: a_{j-1}: predicate of this level's recursive step
  %13 = call i32 @cq_template_udiv_i32_hl(i32 %10, i32 %2)    ; IR: %9 = udiv i32 %6, %2
  %14 = call i32 @cq_template_select_i32(i32 %12, i32 %13, i32 %10)    ; IR: next %6 = a ? %9 : %6
  %15 = call i32 @cq_template_add_i32(i32 %11, i32 %10)    ; IR: %10 = add i32 %5, %6
  %16 = call i32 @cq_template_select_i32(i32 %12, i32 %15, i32 %11)    ; IR: next %5 = a ? %10 : %5
  %17 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %14, i32 %1)    ; IR: %7 = icmp ugt i32 %6, %1 at the next level: the test after this body
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_j = predicate of block %8 at the next level (after trip K: a_K, the output rail)
  call void @cqrt_and_i1(i32 %12, i32 %17, i32 %18)    ; IR: br i1 %7, label %8 taken at the next level
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %17)
  %19 = add nuw nsw i32 %9, 1
  %20 = icmp ult i32 %19, 4    ; IR: K-bounded br i1 %7, label %8, label %11  [K]
  br i1 %20, label %8, label %21

21:
  %22 = call i32 @cq_template_add_i32(i32 %16, i32 %14)    ; IR: %12 = add i32 %5, %6  (block %11, on the final values)
  %23 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %12  [result rail of the call]
  call void @cqrt_copy_i32(i32 %22, i32 %23)    ; IR: copy the result out
  call void @cq_template_add_i32_unc(i32 %22, i32 %16, i32 %14)    ; IR: uncompute %12
  call void @cqrt_free(i32 %22)    ; IR: release the %12 rail (|0>)
  br label %24

24:
  %25 = phi i32 [ 0, %21 ], [ %38, %37 ]    ; IR: reverse level index
  %26 = phi i32 [ %14, %21 ], [ %34, %37 ]    ; IR: %6 written by this level
  %27 = phi i32 [ %16, %21 ], [ %33, %37 ]    ; IR: %5 written by this level
  %28 = phi i32 [ %18, %21 ], [ %32, %37 ]    ; IR: a_j, the predicate computed by this level's test
  %29 = call i32 @cqrt_pop()
  %30 = call i32 @cqrt_pop()
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = icmp eq i32 %25, 0    ; IR: reverse index 0 is trip K: its a_j is a_K, the output rail (rule 14)
  br i1 %35, label %37, label %36
36:
  call void @cqrt_and_i1(i32 %32, i32 %29, i32 %28)    ; IR: uncompute a_j (trips 1..K-1)
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  br label %37
37:
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %29, i32 %26, i32 %1)    ; IR: uncompute %7 (the test after this body)
  call void @cqrt_free(i32 %29)    ; IR: release the %7 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %27, i32 %32, i32 %30, i32 %33)    ; IR: uncompute next %5
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_add_i32_unc(i32 %30, i32 %33, i32 %34)    ; IR: uncompute %10
  call void @cqrt_free(i32 %30)    ; IR: release the %10 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %26, i32 %32, i32 %31, i32 %34)    ; IR: uncompute next %6
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cq_template_udiv_i32_hl_unc(i32 %31, i32 %34, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %31)    ; IR: release the %9 rail (|0>)
  %38 = add nuw nsw i32 %25, 1
  %39 = icmp ult i32 %38, 4    ; IR: K  [K]
  br i1 %39, label %24, label %40

40:
  call void @cqrt_and_i1(i32 %5, i32 %6, i32 %7)    ; IR: uncompute a_0 (trip 0 of the chain)
  call void @cqrt_free(i32 %7)    ; IR: release a_0 (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %6, i32 %0, i32 %1)    ; IR: uncompute the first test %7
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the |1> seed directly (rule 7: a known basis state is freed as is)
  call void @cqrt_free(i32 %4)    ; IR: release incoming 0 of phi %5 (never written, |0>)
  ret i32 %23    ; IR: ret i32 %12
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
