; HAND-WRITTEN. Rules: 14 (nested quantum-dependent exits, cutoff K, chain seeded by the arm flag), 9, 8, 7, 5.
; Checked: s (measured).
; Clean: every trip rail of both loops and every trip predicate, the K-th of each chain included; the after-trip-K exit
; tests (uncomputed right after their output rail is formed); the else-arm value, the arm flag and the s seed are freed.
; Kept: (rule 14) A_K (%40: the outer exit test x_K > k evaluated after outer trip K, ANDed with that trip's
; predicate) and, per outer trip, B_K (%33: the inner exit test z_K > k evaluated after inner trip K, ANDed with that
; trip's predicate; minted in the outer latch, never pushed): 5 output rails in all. A_K = 1 iff the outer loop would run
; a (K+1)-th trip; a B_K = 1 iff that outer trip's inner loop would; a loop that exits after exactly K trips reads 0.
; The user registers x and y stay allocated.
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1).
; Two nested K-loops inside the then-arm of `if (x > c)`. The arm flag F = (x > c) SEEDS the outer chain (rule 14: a loop
; in an arm takes the arm flag instead of |1>): A_i = A_{i-1} & (x_i > k) with A_{-1} = F, so where the arm is not taken
; nothing in the loops changes. Each outer trip's inner chain is seeded by that trip's predicate: B_j = B_{j-1} & (z_j > k)
; with B_{-1} = A_i (-O1's hoisted guard %13 is inner trip 0's test); z_0 is the user register y. Every carried value (s, z,
; x) advances by a select on its chain's predicate (rule 9). The arm itself merges by one select on F between the loops'
; final s (the seed 0 where no trip ran, covering the [0, %10] incoming) and the else-arm value x + y, computed unguarded;
; the merge is a fresh result rail, so nothing is copied out. The mirror is 139's nested reverse: pop the outer trip's
; rails, run the inner reverse (every inner predicate uncomputed), uncompute the outer predicate and its compare.
; F is uncomputed last, after the chain it seeded has been torn down.
source_filename = "nested_kloops_in_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nested_kloops_in_arm(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_ui32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %8 = cq_theta_ui32(%2, %3)  [Ry]
  %9 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %7, i32 %5)    ; IR: %9 = icmp ugt i32 %7, %5  [arm flag; seeds the outer chain]
  %10 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %15 (and the [ 0, %10 ] incoming of %30)  [s before any trip]
  br label %11

11:
  %12 = phi i32 [ 0, %6 ], [ %36, %31 ]    ; IR: outer trip index, bounded by K  [K]
  %13 = phi i32 [ %7, %6 ], [ %35, %31 ]    ; IR: %16 = phi i32 [ %7, %12 ], [ %25, %23 ]
  %14 = phi i32 [ %10, %6 ], [ %27, %31 ]    ; IR: %15 = phi i32 [ 0, %12 ], [ %24, %23 ]
  %15 = phi i32 [ %9, %6 ], [ %17, %31 ]    ; IR: predicate of reaching this outer trip's test (the arm flag for trip 0)
  %16 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %13, i32 %4)    ; IR: %11 = icmp ugt i32 %7, %4 (trip 0) / %26 = icmp ugt i32 %25, %4
  %17 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this outer trip (block %14)
  call void @cqrt_and_i1(i32 %15, i32 %16, i32 %17)    ; IR: br i1 %11 / %26 taken: A_i = A_{i-1} & ocond
  br label %18

18:
  %19 = phi i32 [ 0, %11 ], [ %29, %18 ]    ; IR: inner trip index, bounded by K  [K]
  %20 = phi i32 [ %8, %11 ], [ %28, %18 ]    ; IR: %18 = phi i32 [ %21, %17 ], [ %8, %14 ]  (z = y at the inner entry)
  %21 = phi i32 [ %14, %11 ], [ %27, %18 ]    ; IR: %19 = phi i32 [ %20, %17 ], [ %15, %14 ]
  %22 = phi i32 [ %17, %11 ], [ %24, %18 ]    ; IR: predicate of reaching this inner trip's test (the outer trip predicate for inner trip 0)
  %23 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %20, i32 %4)    ; IR: %13 = icmp ugt i32 %8, %4 (hoisted inner trip 0) / %22 = icmp ugt i32 %21, %4
  %24 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this inner trip (block %17)
  call void @cqrt_and_i1(i32 %22, i32 %23, i32 %24)    ; IR: br i1 %13 / %22 taken: B_j = B_{j-1} & icond
  %25 = call i32 @cq_template_add_i32(i32 %20, i32 %21)    ; IR: %20 = add i32 %18, %19
  %26 = call i32 @cq_template_lshr_i32_hl(i32 %20, i32 1)    ; IR: %21 = lshr i32 %18, 1
  %27 = call i32 @cq_template_select_i32(i32 %24, i32 %25, i32 %21)    ; IR: next %19 / %24 = B ? %20 : %19
  %28 = call i32 @cq_template_select_i32(i32 %24, i32 %26, i32 %20)    ; IR: next %18 = B ? %21 : %18
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %26)
  %29 = add nuw nsw i32 %19, 1
  %30 = icmp ult i32 %29, 4    ; IR: K-bounded br i1 %22, label %17, label %23  [K]
  br i1 %30, label %18, label %31

31:
  %32 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %28, i32 %4)    ; IR: %22 = icmp ugt i32 %21, %4 after inner trip K: the exit test that would admit a (K+1)-th inner trip
  %33 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: B_K of this outer trip = predicate of inner trip K & that test  [output rail, kept]
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)    ; IR: br i1 %22 taken once more (rule 14)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %32, i32 %28, i32 %4)    ; IR: uncompute that test
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cqrt_push(i32 %24)    ; IR: the predicate of inner trip K (popped for the mirror's phi, uncomputed there)
  call void @cqrt_push(i32 %28)    ; IR: the inner loop's final z (the mirror's first inner phi)
  %34 = call i32 @cq_template_add_i32_hl(i32 %13, i32 -1)    ; IR: %25 = add i32 %16, -1
  %35 = call i32 @cq_template_select_i32(i32 %17, i32 %34, i32 %13)    ; IR: next %16 = A ? %25 : %16
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %34)
  %36 = add nuw nsw i32 %12, 1
  %37 = icmp ult i32 %36, 4    ; IR: K-bounded br i1 %26, label %14, label %29  [K]
  br i1 %37, label %11, label %38

38:
  %39 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %35, i32 %4)    ; IR: %26 = icmp ugt i32 %25, %4 after outer trip K: the exit test that would admit a (K+1)-th outer trip
  %40 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: A_K = predicate of outer trip K & that test  [output rail, kept]
  call void @cqrt_and_i1(i32 %17, i32 %39, i32 %40)    ; IR: br i1 %26 taken once more (rule 14)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %39, i32 %35, i32 %4)    ; IR: uncompute that test
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  %41 = call i32 @cq_template_add_i32(i32 %8, i32 %7)    ; IR: %28 = add i32 %8, %7  (else arm, block %27, pure: computed unguarded)
  %42 = call i32 @cq_template_select_i32(i32 %9, i32 %27, i32 %41)    ; IR: %30 = phi i32 [ %28, %27 ], [ 0, %10 ], [ %24, %23 ]  [result rail: F selects the loops' final s]
  call void @cq_template_add_i32_unc(i32 %41, i32 %8, i32 %7)    ; IR: uncompute %28
  call void @cqrt_free(i32 %41)    ; IR: release the %28 rail (|0>)
  br label %43

43:
  %44 = phi i32 [ 0, %38 ], [ %68, %67 ]    ; IR: outer reverse trip index
  %45 = phi i32 [ %35, %38 ], [ %51, %67 ]    ; IR: %16 written by this outer trip
  %46 = phi i32 [ %17, %38 ], [ %50, %67 ]    ; IR: predicate of this outer trip
  %47 = phi i32 [ %27, %38 ], [ %63, %67 ]    ; IR: s at the end of this outer trip (its inner loop's final %19)
  %48 = call i32 @cqrt_pop()
  %49 = call i32 @cqrt_pop()
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()    ; IR: the predicate of this outer trip's inner trip K (uncomputed by the inner reverse loop)
  call void @cq_template_select_i32_unc(i32 %45, i32 %46, i32 %48, i32 %51)    ; IR: uncompute next %16
  call void @cqrt_free(i32 %45)    ; IR: release next %16 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %48, i32 %51, i32 -1)    ; IR: uncompute %25
  call void @cqrt_free(i32 %48)    ; IR: release %25 (|0>)
  br label %54

54:
  %55 = phi i32 [ 0, %43 ], [ %65, %54 ]    ; IR: inner reverse trip index
  %56 = phi i32 [ %52, %43 ], [ %64, %54 ]    ; IR: %18 written by this inner trip
  %57 = phi i32 [ %47, %43 ], [ %63, %54 ]    ; IR: %19 written by this inner trip
  %58 = phi i32 [ %53, %43 ], [ %62, %54 ]    ; IR: predicate of this inner trip
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  %61 = call i32 @cqrt_pop()
  %62 = call i32 @cqrt_pop()
  %63 = call i32 @cqrt_pop()
  %64 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %56, i32 %58, i32 %59, i32 %64)    ; IR: uncompute next %18
  call void @cqrt_free(i32 %56)    ; IR: release next %18 (|0>)
  call void @cq_template_select_i32_unc(i32 %57, i32 %58, i32 %60, i32 %63)    ; IR: uncompute next %19
  call void @cqrt_free(i32 %57)    ; IR: release next %19 (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %59, i32 %64, i32 1)    ; IR: uncompute %21
  call void @cqrt_free(i32 %59)    ; IR: release %21 (|0>)
  call void @cq_template_add_i32_unc(i32 %60, i32 %64, i32 %63)    ; IR: uncompute %20
  call void @cqrt_free(i32 %60)    ; IR: release %20 (|0>)
  call void @cqrt_and_i1(i32 %62, i32 %61, i32 %58)    ; IR: uncompute the predicate of this inner trip (every inner trip 1..K; B_K is a separate rail)
  call void @cqrt_free(i32 %58)    ; IR: release it (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %61, i32 %64, i32 %4)    ; IR: uncompute %13 / %22
  call void @cqrt_free(i32 %61)    ; IR: release it (|0>)
  %65 = add nuw nsw i32 %55, 1
  %66 = icmp ult i32 %65, 4    ; IR: K  [K]
  br i1 %66, label %54, label %67

67:
  call void @cqrt_and_i1(i32 %50, i32 %49, i32 %46)    ; IR: uncompute the predicate of this outer trip (every outer trip 1..K; A_K is a separate rail)
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %49, i32 %51, i32 %4)    ; IR: uncompute %11 / %26
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  %68 = add nuw nsw i32 %44, 1
  %69 = icmp ult i32 %68, 4    ; IR: K  [K]
  br i1 %69, label %43, label %70

70:
  call void @cqrt_free(i32 %63)    ; IR: release incoming 0 of phi %15 directly (rule 7: never written, |0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %9, i32 %7, i32 %5)    ; IR: uncompute %9 (the arm flag, after the chain it seeded is gone)
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %71 = call i32 @cqrt_measure_i32(i32 %42)    ; IR: %31 = cq_measure_ui32(%30)
  ret i32 %71    ; IR: ret i32 %31
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
