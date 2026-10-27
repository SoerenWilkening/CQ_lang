; HAND-WRITTEN. Rules: 18, 14, 5, 7, 2.
; Checked: count(x, 0, k, a, b) (measured: the clone's copied-out result rail %23, %7 -> %8 in the caller).
; Clean: every level rail (compare flags, products, sums, next-value selects, the level predicates a[1]..a[K-1]),
; popped and uncomputed by the clone's reverse loop; the |1> seed (%7, freed directly) and the first-level n rail (%6,
; never written, holds the classical 0).
; Kept: the last level predicate a[K] (%14 of level K, the first predicate the reverse loop meets): an output rail,
; since a[K] = 1 records that the recursion had not bottomed out after K levels; and x (%6 in the caller, the rotated
; user register).
; Rotations: (Ry, x, th, 1).
; clang -O1 turned the tail recursion into a loop inside count; the clone
; __cq_q_count_10000 (mask left to right, §1.4) is the rolled K-bounded predicated loop of example 05 (K = 4; the literal
; 4 is K): level j of the recursion runs under a[j] = a[j-1] & (x[j] > k), seeded with |1>. The clone returns the
; copied-out result rail; the caller measures it.
; Output rail (rule 14): the LAST level predicate a[K] (%14 of level 3, the predicate the reverse loop meets first) is
; kept allocated, neither uncomputed nor freed: a[K] = 1 means the recursion had not bottomed out after K levels, which
; is observable. a[1]..a[K-1] are uncomputed; the reverse loop skips the predicate uncompute on its first iteration
; (reverse index 0 = level K) by a classical branch.
; After-K check (rule 14): -O1's loop tests at its header (no pre-header guard; a level is the test x > k followed by
; the recursive step), so level K's predicate a[K] = a[K-1] & (x[K] > k) is exactly the test that admits a (K+1)-th
; level, not the predicate of level K's own test (that is a[K-1], uncomputed). x * a + b wraps: no range bound B, the
; cutoff is K. Basis check (a = 1, b = 0xFFFFFFFF, k = 2): x0 = 5 tests 5, 4, 3 > 2, then 2 > 2 = 0 at level 4, so the
; recursion bottoms out at exactly K levels and a[K] = 0; x0 = 6 passes all four tests and a[K] = 1.
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
  br label %8

8:
  %9 = phi i32 [ 0, %5 ], [ %20, %8 ]    ; IR: recursion level, bounded by K  [K]
  %10 = phi i32 [ %0, %5 ], [ %17, %8 ]    ; IR: %7 = phi i32 [ %0, %5 ], [ %12, %10 ]
  %11 = phi i32 [ %6, %5 ], [ %19, %8 ]    ; IR: %8 = phi i32 [ %1, %5 ], [ %13, %10 ]
  %12 = phi i32 [ %7, %5 ], [ %14, %8 ]    ; IR: predicate of reaching this level's test
  %13 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %10, i32 %2)    ; IR: %9 = icmp ugt i32 %7, %2
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %10 at this level
  call void @cqrt_and_i1(i32 %12, i32 %13, i32 %14)    ; IR: br i1 %9, label %10 taken
  %15 = call i32 @cq_template_mul_i32_hl(i32 %10, i32 %3)    ; IR: %11 = mul i32 %3, %7
  %16 = call i32 @cq_template_add_i32_hl(i32 %15, i32 %4)    ; IR: %12 = add i32 %11, %4
  %17 = call i32 @cq_template_select_i32(i32 %14, i32 %16, i32 %10)    ; IR: next %7 = a ? %12 : %7
  %18 = call i32 @cq_template_add_i32_hl(i32 %11, i32 1)    ; IR: %13 = add nsw i32 %8, 1
  %19 = call i32 @cq_template_select_i32(i32 %14, i32 %18, i32 %11)    ; IR: next %8 = a ? %13 : %8
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %18)
  %20 = add nuw nsw i32 %9, 1
  %21 = icmp ult i32 %20, 4    ; IR: K-bounded br i1 %9, label %10, label %14  [K]
  br i1 %21, label %8, label %22

22:
  %23 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %8  [copied-out result]
  call void @cqrt_copy_i32(i32 %19, i32 %23)    ; IR: ret i32 %8
  br label %24

24:
  %25 = phi i32 [ 0, %22 ], [ %39, %38 ]    ; IR: reverse level index
  %26 = phi i32 [ %17, %22 ], [ %35, %38 ]    ; IR: %7 written by this level
  %27 = phi i32 [ %19, %22 ], [ %34, %38 ]    ; IR: %8 written by this level
  %28 = phi i32 [ %14, %22 ], [ %33, %38 ]    ; IR: predicate of this level
  %29 = call i32 @cqrt_pop()
  %30 = call i32 @cqrt_pop()
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %27, i32 %28, i32 %29, i32 %34)    ; IR: uncompute next %8
  call void @cqrt_free(i32 %27)    ; IR: release next %8 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %29, i32 %34, i32 1)    ; IR: uncompute %13
  call void @cqrt_free(i32 %29)    ; IR: release %13 (|0>)
  call void @cq_template_select_i32_unc(i32 %26, i32 %28, i32 %30, i32 %35)    ; IR: uncompute next %7
  call void @cqrt_free(i32 %26)    ; IR: release next %7 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %30, i32 %31, i32 %4)    ; IR: uncompute %12
  call void @cqrt_free(i32 %30)    ; IR: release %12 (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %31, i32 %35, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %31)    ; IR: release %11 (|0>)
  %36 = icmp eq i32 %25, 0    ; IR: reverse index 0 is level K: its predicate a[K] is the output rail (rule 14)
  br i1 %36, label %38, label %37
37:
  call void @cqrt_and_i1(i32 %33, i32 %32, i32 %28)    ; IR: uncompute the predicate of this level (levels 1..K-1)
  call void @cqrt_free(i32 %28)    ; IR: release the predicate (|0>)
  br label %38
38:
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %32, i32 %35, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %32)    ; IR: release %9 (|0>)
  %39 = add nuw nsw i32 %25, 1
  %40 = icmp ult i32 %39, 4    ; IR: K  [K]
  br i1 %40, label %24, label %41

41:
  call void @cqrt_free(i32 %33)    ; IR: release the |1> seed directly (rule 7: a known basis state is freed as is)
  call void @cqrt_free(i32 %34)    ; IR: release the first-level n rail (never written, holds the classical %1)
  ret i32 %23    ; IR: ret i32 %8
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
