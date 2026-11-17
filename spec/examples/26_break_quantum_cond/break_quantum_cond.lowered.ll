; HAND-WRITTEN. Rules: 14 (mixed exit), 7, 4, 5.
; Checked: break_quantum_cond: i (measured, %8 -> %9); break_with_body: acc (measured; %26 -> %40 when a trip runs, %7 -> %10
; when n < 1).
; Clean: break_quantum_cond: the difference rail %7 = x - k. break_with_body: every trip rail (the equality flag, the
; negated predicate, acc * c, acc * c + i, the selected acc) and EVERY trip predicate a_0 .. a_{n-1}, the last included,
; popped and uncomputed by the reverse loop; the |1> seed and the |0> incoming of acc are freed directly.
; Kept: x (the rotated register, %5 / %6) and the measured result rails. No predicate is kept: the bound is classical,
; so every predicate is a function of the inputs and the mirror uncomputes it (rule 14, classical bound with a quantum
; exit).
; Rotations: (Ry, x, th, 1) in each entry.
; break_quantum_cond: -O1 folds the empty loop with a quantum break into smax/umin, so no loop remains: i = umin(x - k,
; smax(n, 0)) is one _hl sub template and one _hl umin template (the smax is classical), and the difference rail is
; uncomputed before the measurement.
; break_with_body: the classical bound `i < n` stays a classical loop; the quantum break feeds the trip predicate chain
; a_i = a_{i-1} & NOT(x == i + k), seeded |1>. Each trip computes its values into fresh rails and pushes them; after acc
; is copied out a reverse loop pops and uncomputes every trip, its predicate included (no cutoff applies, so no
; predicate is an output rail). When n < 1 no trip runs and there is no predicate rail: the |1> seed is minted in the
; preheader, after the classical zero-trip test, never on the skip path (ruling 2026-10-29, cq-ph2i). The |1> seed is freed
; directly (rule 7).
source_filename = "break_quantum_cond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_quantum_cond(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = tail call i32 @llvm.smax.i32(i32 %2, i32 0)    ; IR: %6 = llvm.smax.i32(%2, 0)  (classical)
  %7 = call i32 @cq_template_sub_i32_hl(i32 %5, i32 %3)    ; IR: %8 = sub i32 %7, %3  (%7 = freeze %5 is %5)
  %8 = call i32 @cq_template_umin_i32_hl(i32 %7, i32 %6)    ; IR: %9 = llvm.umin.i32(%8, %6)
  call void @cq_template_sub_i32_hl_unc(i32 %7, i32 %5, i32 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %7)    ; IR: release the %8 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %10 = cq_measure_si32(%9)
  ret i32 %9    ; IR: ret i32 %10
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
define i32 @break_with_body(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %12 / %21  [acc before trip 0]
  %8 = icmp slt i32 %2, 1    ; IR: %7 = icmp slt i32 %2, 1  (classical half of %9: no trip at all)
  br i1 %8, label %9, label %11    ; IR: br i1 %9 on its classical half; the quantum half %8 becomes the trip-0 predicate

9:
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %22 = cq_measure_si32(%21), %21 = 0 from %5  (no trip ran: no predicate rail exists)
  ret i32 %10    ; IR: ret i32 %22

11:
  %12 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test (always 1); minted only where a trip can run (rule 14, 7)
  br label %13

13:
  %14 = phi i32 [ 0, %11 ], [ %23, %13 ]    ; IR: %11 = phi i32 [ %15, %10 ], [ 0, %5 ]  (classical)
  %15 = phi i32 [ %7, %11 ], [ %22, %13 ]    ; IR: %12 = phi i32 [ %14, %10 ], [ 0, %5 ]
  %16 = phi i32 [ %12, %11 ], [ %19, %13 ]    ; IR: predicate of reaching this trip's break test
  %17 = add nsw i32 %14, %3    ; IR: %17 = add nsw i32 %15, %3 of the previous trip (i + k, classical; %3 itself for trip 0)
  %18 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 %17)    ; IR: %8 (trip 0) / %18 = icmp eq i32 %6, %17  [break condition]
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %10 at this trip
  call void @cqrt_not_i1(i32 %18)    ; IR: bracket: trip runs when the break condition is false
  call void @cqrt_and_i1(i32 %16, i32 %18, i32 %19)    ; IR: br i1 %9 / %19 not taken: a = ap & NOT e
  call void @cqrt_not_i1(i32 %18)    ; IR: bracket
  %20 = call i32 @cq_template_mul_i32_hl(i32 %15, i32 %4)    ; IR: %13 = mul nsw i32 %12, %4
  %21 = call i32 @cq_template_add_i32_hl(i32 %20, i32 %14)    ; IR: %14 = add nsw i32 %13, %11
  %22 = call i32 @cq_template_select_i32(i32 %19, i32 %21, i32 %15)    ; IR: next %12 / %21 = a ? %14 : %12
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %21)
  %23 = add nuw nsw i32 %14, 1    ; IR: %15 = add nuw nsw i32 %11, 1
  %24 = icmp sge i32 %23, %2    ; IR: %16 = icmp sge i32 %15, %2  (classical half of %19)
  br i1 %24, label %25, label %13    ; IR: br i1 %19 on its classical half

25:
  %26 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %21 = phi i32 [ %14, %10 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %22, i32 %26)    ; IR: %21
  br label %27

27:
  %28 = phi i32 [ %14, %25 ], [ %37, %27 ]    ; IR: trip index being undone, from the last down to 0
  %29 = phi i32 [ %22, %25 ], [ %35, %27 ]
  %30 = phi i32 [ %19, %25 ], [ %34, %27 ]
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = add nsw i32 %28, %3    ; IR: i + k of that trip (classical)
  call void @cq_template_select_i32_unc(i32 %29, i32 %30, i32 %31, i32 %35)    ; IR: uncompute next %12
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %31, i32 %32, i32 %28)    ; IR: uncompute %14
  call void @cqrt_free(i32 %31)    ; IR: release the %14 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %32, i32 %35, i32 %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %32)    ; IR: release the %13 rail (|0>)
  call void @cqrt_not_i1(i32 %33)    ; IR: bracket
  call void @cqrt_and_i1(i32 %34, i32 %33, i32 %30)    ; IR: uncompute the trip predicate (every trip, the last included: rule 14, classical bound)
  call void @cqrt_not_i1(i32 %33)    ; IR: bracket
  call void @cqrt_free(i32 %30)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %33, i32 %6, i32 %36)    ; IR: uncompute %8 / %18
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  %37 = add nsw i32 %28, -1
  %38 = icmp sge i32 %37, 0
  br i1 %38, label %27, label %39

39:
  call void @cqrt_free(i32 %34)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %35)    ; IR: release incoming 0 of phi %12 (never written, |0>)
  %40 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %22 = cq_measure_si32(%21)
  ret i32 %40    ; IR: ret i32 %22
}

declare i32 @cqrt_pop()

declare void @cqrt_push(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_select_i32_unc(i32, i32, i32, i32)

declare i32 @cq_template_select_i32(i32, i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @llvm.smax.i32(i32, i32) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #1

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare i32 @cq_template_umin_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
