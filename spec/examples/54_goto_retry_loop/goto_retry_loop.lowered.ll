; HAND-WRITTEN. Rules: 14, 8, 7, 5, 2.
; Checked: y = x_K * c (the copied-out product of the carried x after K trips, %29, measured as %63).
; Clean: every trip rail except a_K: the path flags, products, the second compare, cont, the two candidate updates,
; the inner and carried selects, the chain predicates a_0..a_{K-1} (trips K..1 popped and uncomputed by the reverse
; loop; trip 0's test and a_0 uncomputed after it), and the |1> seed (%7) freed directly.
; Kept: x (%6, the rotated register); y (%29, measured); a_K (%27 of the K-th trip, %38 of the first reverse trip), the
; output rail of rule 14: the continue test evaluated after the K-th body, 1 iff the retry loop would run a (K+1)-th trip.
; Rotations: (Ry, x, th, 1).
; Both gotos reach the header through one latch block (%12) that merges the two continue paths, so this is one rolled
; K-bounded loop (as example 05) whose CONTINUE predicate is the disjunction of the two path conditions:
; cont = (x > k) | (x*c > m), one or_i1 into a fresh |0> flag (rule 8; the second goto's own path predicate
; !(x > k) & (x*c > m) is not materialised, the OR absorbs it). -O1 tests at the header with no pre-header guard, so the
; loop is re-rolled to body-then-test (rule 14): the FIRST header evaluation (x_0 > k, x_0 * c, x_0 * c > m, cont_0) is
; computed before the loop as trip 0 of the chain, a_0 = seed & cont_0 from the |1> seed; trip j (j = 1..K) runs the
; body under a_{j-1} (the latch value x' = p1 ? x-k : x>>1 on the path flag of the CURRENT x, selected into the carried
; x only where a_{j-1} = 1) and then the NEXT header evaluation on the new x, a_j = a_{j-1} & cont_j. The path flag and
; the product of each test are carried into the next trip (the body's inner select reads the flag; the product of the
; last test is y). K = 4 (the literal 4 below).
; Output rail (rule 14): after the K-th body the chain ends in cont_K, the test admitting trip K + 1; a_K = a_{K-1} &
; cont_K is kept allocated, neither uncomputed nor freed: a_K = 1 means the retry loop would still continue after K
; trips; a loop that exits after exactly K trips reads 0. y is the value of x*c at the exit: the carried x stops
; changing once the loop has exited, so y = x_K * c, the product of the K-th test, copied out (alloc + copy) and
; measured. The reverse loop pops trips K..1 and skips the predicate uncompute on its first iteration (reverse index 0)
; by a classical branch; trip 0's test and a_0 are uncomputed after it and the |1> seed is freed directly (rule 7).
source_filename = "goto_retry_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @goto_retry_loop(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching recompute the first time (always 1)
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %9 = icmp sgt i32 %8, %2 at recompute the first time: trip 0 of the chain  [path 1 predicate, block %10]
  %9 = call i32 @cq_template_mul_i32_hl(i32 %6, i32 %3)    ; IR: %15 = mul nsw i32 %8, %3  (block %14, pure, hoisted)
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %9, i32 %4)    ; IR: %16 = icmp sgt i32 %15, %4
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: block %12 is reached = path 1 OR path 2: cont = %9 | %16 (rule 8)
  call void @cqrt_or_i1(i32 %8, i32 %10, i32 %11)    ; IR: cont ^= %9 | %16
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_0 = predicate of the first back edge
  call void @cqrt_and_i1(i32 %7, i32 %11, i32 %12)    ; IR: br label %7 from %12 taken the first time
  br label %13

13:
  %14 = phi i32 [ 0, %5 ], [ %28, %13 ]    ; IR: trip index, bounded by K  [K]
  %15 = phi i32 [ %6, %5 ], [ %22, %13 ]    ; IR: %8 = phi i32 [ %6, %5 ], [ %13, %12 ]
  %16 = phi i32 [ %12, %5 ], [ %27, %13 ]    ; IR: a_{j-1}: predicate of this trip's body (the back edge that reaches it)
  %17 = phi i32 [ %8, %5 ], [ %23, %13 ]    ; IR: %9 of the current x (path 1 flag, computed by the previous test)
  %18 = phi i32 [ %9, %5 ], [ %24, %13 ]    ; IR: %15 of the current x (computed by the previous test)
  %19 = call i32 @cq_template_sub_i32_hl(i32 %15, i32 %2)    ; IR: %11 = sub nsw i32 %8, %2
  %20 = call i32 @cq_template_ashr_i32_hl(i32 %15, i32 1)    ; IR: %18 = ashr i32 %8, 1
  %21 = call i32 @cq_template_select_i32(i32 %17, i32 %19, i32 %20)    ; IR: %13 = phi i32 [ %11, %10 ], [ %18, %17 ]
  %22 = call i32 @cq_template_select_i32(i32 %16, i32 %21, i32 %15)    ; IR: next %8 = a ? %13 : %8
  %23 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %22, i32 %2)    ; IR: %9 = icmp sgt i32 %8, %2 at the next recompute: the test after this body
  %24 = call i32 @cq_template_mul_i32_hl(i32 %22, i32 %3)    ; IR: %15 = mul nsw i32 %8, %3 of the next header
  %25 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %24, i32 %4)    ; IR: %16 = icmp sgt i32 %15, %4
  %26 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: cont of the next header = %9 | %16 (rule 8)
  call void @cqrt_or_i1(i32 %23, i32 %25, i32 %26)    ; IR: cont ^= %9 | %16
  %27 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_j = predicate of the next back edge (after trip K: a_K, the output rail)
  call void @cqrt_and_i1(i32 %16, i32 %26, i32 %27)    ; IR: br label %7 from %12 taken once more
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %26)
  %28 = add nuw nsw i32 %14, 1
  %29 = icmp ult i32 %28, 4    ; IR: K-bounded br label %7  [K]
  br i1 %29, label %13, label %30

30:
  %31 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %15 = mul nsw i32 %8, %3 of the exiting trip  [copied-out result rail]
  call void @cqrt_copy_i32(i32 %24, i32 %31)    ; IR: %15: y = x_K * c, the product of the K-th test
  br label %32

32:
  %33 = phi i32 [ 0, %30 ], [ %50, %49 ]    ; IR: reverse trip index
  %34 = phi i32 [ %22, %30 ], [ %46, %49 ]    ; IR: %8 written by this trip
  %35 = phi i32 [ %27, %30 ], [ %45, %49 ]    ; IR: a_j, the predicate computed by this trip's test
  %36 = phi i32 [ %23, %30 ], [ %44, %49 ]    ; IR: %9 computed by this trip's test
  %37 = phi i32 [ %24, %30 ], [ %43, %49 ]    ; IR: %15 computed by this trip's test
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  %43 = call i32 @cqrt_pop()
  %44 = call i32 @cqrt_pop()
  %45 = call i32 @cqrt_pop()
  %46 = call i32 @cqrt_pop()
  %47 = icmp eq i32 %33, 0    ; IR: reverse index 0 is trip K: its a_j is a_K, the output rail (rule 14)
  br i1 %47, label %49, label %48

48:
  call void @cqrt_and_i1(i32 %45, i32 %38, i32 %35)    ; IR: uncompute a_j (trips 1..K-1)
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  br label %49

49:
  call void @cqrt_or_i1(i32 %36, i32 %39, i32 %38)    ; IR: uncompute cont of this trip's test
  call void @cqrt_free(i32 %38)    ; IR: release cont (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %39, i32 %37, i32 %4)    ; IR: uncompute %16
  call void @cqrt_free(i32 %39)    ; IR: release %16 (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %37, i32 %34, i32 %3)    ; IR: uncompute %15
  call void @cqrt_free(i32 %37)    ; IR: release %15 (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %36, i32 %34, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %36)    ; IR: release %9 (|0>)
  call void @cq_template_select_i32_unc(i32 %34, i32 %45, i32 %40, i32 %46)    ; IR: uncompute next %8
  call void @cqrt_free(i32 %34)    ; IR: release next %8 (|0>)
  call void @cq_template_select_i32_unc(i32 %40, i32 %44, i32 %42, i32 %41)    ; IR: uncompute %13
  call void @cqrt_free(i32 %40)    ; IR: release %13 (|0>)
  call void @cq_template_ashr_i32_hl_unc(i32 %41, i32 %46, i32 1)    ; IR: uncompute %18
  call void @cqrt_free(i32 %41)    ; IR: release %18 (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %42, i32 %46, i32 %2)    ; IR: uncompute %11
  call void @cqrt_free(i32 %42)    ; IR: release %11 (|0>)
  %50 = add nuw nsw i32 %33, 1
  %51 = icmp ult i32 %50, 4    ; IR: K  [K]
  br i1 %51, label %32, label %52

52:
  call void @cqrt_and_i1(i32 %7, i32 %11, i32 %12)    ; IR: uncompute a_0 (trip 0 of the chain)
  call void @cqrt_free(i32 %12)    ; IR: release a_0 (|0>)
  call void @cqrt_or_i1(i32 %8, i32 %10, i32 %11)    ; IR: uncompute cont of the first header
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %9, i32 %4)    ; IR: uncompute the first %16
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %9, i32 %6, i32 %3)    ; IR: uncompute the first %15
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %6, i32 %2)    ; IR: uncompute the first %9
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %7)    ; IR: release the |1> seed directly (rule 7: known basis state)
  %53 = call i32 @cqrt_measure_i32(i32 %31)    ; IR: %20 = cq_measure_si32(%15)
  ret i32 %53    ; IR: ret i32 %20
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_or_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
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
