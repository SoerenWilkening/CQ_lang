; HAND-WRITTEN. Rules: 13, 14 (classical bound), 7, 9, 2, 4, 5.
; Checked: acc (the copied-out result %26 -> %44, measured; where the loop never runs the seed rail %5 -> %8 is measured).
; Clean: every trip rail (the scrutinee, the three equality flags, the three arm values and the select chain of each
; trip, and the old acc), popped and uncomputed by the reverse loop; the seed rail holding the classical 1 (%5, popped
; as %40), never written and freed directly.
; Kept: x (%4, the rotated register) and the measured result rail.
; Rotations: (Ry, x, th, 1).
; The loop is a classical loop with no predicate chain (25, 57; the trip count n is classical, only the switch inside
; the body is quantum). The quantum switch is the 22/49 value switch in its body, and acc is loop-carried and seeded
; CLASSICAL (a rail holding 1 before trip 0, as 62). The default label is `unreachable` (-O1 proved `& 3` covers 0..3),
; so case 3 is the complement: no flag, it is the innermost select operand, i.e. acc carried unchanged. Each trip
; computes the scrutinee, three equality flags, the three arm values from the carried acc and merges them by a select
; chain into a fresh rail (the next acc); the old acc and every intermediate are pushed, as in 57. The classical trip
; index is not pushed: the reverse trip j is the forward trip i = j and recomputes it. After the last trip the result is
; copied out, the reverse loop pops and uncomputes each trip LIFO, and the seed rail (the classical 1, never written) is
; in a known basis state and is freed directly (rule 7). Where the loop never runs, acc is the seed rail itself and is
; measured.
source_filename = "switch_in_loop_carried.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @switch_in_loop_carried(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: incoming 1 of phi %11 / %7  [acc before trip 0: a rail holding the classical 1]
  %6 = icmp sgt i32 %2, 0    ; IR: %5 = icmp sgt i32 %2, 0  (classical)
  br i1 %6, label %9, label %7    ; IR: br i1 %5, label %9, label %6

7:
  %8 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %8 = cq_measure_si32(%7), %7 = 1 from %3
  ret i32 %8    ; IR: ret i32 %8

9:
  %10 = phi i32 [ 0, %3 ], [ %23, %9 ]    ; IR: %10 = phi i32 [ %23, %21 ], [ 0, %3 ]  (classical)
  %11 = phi i32 [ %5, %3 ], [ %22, %9 ]    ; IR: %11 = phi i32 [ %22, %21 ], [ 1, %3 ]  [carried acc]
  %12 = call i32 @cq_template_ashr_i32_hl(i32 %4, i32 %10)    ; IR: %12 = ashr i32 %4, %10
  %13 = call i32 @cq_template_and_i32_hl(i32 %12, i32 3)    ; IR: %13 = and i32 %12, 3  [scrutinee]
  %14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 0)    ; IR: switch i32 %13: i32 0 -> %14
  %15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 1)    ; IR: switch i32 %13: i32 1 -> %16
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 2)    ; IR: switch i32 %13: i32 2 -> %18  (i32 3 -> %21: complement, no flag)
  %17 = call i32 @cq_template_add_i32_hl(i32 %11, i32 %10)    ; IR: %15 = add nsw i32 %10, %11  (commutative: classical operand moved to the _hl slot)
  %18 = call i32 @cq_template_xor_i32_hl(i32 %11, i32 5)    ; IR: %17 = xor i32 %11, 5
  %19 = call i32 @cq_template_mul_i32_hl(i32 %11, i32 3)    ; IR: %19 = mul nsw i32 %11, 3
  %20 = call i32 @cq_template_select_i32(i32 %16, i32 %19, i32 %11)    ; IR: %22 = phi: [ %19, %18 ] else [ %11, %9 ] (case 3)
  %21 = call i32 @cq_template_select_i32(i32 %15, i32 %18, i32 %20)    ; IR: %22 = phi: [ %17, %16 ]
  %22 = call i32 @cq_template_select_i32(i32 %14, i32 %17, i32 %21)    ; IR: %22 = phi: [ %15, %14 ]  [next acc]
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %13)
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %21)
  %23 = add nuw nsw i32 %10, 1    ; IR: %23 = add nuw nsw i32 %10, 1  (classical)
  %24 = icmp eq i32 %23, %2    ; IR: %24 = icmp eq i32 %23, %2  (classical)
  br i1 %24, label %25, label %9    ; IR: br i1 %24, label %6, label %9

25:
  %26 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %7 = phi i32 [ %22, %21 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %22, i32 %26)    ; IR: %7
  br label %27

27:
  %28 = phi i32 [ %10, %25 ], [ %41, %27 ]    ; IR: trip being undone, from the last down to 0 (its classical i)
  %29 = phi i32 [ %22, %25 ], [ %40, %27 ]    ; IR: %22 of this trip
  %30 = call i32 @cqrt_pop()
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  call void @cq_template_select_i32_unc(i32 %29, i32 %37, i32 %34, i32 %30)    ; IR: uncompute %22 (outer select)
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %30, i32 %36, i32 %33, i32 %31)    ; IR: uncompute the middle merge
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %31, i32 %35, i32 %32, i32 %40)    ; IR: uncompute the innermost merge
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %32, i32 %40, i32 3)    ; IR: uncompute %19
  call void @cqrt_free(i32 %32)    ; IR: release the %19 rail (|0>)
  call void @cq_template_xor_i32_hl_unc(i32 %33, i32 %40, i32 5)    ; IR: uncompute %17
  call void @cqrt_free(i32 %33)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %34, i32 %40, i32 %28)    ; IR: uncompute %15
  call void @cqrt_free(i32 %34)    ; IR: release the %15 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %35, i32 %38, i32 2)    ; IR: uncompute the case-2 flag
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %36, i32 %38, i32 1)    ; IR: uncompute the case-1 flag
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %37, i32 %38, i32 0)    ; IR: uncompute the case-0 flag
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %38, i32 %39, i32 3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %38)    ; IR: release the %13 rail (|0>)
  call void @cq_template_ashr_i32_hl_unc(i32 %39, i32 %4, i32 %28)    ; IR: uncompute %12
  call void @cqrt_free(i32 %39)    ; IR: release the %12 rail (|0>)
  %41 = add nsw i32 %28, -1
  %42 = icmp sgt i32 %41, -1    ; IR: trips n-1 down to 0
  br i1 %42, label %27, label %43

43:
  call void @cqrt_free(i32 %40)    ; IR: release incoming 1 of phi %11 directly (rule 7: a seed rail holding the classical 1)
  %44 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %44    ; IR: ret i32 %8
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_ashr_i32_hl(i32, i32)
declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_xor_i32_hl(i32, i32)
declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
