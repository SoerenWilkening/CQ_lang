; HAND-WRITTEN. Rules: 14, 7, 4, 5, 2.
; Checked: n (measured, the copied-out carried rail %26 -> %42).
; Clean: every trip rail (the compare flags, the products, sums, the next-value selects and every trip predicate
; a_0..a_{K-1}, the K-th body's included), popped and uncomputed by the reverse loop; the after-trip-K exit test (%24,
; uncomputed at once); the |1> seed (%8, freed directly) and the |0> incoming of the n phi (%7, never written).
; Kept: a_K (%25: the exit test x_K > k evaluated after the K-th body, ANDed with the predicate of trip K; rule 14:
; a_K = 1 iff the loop would run a (K+1)-th trip, observable non-convergence; a loop that exits after exactly K trips
; reads 0); x (%6, the rotated user register, loop-carried through the selects); n (%26, measured). x * a + b wraps,
; so LLVM knows no bound on the trip count and the cutoff is K.
; Rotations: (Ry, x, th, 1).
; Re-rolled (rule 14): -O1's pre-header guard x > k (%7) is the latch test %14 one trip earlier (SCEV: both test the
; carried x), so it is trip 0 of the loop. Iteration j of the rolled loop evaluates the test on the carried x, forms
; a_j = a_{j-1} & (x_j > k) from the |1> seed, and runs the body (x = x * a + b, n++) under a_j: the select merges
; advance each carried value only where a_j = 1. The loop is cut off after K bodies (K = 4; the literal 4 below is K).
; After the K-th body the exit test is evaluated once more on the final x and a_K = a_{K-1} & (x_K > k) is kept as the
; output rail; that test is uncomputed at once. Each trip pushes its handles on the runtime handle stack; after n is
; copied out, a reverse loop pops them and uncomputes every trip, every trip predicate included (the K-th body's
; predicate is not a_K). The |1> seed is freed directly (rule 7).
; Basis check (a = 1, b = 0xFFFFFFFF, i.e. x = x - 1; k = 2): x0 = 6 tests 6, 5, 4, 3 > 2 (four bodies, n = 4) and the
; test after the K-th body reads 2 > 2 = 0, so a_K = 0 (exact-K exit); x0 = 7 tests 7, 6, 5, 4 and then 3 > 2 = 1, so
; a_K = 1 (the loop would run a fifth trip). In both cases trip K's own predicate a_{K-1} is 1 and is uncomputed.
source_filename = "while_quantum_cond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @while_quantum_cond(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %9 / %16
  %8 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the loop guard in %5 (always 1)
  br label %9

9:
  %10 = phi i32 [ 0, %5 ], [ %21, %9 ]    ; IR: trip index, bounded by K  [K]
  %11 = phi i32 [ %6, %5 ], [ %18, %9 ]    ; IR: %10 = phi i32 [ %12, %8 ], [ %6, %5 ]
  %12 = phi i32 [ %7, %5 ], [ %20, %9 ]    ; IR: %9 = phi i32 [ %13, %8 ], [ 0, %5 ]
  %13 = phi i32 [ %8, %5 ], [ %15, %9 ]    ; IR: predicate of reaching this trip's test
  %14 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %11, i32 %2)    ; IR: %7 = icmp ugt i32 %6, %2 (trip 0) / %14 = icmp ugt i32 %12, %2
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip
  call void @cqrt_and_i1(i32 %13, i32 %14, i32 %15)    ; IR: br i1 %7 (trip 0) / br i1 %14 taken
  %16 = call i32 @cq_template_mul_i32_hl(i32 %11, i32 %3)    ; IR: %11 = mul i32 %10, %3
  %17 = call i32 @cq_template_add_i32_hl(i32 %16, i32 %4)    ; IR: %12 = add i32 %11, %4
  %18 = call i32 @cq_template_select_i32(i32 %15, i32 %17, i32 %11)    ; IR: next %10 = a ? %12 : %10
  %19 = call i32 @cq_template_add_i32_hl(i32 %12, i32 1)    ; IR: %13 = add nuw nsw i32 %9, 1
  %20 = call i32 @cq_template_select_i32(i32 %15, i32 %19, i32 %12)    ; IR: next %9 / %16 = a ? %13 : %9
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %19)
  %21 = add nuw nsw i32 %10, 1
  %22 = icmp ult i32 %21, 4    ; IR: K-bounded br i1 %14, label %8, label %15  [K]
  br i1 %22, label %9, label %23

23:
  %24 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %18, i32 %2)    ; IR: %14 = icmp ugt i32 %12, %2 after trip K: the exit test that would admit a (K+1)-th trip
  %25 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K = predicate of trip K & that test  [output rail, kept]
  call void @cqrt_and_i1(i32 %15, i32 %24, i32 %25)    ; IR: br i1 %14 taken once more (rule 14)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %24, i32 %18, i32 %2)    ; IR: uncompute that test
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  %26 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %16 = phi i32 [ 0, %5 ], [ %13, %8 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %20, i32 %26)    ; IR: %16
  br label %27

27:
  %28 = phi i32 [ 0, %23 ], [ %39, %27 ]    ; IR: reverse trip index
  %29 = phi i32 [ %18, %23 ], [ %38, %27 ]    ; IR: %10 written by this trip
  %30 = phi i32 [ %20, %23 ], [ %37, %27 ]    ; IR: %9 written by this trip
  %31 = phi i32 [ %15, %23 ], [ %36, %27 ]    ; IR: predicate of this trip
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %30, i32 %31, i32 %32, i32 %37)    ; IR: uncompute next %9
  call void @cqrt_free(i32 %30)    ; IR: release next %9 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %32, i32 %37, i32 1)    ; IR: uncompute %13
  call void @cqrt_free(i32 %32)    ; IR: release %13 (|0>)
  call void @cq_template_select_i32_unc(i32 %29, i32 %31, i32 %33, i32 %38)    ; IR: uncompute next %10
  call void @cqrt_free(i32 %29)    ; IR: release next %10 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %33, i32 %34, i32 %4)    ; IR: uncompute %12
  call void @cqrt_free(i32 %33)    ; IR: release %12 (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %34, i32 %38, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %34)    ; IR: release %11 (|0>)
  call void @cqrt_and_i1(i32 %36, i32 %35, i32 %31)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)
  call void @cqrt_free(i32 %31)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %35, i32 %38, i32 %2)    ; IR: uncompute %7 / %14
  call void @cqrt_free(i32 %35)    ; IR: release %7 / %14 (|0>)
  %39 = add nuw nsw i32 %28, 1
  %40 = icmp ult i32 %39, 4    ; IR: K  [K]
  br i1 %40, label %27, label %41

41:
  call void @cqrt_free(i32 %36)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %37)    ; IR: release incoming 0 of phi %9 (never written, |0>)
  %42 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %42    ; IR: ret i32 %17
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
