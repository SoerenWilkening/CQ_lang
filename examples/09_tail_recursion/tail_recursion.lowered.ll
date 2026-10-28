; HAND-WRITTEN. Rules: 18, 14, 5, 7, 2.
; Checked: count(x, 0, k, a, b) (measured: the clone's copied-out result rail %25, %7 -> %8 in the caller).
; Clean: every level rail (the compare flags of the first test and of every level's test, products, sums, next-value
; selects, the chain predicates a_0..a_{K-1}), popped and uncomputed by the clone's reverse loop (a_0 and its test after
; it); the |1> seed (%7, freed directly) and the first-level n rail (%6, never written, holds the classical 0).
; Kept: a_K (%21 of the K-th trip, the first predicate the reverse loop meets): the output rail of rule 14, the test
; admitting a (K+1)-th level, so a_K = 1 iff the recursion had not bottomed out after K levels; and x (%6 in the caller,
; the rotated user register).
; Rotations: (Ry, x, th, 1).
; clang -O1 turned the tail recursion into a loop inside count that tests at its header (x > k, then the recursive
; step); the clone __cq_q_count_10000 (mask left to right, §1.4) is the rolled K-bounded predicated loop of example 05
; (K = 4; the literal 4 is K), re-rolled to body-then-test (rule 14): the FIRST header test x_0 > k is computed before
; the loop as trip 0 of the predicate chain, a_0 = seed & (x_0 > k) from the |1> seed; trip j (j = 1..K) runs the
; recursive step under a_{j-1} (x = x * a + b, n = n + 1, each carried value advanced by a select on a_{j-1}) and then
; the NEXT header test on the new x, a_j = a_{j-1} & (x_j > k). After the K-th body the chain ends in the test admitting
; trip K + 1: that rail is a_K, kept allocated, neither uncomputed nor freed. The clone returns the copied-out result
; rail; the caller measures it.
; Output rail (rule 14): a_K = 1 iff the loop would run another trip; a recursion that bottoms out after exactly K
; levels reads 0. a_0..a_{K-1} are uncomputed: the reverse loop pops trip K..1 and skips the predicate uncompute on its
; first iteration (reverse index 0 = trip K) by a classical branch; a_0 and the first test are uncomputed after it.
; x * a + b wraps: no range bound B, the cutoff is K. Basis check (a = 1, b = 0xFFFFFFFF, k = 2): x0 = 5 runs 3 levels
; (5, 4, 3 > 2; the test after the third body reads 2 > 2 = 0), a_K = 0; x0 = 6 runs exactly K = 4 levels (6, 5, 4, 3 > 2)
; and the test after the fourth body reads 2 > 2 = 0, so a_K = 0; x0 = 7 passes that test (3 > 2) and a_K = 1.
source_filename = "tail_recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @tail_recursion(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call fastcc i32 @__cq_q_count_10000(i32 %6, i32 0, i32 %2, i32 %3, i32 %4)    ; IR: %7 = call @count(%6, 0, %2, %3, %4), quantum clone of count (arg 0 quantum)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

define internal fastcc i32 @__cq_q_count_10000(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: incoming %1 of phi %8  [n at the first level]
  %7 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test in %6 (always 1)
  %8 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %0, i32 %2)    ; IR: %9 = icmp ugt i32 %7, %2 at the first level: trip 0 of the chain, before the loop
  %9 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_0 = predicate of block %10 at the first level
  call void @cqrt_and_i1(i32 %7, i32 %8, i32 %9)    ; IR: br i1 %9, label %10 taken at the first level
  br label %10

10:
  %11 = phi i32 [ 0, %5 ], [ %22, %10 ]    ; IR: recursion level, bounded by K  [K]
  %12 = phi i32 [ %0, %5 ], [ %17, %10 ]    ; IR: %7 = phi i32 [ %0, %5 ], [ %12, %10 ]
  %13 = phi i32 [ %6, %5 ], [ %19, %10 ]    ; IR: %8 = phi i32 [ %1, %5 ], [ %13, %10 ]
  %14 = phi i32 [ %9, %5 ], [ %21, %10 ]    ; IR: a_{j-1}: predicate of this level's recursive step
  %15 = call i32 @cq_template_mul_i32_hl(i32 %12, i32 %3)    ; IR: %11 = mul i32 %3, %7
  %16 = call i32 @cq_template_add_i32_hl(i32 %15, i32 %4)    ; IR: %12 = add i32 %11, %4
  %17 = call i32 @cq_template_select_i32(i32 %14, i32 %16, i32 %12)    ; IR: next %7 = a ? %12 : %7
  %18 = call i32 @cq_template_add_i32_hl(i32 %13, i32 1)    ; IR: %13 = add nsw i32 %8, 1
  %19 = call i32 @cq_template_select_i32(i32 %14, i32 %18, i32 %13)    ; IR: next %8 = a ? %13 : %8
  %20 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %17, i32 %2)    ; IR: %9 = icmp ugt i32 %7, %2 at the next level: the test after this body
  %21 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_j = predicate of block %10 at the next level (after trip K: a_K, the output rail)
  call void @cqrt_and_i1(i32 %14, i32 %20, i32 %21)    ; IR: br i1 %9, label %10 taken at the next level
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %20)
  %22 = add nuw nsw i32 %11, 1
  %23 = icmp ult i32 %22, 4    ; IR: K-bounded br i1 %9, label %10, label %14  [K]
  br i1 %23, label %10, label %24

24:
  %25 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %8  [copied-out result]
  call void @cqrt_copy_i32(i32 %19, i32 %25)    ; IR: ret i32 %8
  br label %26

26:
  %27 = phi i32 [ 0, %24 ], [ %41, %40 ]    ; IR: reverse level index
  %28 = phi i32 [ %17, %24 ], [ %37, %40 ]    ; IR: %7 written by this level
  %29 = phi i32 [ %19, %24 ], [ %36, %40 ]    ; IR: %8 written by this level
  %30 = phi i32 [ %21, %24 ], [ %35, %40 ]    ; IR: a_j, the predicate computed by this level's test
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = icmp eq i32 %27, 0    ; IR: reverse index 0 is trip K: its a_j is a_K, the output rail (rule 14)
  br i1 %38, label %40, label %39
39:
  call void @cqrt_and_i1(i32 %35, i32 %31, i32 %30)    ; IR: uncompute a_j (trips 1..K-1)
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  br label %40
40:
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %31, i32 %28, i32 %2)    ; IR: uncompute %9 (the test after this body)
  call void @cqrt_free(i32 %31)    ; IR: release %9 (|0>)
  call void @cq_template_select_i32_unc(i32 %29, i32 %35, i32 %32, i32 %36)    ; IR: uncompute next %8
  call void @cqrt_free(i32 %29)    ; IR: release next %8 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %32, i32 %36, i32 1)    ; IR: uncompute %13
  call void @cqrt_free(i32 %32)    ; IR: release %13 (|0>)
  call void @cq_template_select_i32_unc(i32 %28, i32 %35, i32 %33, i32 %37)    ; IR: uncompute next %7
  call void @cqrt_free(i32 %28)    ; IR: release next %7 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %33, i32 %34, i32 %4)    ; IR: uncompute %12
  call void @cqrt_free(i32 %33)    ; IR: release %12 (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %34, i32 %37, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %34)    ; IR: release %11 (|0>)
  %41 = add nuw nsw i32 %27, 1
  %42 = icmp ult i32 %41, 4    ; IR: K  [K]
  br i1 %42, label %26, label %43

43:
  call void @cqrt_and_i1(i32 %7, i32 %8, i32 %9)    ; IR: uncompute a_0 (trip 0 of the chain)
  call void @cqrt_free(i32 %9)    ; IR: release a_0 (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %8, i32 %0, i32 %2)    ; IR: uncompute the first test %9
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %7)    ; IR: release the |1> seed directly (rule 7: a known basis state is freed as is)
  call void @cqrt_free(i32 %6)    ; IR: release the first-level n rail (never written, holds the classical %1)
  ret i32 %25    ; IR: ret i32 %8
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
