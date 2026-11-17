; HAND-WRITTEN. Rules: 14 (quantum-dependent exit, cutoff K), 8, 9, 7, 5.
; Checked: i (measured).
; Clean: every trip rail, every trip predicate (the K-th included) and the after-trip-K return test; the |1> seed and
; the i seed are freed directly.
; Kept: a_K (%22: the return test x_K == k evaluated after the K-th body, negated and ANDed with trip K's predicate;
; rule 14: a_K = 1 iff the loop would run a (K+1)-th trip, i.e. the return was not taken within K trips nor at the
; test after them, which is observable; a loop whose return is taken at that test reads 0). The user register x stays
; allocated.
; Rotations: (Ry, x, tx, 1).
; `for (;;) { if (x == k) return cq_measure(i); ... }` is a loop whose only exit is the return, tested at the top of each
; trip (-O1: the pre-header `x == k` is trip 0's test, the latch `x/2 == k` the next trip's). It is re-rolled to K = 4 trips
; under the chain a_j = a_{j-1} & NOT(x_j == k): the exit flag is X-bracketed into the Toffoli (rule 8). The returned
; value is the carried i, which the selects on a_j freeze at the trip where the return was taken (rule 9), so the
; fall-through after K trips and every early return read the same copied-out rail. After the K-th trip the return test
; is evaluated once more on x_K and a_K = (predicate of trip K) & NOT(x_K == k) is kept (rule 14); the test is uncomputed
; at once. Each trip pushes its rails; the mirror pops and uncomputes LIFO, every trip predicate included.
source_filename = "return_in_kloop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @return_in_kloop(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %10 / %7  [i before trip 0]
  %6 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test in %3 (always 1)
  br label %7

7:
  %8 = phi i32 [ 0, %3 ], [ %18, %7 ]    ; IR: trip index, bounded by K  [K]
  %9 = phi i32 [ %4, %3 ], [ %16, %7 ]    ; IR: %11 = phi i32 [ %12, %9 ], [ %4, %3 ]
  %10 = phi i32 [ %5, %3 ], [ %17, %7 ]    ; IR: %10 = phi i32 [ %13, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %6, %3 ], [ %13, %7 ]    ; IR: predicate of reaching this trip's test
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 %2)    ; IR: %5 = icmp eq i32 %4, %2 (trip 0) / %14 = icmp eq i32 %12, %2  [the return flag]
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip's body (block %9)
  call void @cqrt_not_i1(i32 %12)    ; IR: bracket: the trip runs when the return is NOT taken
  call void @cqrt_and_i1(i32 %11, i32 %12, i32 %13)    ; IR: br i1 %5 / %14 not taken: a_j = a_{j-1} & NOT e
  call void @cqrt_not_i1(i32 %12)    ; IR: bracket
  %14 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 1)    ; IR: %12 = lshr i32 %11, 1
  %15 = call i32 @cq_template_add_i32_hl(i32 %10, i32 1)    ; IR: %13 = add nuw nsw i32 %10, 1
  %16 = call i32 @cq_template_select_i32(i32 %13, i32 %14, i32 %9)    ; IR: next %11 = a ? %12 : %11
  %17 = call i32 @cq_template_select_i32(i32 %13, i32 %15, i32 %10)    ; IR: next %10 / %7 = a ? %13 : %10  (frozen once the return was taken)
  call void @cqrt_push(i32 %9)
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  %18 = add nuw nsw i32 %8, 1
  %19 = icmp ult i32 %18, 4    ; IR: K-bounded br i1 %14, label %6, label %9  [K]
  br i1 %19, label %7, label %20

20:
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %16, i32 %2)    ; IR: %14 = icmp eq i32 %12, %2 after trip K: the return test that would decide a (K+1)-th trip
  %22 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K = predicate of trip K & NOT that test  [output rail, kept]
  call void @cqrt_not_i1(i32 %21)    ; IR: bracket
  call void @cqrt_and_i1(i32 %13, i32 %21, i32 %22)    ; IR: br i1 %14 not taken once more (rule 14)
  call void @cqrt_not_i1(i32 %21)    ; IR: bracket
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %21, i32 %16, i32 %2)    ; IR: uncompute that test
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  %23 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %7 = phi i32 [ 0, %3 ], [ %13, %9 ]  [copied-out result: the carried i]
  call void @cqrt_copy_i32(i32 %17, i32 %23)    ; IR: %7
  br label %24

24:
  %25 = phi i32 [ 0, %20 ], [ %35, %24 ]    ; IR: reverse trip index
  %26 = phi i32 [ %16, %20 ], [ %34, %24 ]    ; IR: %11 written by this trip
  %27 = phi i32 [ %17, %20 ], [ %33, %24 ]    ; IR: %10 written by this trip
  %28 = phi i32 [ %13, %20 ], [ %32, %24 ]    ; IR: predicate of this trip
  %29 = call i32 @cqrt_pop()
  %30 = call i32 @cqrt_pop()
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %27, i32 %28, i32 %29, i32 %33)    ; IR: uncompute next %10
  call void @cqrt_free(i32 %27)    ; IR: release next %10 (|0>)
  call void @cq_template_select_i32_unc(i32 %26, i32 %28, i32 %30, i32 %34)    ; IR: uncompute next %11
  call void @cqrt_free(i32 %26)    ; IR: release next %11 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %29, i32 %33, i32 1)    ; IR: uncompute %13
  call void @cqrt_free(i32 %29)    ; IR: release %13 (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %30, i32 %34, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %30)    ; IR: release %12 (|0>)
  call void @cqrt_not_i1(i32 %31)    ; IR: bracket
  call void @cqrt_and_i1(i32 %32, i32 %31, i32 %28)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)
  call void @cqrt_not_i1(i32 %31)    ; IR: bracket
  call void @cqrt_free(i32 %28)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %31, i32 %34, i32 %2)    ; IR: uncompute %5 / %14
  call void @cqrt_free(i32 %31)    ; IR: release %5 / %14 (|0>)
  %35 = add nuw nsw i32 %25, 1
  %36 = icmp ult i32 %35, 4    ; IR: K  [K]
  br i1 %36, label %24, label %37

37:
  call void @cqrt_free(i32 %32)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %33)    ; IR: release incoming 0 of phi %10 (never written, |0>)
  %38 = call i32 @cqrt_measure_i32(i32 %23)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %38    ; IR: ret i32 %8
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
