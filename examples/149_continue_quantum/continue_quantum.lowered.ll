; HAND-WRITTEN. Rules: 14 (classical bound; quantum-dependent exit with cutoff K), 9, 8, 7, 5.
; Checked: continue_classical_bound: acc + x (measured); continue_kloop: s + x (measured).
; Clean: every trip rail of both loops, every trip predicate of continue_kloop (the K-th included) and its
; after-trip-K exit test; both seeds are freed directly.
; Kept: continue_kloop's a_K (%26: the exit test x_K > k evaluated after the K-th body, ANDed with trip K's predicate;
; rule 14: a_K = 1 iff the loop would run a (K+1)-th trip, which is observable; a loop that exits after exactly K trips
; reads 0). continue_classical_bound keeps nothing. The user register x stays allocated in both.
; Rotations: (Ry, x, tx, 1) in each function.
; continue_classical_bound: the bound is classical, so the loop stays a classical loop with no predicate chain (131). -O1
; folds the quantum `continue` into `select e, acc, acc*c + i`: the skip flag e = (x == i + k) is a flag rail per trip and
; the carried acc advances by one select (rule 9: the skipped arm is the old acc itself). Each trip pushes its rails;
; after the result is copied out a reverse loop pops and uncomputes every trip LIFO; the acc seed is freed directly (7).
; continue_kloop: the exit depends on x, so the loop is re-rolled to K = 4 trips under the chain a_j = a_{j-1} & (x_j > k)
; (the pre-header guard is trip 0's test). -O1 folds the `continue` into a select too, so the skip never reaches the
; chain: it is the all-literal select (c or 0) added to s; both carried values advance by a select on a_j. The exit value
; of x is the carried x_K: -O1's phi spells it as the literal k (SCEV: an unsigned x decremented by 1 from above k leaves
; the loop exactly at k), which the carried rail equals on every branch where the loop has exited (a_K = 0). Both results
; are copied out (alloc + copy) before the mirror; the user register x stays allocated. After the K-th trip the exit
; test is evaluated once more on x_K and a_K = (predicate of trip K) & (x_K > k) is kept (rule 14); the test is uncomputed at once and
; the mirror uncomputes every trip predicate, the K-th included.
source_filename = "continue_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @continue_classical_bound(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %15 / %9  [acc before trip 0]
  %8 = icmp sgt i32 %2, 0    ; IR: %7 = icmp sgt i32 %2, 0  (classical)
  br i1 %8, label %13, label %9    ; IR: br i1 %7, label %13, label %8

9:
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %10 = cq_measure_si32(%9), %9 = 0 from %5
  %11 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_si32(%6)
  %12 = add nsw i32 %11, %10    ; IR: %12 = add nsw i32 %11, %10  (classical)
  ret i32 %12    ; IR: ret i32 %12

13:
  %14 = phi i32 [ 0, %5 ], [ %21, %13 ]    ; IR: %14 = phi i32 [ %21, %13 ], [ 0, %5 ]  (classical)
  %15 = phi i32 [ %7, %5 ], [ %20, %13 ]    ; IR: %15 = phi i32 [ %20, %13 ], [ 0, %5 ]  [carried acc]
  %16 = add nsw i32 %14, %3    ; IR: %16 = add nsw i32 %14, %3  (classical)
  %17 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 %16)    ; IR: %17 = icmp eq i32 %6, %16  [the continue flag]
  %18 = call i32 @cq_template_mul_i32_hl(i32 %15, i32 %4)    ; IR: %18 = mul nsw i32 %15, %4
  %19 = call i32 @cq_template_add_i32_hl(i32 %18, i32 %14)    ; IR: %19 = add nsw i32 %18, %14
  %20 = call i32 @cq_template_select_i32(i32 %17, i32 %15, i32 %19)    ; IR: %20 = select i1 %17, i32 %15, i32 %19  [next acc: the continue keeps the old acc]
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %19)
  %21 = add nuw nsw i32 %14, 1    ; IR: %21 = add nuw nsw i32 %14, 1  (classical)
  %22 = icmp eq i32 %21, %2    ; IR: %22 = icmp eq i32 %21, %2  (classical)
  br i1 %22, label %23, label %13    ; IR: br i1 %22, label %8, label %13

23:
  %24 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %9 = phi i32 [ %20, %13 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %20, i32 %24)    ; IR: %9
  br label %25

25:
  %26 = phi i32 [ %14, %23 ], [ %33, %25 ]    ; IR: trip being undone, from the last down to 0 (its classical i)
  %27 = phi i32 [ %20, %23 ], [ %31, %25 ]    ; IR: %20 of this trip
  %28 = call i32 @cqrt_pop()
  %29 = call i32 @cqrt_pop()
  %30 = call i32 @cqrt_pop()
  %31 = call i32 @cqrt_pop()
  %32 = add nsw i32 %26, %3    ; IR: %16 of that trip (classical)
  call void @cq_template_select_i32_unc(i32 %27, i32 %30, i32 %31, i32 %28)    ; IR: uncompute %20
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %28, i32 %29, i32 %26)    ; IR: uncompute %19
  call void @cqrt_free(i32 %28)    ; IR: release the %19 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %29, i32 %31, i32 %4)    ; IR: uncompute %18
  call void @cqrt_free(i32 %29)    ; IR: release the %18 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %30, i32 %6, i32 %32)    ; IR: uncompute %17
  call void @cqrt_free(i32 %30)    ; IR: release the %17 rail (|0>)
  %33 = add nsw i32 %26, -1
  %34 = icmp sge i32 %33, 0    ; IR: trips n-1 down to 0
  br i1 %34, label %25, label %35

35:
  call void @cqrt_free(i32 %31)    ; IR: release incoming 0 of phi %15 directly (rule 7: never written, |0>)
  %36 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %10 = cq_measure_si32(%9)
  %37 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_si32(%6)
  %38 = add nsw i32 %37, %36    ; IR: %12 = add nsw i32 %11, %10  (classical)
  ret i32 %38    ; IR: ret i32 %12
}

define i32 @continue_kloop(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %8 / %18  [s before trip 0]
  %7 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the loop guard in %4 (always 1)
  br label %8

8:
  %9 = phi i32 [ 0, %4 ], [ %22, %8 ]    ; IR: trip index, bounded by K  [K]
  %10 = phi i32 [ %5, %4 ], [ %20, %8 ]    ; IR: %9 = phi i32 [ %10, %7 ], [ %5, %4 ]
  %11 = phi i32 [ %6, %4 ], [ %21, %8 ]    ; IR: %8 = phi i32 [ %14, %7 ], [ 0, %4 ]
  %12 = phi i32 [ %7, %4 ], [ %14, %8 ]    ; IR: predicate of reaching this trip's test
  %13 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %10, i32 %2)    ; IR: %6 = icmp ugt i32 %5, %2 (trip 0) / %15 = icmp ugt i32 %10, %2
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip
  call void @cqrt_and_i1(i32 %12, i32 %13, i32 %14)    ; IR: br i1 %6 (trip 0) / br i1 %15 taken: a_j = a_{j-1} & cond_j
  %15 = call i32 @cq_template_add_i32_hl(i32 %10, i32 -1)    ; IR: %10 = add i32 %9, -1
  %16 = call i32 @cq_template_and_i32_hl(i32 %15, i32 1)    ; IR: %11 = and i32 %10, 1
  %17 = call i32 @cq_template_icmp_eq_i32_hl(i32 %16, i32 0)    ; IR: %12 = icmp eq i32 %11, 0  [the continue, folded by -O1 into the select below]
  %18 = call i32 @cq_template_select_i32_ll(i32 %17, i32 %3, i32 0)    ; IR: %13 = select i1 %12, i32 %3, i32 0  (both arms classical: _ll)
  %19 = call i32 @cq_template_add_i32(i32 %18, i32 %11)    ; IR: %14 = add i32 %13, %8
  %20 = call i32 @cq_template_select_i32(i32 %14, i32 %15, i32 %10)    ; IR: next %9 = a ? %10 : %9
  %21 = call i32 @cq_template_select_i32(i32 %14, i32 %19, i32 %11)    ; IR: next %8 / %18 = a ? %14 : %8
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %19)
  %22 = add nuw nsw i32 %9, 1
  %23 = icmp ult i32 %22, 4    ; IR: K-bounded br i1 %15, label %7, label %16  [K]
  br i1 %23, label %8, label %24

24:
  %25 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %20, i32 %2)    ; IR: %15 = icmp ugt i32 %10, %2 after trip K: the exit test that would admit a (K+1)-th trip
  %26 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K = predicate of trip K & that test  [output rail, kept]
  call void @cqrt_and_i1(i32 %14, i32 %25, i32 %26)    ; IR: br i1 %15 taken once more (rule 14)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %25, i32 %20, i32 %2)    ; IR: uncompute that test
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  %27 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %18 = phi i32 [ 0, %4 ], [ %14, %7 ]  [copied-out s]
  call void @cqrt_copy_i32(i32 %21, i32 %27)    ; IR: %18
  %28 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %17 = phi i32 [ %5, %4 ], [ %2, %7 ]  [copied-out x: the carried x_K, which is the literal k wherever the loop has exited]
  call void @cqrt_copy_i32(i32 %20, i32 %28)    ; IR: %17
  br label %29

29:
  %30 = phi i32 [ 0, %24 ], [ %43, %29 ]    ; IR: reverse trip index
  %31 = phi i32 [ %20, %24 ], [ %42, %29 ]    ; IR: %9 written by this trip
  %32 = phi i32 [ %21, %24 ], [ %41, %29 ]    ; IR: %8 written by this trip
  %33 = phi i32 [ %14, %24 ], [ %40, %29 ]    ; IR: predicate of this trip
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %32, i32 %33, i32 %34, i32 %41)    ; IR: uncompute next %8
  call void @cqrt_free(i32 %32)    ; IR: release next %8 (|0>)
  call void @cq_template_select_i32_unc(i32 %31, i32 %33, i32 %38, i32 %42)    ; IR: uncompute next %9
  call void @cqrt_free(i32 %31)    ; IR: release next %9 (|0>)
  call void @cq_template_add_i32_unc(i32 %34, i32 %35, i32 %41)    ; IR: uncompute %14
  call void @cqrt_free(i32 %34)    ; IR: release %14 (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %35, i32 %36, i32 %3, i32 0)    ; IR: uncompute %13
  call void @cqrt_free(i32 %35)    ; IR: release %13 (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %36, i32 %37, i32 0)    ; IR: uncompute %12
  call void @cqrt_free(i32 %36)    ; IR: release %12 (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %37, i32 %38, i32 1)    ; IR: uncompute %11
  call void @cqrt_free(i32 %37)    ; IR: release %11 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %38, i32 %42, i32 -1)    ; IR: uncompute %10
  call void @cqrt_free(i32 %38)    ; IR: release %10 (|0>)
  call void @cqrt_and_i1(i32 %40, i32 %39, i32 %33)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)
  call void @cqrt_free(i32 %33)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %39, i32 %42, i32 %2)    ; IR: uncompute %6 / %15
  call void @cqrt_free(i32 %39)    ; IR: release %6 / %15 (|0>)
  %43 = add nuw nsw i32 %30, 1
  %44 = icmp ult i32 %43, 4    ; IR: K  [K]
  br i1 %44, label %29, label %45

45:
  call void @cqrt_free(i32 %40)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %41)    ; IR: release incoming 0 of phi %8 (never written, |0>)
  %46 = call i32 @cqrt_measure_i32(i32 %27)    ; IR: %19 = cq_measure_ui32(%18)
  %47 = call i32 @cqrt_measure_i32(i32 %28)    ; IR: %20 = cq_measure_ui32(%17)
  %48 = add i32 %47, %46    ; IR: %21 = add i32 %20, %19  (classical)
  ret i32 %48    ; IR: ret i32 %21
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
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
