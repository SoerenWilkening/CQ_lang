; HAND-WRITTEN. Rules: 14, 8, 9, 7, 5, 2.
; Checked: e (the outer select rail %51, measured as %80).
; Clean: every rail except the two a_K rails: the arm flags %9 (hx < k1), %10 (hx == 0), %11 (aA) and %12 (aB), both
; loops' per-trip rails (popped and uncomputed by the two reverse loops, every trip predicate 1..K included), each
; loop's after-trip-K exit test (uncomputed right after its a_K is formed), the constant seeds %13 (-1043) and %31
; (-1022), the hoisted hx << 11 (%30), the else arm %48/%49 and the inner merge %50, all freed.
; Kept: hx (%7) and lx (%8), the rotated registers; e (%51, measured); the two output rails a_K of loop A (%29) and of
; loop B (%47), rule 14.
; Rotations: (Ry, hx, t1, 1); (Ry, lx, t2, 1).
; Two normalization loops sit each inside a quantum arm: loop A under aA = (hx < k1) & (hx == 0), loop B under
; aB = (hx < k1) & !(hx == 0). A loop inside a quantum arm is the rolled K-bounded loop of example 05 whose predicate
; chain is SEEDED WITH THE ARM FLAG instead of a |1> rail (trips where the arm is not taken do nothing). The guard test
; and the latch test are the same compare on the carried value, so one compare per trip serves both: trip j runs under
; p_j = p_{j-1} & (v_j > 0). The five-way merge (else arm, two failed guards, two loop exits) is two selects: the
; guard-failed incomings are the carried value after zero trips, so each loop's final carried e covers both of its
; incomings; sAB = (hx == 0) ? eA : eB, e = (hx < k1) ? sAB : eC. Both loops push on one handle stack, so loop B is
; reversed before loop A. K = 4 (the literal 4 below).
; Output rails (rule 14): after its K-th trip each loop evaluates its exit test once more on the final carried value
; (lx_K > 0, resp. hx_K > 0) and keeps a_K = p_K & test as an output rail, neither uncomputed nor freed; a_K = 1 means
; that arm's loop would run a (K+1)-th trip (it had not finished normalizing), and a loop that exits after exactly K
; trips reads 0. The test itself is uncomputed at once. Every trip predicate p_1..p_K, the K-th included, is uncomputed
; by its reverse loop. The arm flags that seeded the chains are uncomputed as before.
source_filename = "loop_in_arm_multi_exit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @loop_in_arm_multi_exit(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %2)  [register hx]
  call void @cqrt_ry_i32(i32 %7, double %2)    ; IR: %7 = cq_theta_si32(%0, %2)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %8 = cq_theta_si32(%1, %3)  [register lx]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %8 = cq_theta_si32(%1, %3)  [Ry]
  %9 = call i32 @cq_template_icmp_slt_i32_hl(i32 %7, i32 %4)    ; IR: %9 = icmp slt i32 %7, %4  [predicate of block %10]
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)    ; IR: %11 = icmp eq i32 %7, 0
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %12 = %9 & %11
  call void @cqrt_and_i1(i32 %9, i32 %10, i32 %11)    ; IR: br i1 %11 inside block %10
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %20 = %9 & NOT %11
  call void @cqrt_not_i1(i32 %10)    ; IR: bracket: NOT %11
  call void @cqrt_and_i1(i32 %9, i32 %10, i32 %12)    ; IR: br i1 %11 inside block %10 (else edge)
  call void @cqrt_not_i1(i32 %10)    ; IR: bracket
  %13 = call i32 @cqrt_alloc_i32(i32 -1043)    ; IR: incoming -1043 of phi %15 (and of %33 from %12)
  br label %14

14:
  %15 = phi i32 [ 0, %6 ], [ %25, %14 ]    ; IR: trip index of loop A, bounded by K  [K]
  %16 = phi i32 [ %8, %6 ], [ %24, %14 ]    ; IR: %16 = phi i32 [ %18, %14 ], [ %8, %12 ]
  %17 = phi i32 [ %13, %6 ], [ %23, %14 ]    ; IR: %15 = phi i32 [ %17, %14 ], [ -1043, %12 ]
  %18 = phi i32 [ %11, %6 ], [ %20, %14 ]    ; IR: predicate of reaching this trip's test (trip 0: the arm flag)
  %19 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %16, i32 0)    ; IR: %13 = icmp sgt i32 %8, 0 (trip 0) / %19 = icmp sgt i32 %18, 0
  %20 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip
  call void @cqrt_and_i1(i32 %18, i32 %19, i32 %20)    ; IR: br i1 %13 (trip 0) / br i1 %19 taken
  %21 = call i32 @cq_template_add_i32_hl(i32 %17, i32 -1)    ; IR: %17 = add nsw i32 %15, -1
  %22 = call i32 @cq_template_shl_i32_hl(i32 %16, i32 1)    ; IR: %18 = shl nuw i32 %16, 1
  %23 = call i32 @cq_template_select_i32(i32 %20, i32 %21, i32 %17)    ; IR: next %15 = a ? %17 : %15
  %24 = call i32 @cq_template_select_i32(i32 %20, i32 %22, i32 %16)    ; IR: next %16 = a ? %18 : %16
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %22)
  %25 = add nuw nsw i32 %15, 1
  %26 = icmp ult i32 %25, 4    ; IR: K-bounded br i1 %19, label %14, label %32  [K]
  br i1 %26, label %14, label %27

27:
  %28 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %24, i32 0)    ; IR: %19 = icmp sgt i32 %18, 0 after trip K: the exit test that would admit a (K+1)-th trip of loop A
  %29 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K of loop A = predicate of trip K & that test  [output rail, kept]
  call void @cqrt_and_i1(i32 %20, i32 %28, i32 %29)    ; IR: br i1 %19 taken once more (rule 14)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %28, i32 %24, i32 0)    ; IR: uncompute that test
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  %30 = call i32 @cq_template_shl_i32_hl(i32 %7, i32 11)    ; IR: %21 = shl i32 %7, 11  (pure, hoisted out of block %20)
  %31 = call i32 @cqrt_alloc_i32(i32 -1022)    ; IR: incoming -1022 of phi %24 (and of %33 from %20)
  br label %32

32:
  %33 = phi i32 [ 0, %27 ], [ %43, %32 ]    ; IR: trip index of loop B, bounded by K  [K]
  %34 = phi i32 [ %30, %27 ], [ %42, %32 ]    ; IR: %25 = phi i32 [ %27, %23 ], [ %21, %20 ]
  %35 = phi i32 [ %31, %27 ], [ %41, %32 ]    ; IR: %24 = phi i32 [ %26, %23 ], [ -1022, %20 ]
  %36 = phi i32 [ %12, %27 ], [ %38, %32 ]    ; IR: predicate of reaching this trip's test (trip 0: the arm flag)
  %37 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %34, i32 0)    ; IR: %22 = icmp sgt i32 %21, 0 (trip 0) / %28 = icmp sgt i32 %27, 0
  %38 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip
  call void @cqrt_and_i1(i32 %36, i32 %37, i32 %38)    ; IR: br i1 %22 (trip 0) / br i1 %28 taken
  %39 = call i32 @cq_template_add_i32_hl(i32 %35, i32 -1)    ; IR: %26 = add nsw i32 %24, -1
  %40 = call i32 @cq_template_shl_i32_hl(i32 %34, i32 1)    ; IR: %27 = shl nuw i32 %25, 1
  %41 = call i32 @cq_template_select_i32(i32 %38, i32 %39, i32 %35)    ; IR: next %24 = a ? %26 : %24
  %42 = call i32 @cq_template_select_i32(i32 %38, i32 %40, i32 %34)    ; IR: next %25 = a ? %27 : %25
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %36)
  call void @cqrt_push(i32 %37)
  call void @cqrt_push(i32 %39)
  call void @cqrt_push(i32 %40)
  %43 = add nuw nsw i32 %33, 1
  %44 = icmp ult i32 %43, 4    ; IR: K-bounded br i1 %28, label %23, label %32  [K]
  br i1 %44, label %32, label %45

45:
  %46 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %42, i32 0)    ; IR: %28 = icmp sgt i32 %27, 0 after trip K: the exit test that would admit a (K+1)-th trip of loop B
  %47 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K of loop B = predicate of trip K & that test  [output rail, kept]
  call void @cqrt_and_i1(i32 %38, i32 %46, i32 %47)    ; IR: br i1 %28 taken once more (rule 14)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %46, i32 %42, i32 0)    ; IR: uncompute that test
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  %48 = call i32 @cq_template_ashr_i32_hl(i32 %7, i32 20)    ; IR: %30 = ashr i32 %7, 20  (block %29, pure, hoisted)
  %49 = call i32 @cq_template_sub_i32_hl(i32 %48, i32 %5)    ; IR: %31 = sub nsw i32 %30, %5
  %50 = call i32 @cq_template_select_i32(i32 %10, i32 %23, i32 %41)    ; IR: %33 = phi: inner merge of the two loop arms, (%11) ? e of loop A : e of loop B
  %51 = call i32 @cq_template_select_i32(i32 %9, i32 %50, i32 %49)    ; IR: %33 = phi: (%9) ? inner : %31  [result rail]
  call void @cq_template_select_i32_unc(i32 %50, i32 %10, i32 %23, i32 %41)    ; IR: uncompute the inner merge
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %49, i32 %48, i32 %5)    ; IR: uncompute %31
  call void @cqrt_free(i32 %49)    ; IR: release the %31 rail (|0>)
  call void @cq_template_ashr_i32_hl_unc(i32 %48, i32 %7, i32 20)    ; IR: uncompute %30
  call void @cqrt_free(i32 %48)    ; IR: release the %30 rail (|0>)
  br label %52

52:
  %53 = phi i32 [ 0, %45 ], [ %63, %52 ]    ; IR: reverse trip index of loop B
  %54 = phi i32 [ %42, %45 ], [ %62, %52 ]    ; IR: %25 written by this trip
  %55 = phi i32 [ %41, %45 ], [ %61, %52 ]    ; IR: %24 written by this trip
  %56 = phi i32 [ %38, %45 ], [ %60, %52 ]    ; IR: predicate of this trip
  %57 = call i32 @cqrt_pop()
  %58 = call i32 @cqrt_pop()
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  %61 = call i32 @cqrt_pop()
  %62 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %54, i32 %56, i32 %57, i32 %62)    ; IR: uncompute next %25
  call void @cqrt_free(i32 %54)    ; IR: release next %25 (|0>)
  call void @cq_template_select_i32_unc(i32 %55, i32 %56, i32 %58, i32 %61)    ; IR: uncompute next %24
  call void @cqrt_free(i32 %55)    ; IR: release next %24 (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %57, i32 %62, i32 1)    ; IR: uncompute %27
  call void @cqrt_free(i32 %57)    ; IR: release %27 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %58, i32 %61, i32 -1)    ; IR: uncompute %26
  call void @cqrt_free(i32 %58)    ; IR: release %26 (|0>)
  call void @cqrt_and_i1(i32 %60, i32 %59, i32 %56)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)
  call void @cqrt_free(i32 %56)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %59, i32 %62, i32 0)    ; IR: uncompute %22 / %28
  call void @cqrt_free(i32 %59)    ; IR: release %22 / %28 (|0>)
  %63 = add nuw nsw i32 %53, 1
  %64 = icmp ult i32 %63, 4    ; IR: K  [K]
  br i1 %64, label %52, label %65

65:
  call void @cqrt_free(i32 %61)    ; IR: release incoming -1022 of phi %24 (never written)
  call void @cq_template_shl_i32_hl_unc(i32 %62, i32 %7, i32 11)    ; IR: uncompute %21
  call void @cqrt_free(i32 %62)    ; IR: release the %21 rail (|0>)
  br label %66

66:
  %67 = phi i32 [ 0, %65 ], [ %77, %66 ]    ; IR: reverse trip index of loop A
  %68 = phi i32 [ %24, %65 ], [ %76, %66 ]    ; IR: %16 written by this trip
  %69 = phi i32 [ %23, %65 ], [ %75, %66 ]    ; IR: %15 written by this trip
  %70 = phi i32 [ %20, %65 ], [ %74, %66 ]    ; IR: predicate of this trip
  %71 = call i32 @cqrt_pop()
  %72 = call i32 @cqrt_pop()
  %73 = call i32 @cqrt_pop()
  %74 = call i32 @cqrt_pop()
  %75 = call i32 @cqrt_pop()
  %76 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %68, i32 %70, i32 %71, i32 %76)    ; IR: uncompute next %16
  call void @cqrt_free(i32 %68)    ; IR: release next %16 (|0>)
  call void @cq_template_select_i32_unc(i32 %69, i32 %70, i32 %72, i32 %75)    ; IR: uncompute next %15
  call void @cqrt_free(i32 %69)    ; IR: release next %15 (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %71, i32 %76, i32 1)    ; IR: uncompute %18
  call void @cqrt_free(i32 %71)    ; IR: release %18 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %72, i32 %75, i32 -1)    ; IR: uncompute %17
  call void @cqrt_free(i32 %72)    ; IR: release %17 (|0>)
  call void @cqrt_and_i1(i32 %74, i32 %73, i32 %70)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)
  call void @cqrt_free(i32 %70)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %73, i32 %76, i32 0)    ; IR: uncompute %13 / %19
  call void @cqrt_free(i32 %73)    ; IR: release %13 / %19 (|0>)
  %77 = add nuw nsw i32 %67, 1
  %78 = icmp ult i32 %77, 4    ; IR: K  [K]
  br i1 %78, label %66, label %79

79:
  call void @cqrt_free(i32 %75)    ; IR: release incoming -1043 of phi %15 (never written)
  call void @cqrt_not_i1(i32 %10)    ; IR: bracket: NOT %11
  call void @cqrt_and_i1(i32 %9, i32 %10, i32 %12)    ; IR: uncompute the block %20 predicate
  call void @cqrt_not_i1(i32 %10)    ; IR: bracket
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %9, i32 %10, i32 %11)    ; IR: uncompute the block %12 predicate
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %7, i32 0)    ; IR: uncompute %11
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %9, i32 %7, i32 %4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %80 = call i32 @cqrt_measure_i32(i32 %51)    ; IR: %34 = cq_measure_si32(%33)
  ret i32 %80    ; IR: ret i32 %34
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_ashr_i32_hl(i32, i32)
declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
