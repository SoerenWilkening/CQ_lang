; HAND-WRITTEN. Rules: 24, 20, 4, 9, 5, 7, 2.
; Checked: now + ok + expected: the final cell, the cmpxchg success flag and the loaded value (measured).
; Clean: the cmpxchg equality flag; the classical initial-value rail c (never entangled, freed directly, rule 7).
; Kept: the user register x (the cell after the atomic store); the fetch-add result x + c and the cmpxchg select
; (the cell's later values: one of them is the measured `now`, the loaded value is the measured `expected`); the zext'd
; flag (measured).
; Rotations: Ry(th) on x.
; THREADS ARE OUT OF THE MODEL (rule 24): a reversible circuit is sequential, so every atomic op has single-thread
; semantics and lowers as the plain op it wraps: store atomic = store, load atomic = load, atomicrmw add = load + add
; + store (its result is the old value), cmpxchg = load + icmp eq + select + store returning { loaded, equal } as two
; rails (64's aggregate), fence = nothing (no gate, no host call). cell is a non-escaping alloca written with a quantum
; value, so it is a SLOT OF HANDLES (31, rule 20): the classical initial store is promoted to a fresh rail holding c,
; and every later store/load moves a handle. The cmpxchg's loaded value (%10, "expected" after a failed exchange) and
; the final cell (%12) and the flag are measured; the rest is uncomputed.
source_filename = "atomics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @atomics(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = alloca i32, align 4    ; IR: %5 = alloca i32  (cell: a slot holding a handle)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %5: the classical initial value as a rail (the slot holds handles)
  store i32 %7, ptr %5, align 4    ; IR: store i32 %2, ptr %5  (store the handle)
  store i32 %6, ptr %5, align 4    ; IR: store atomic i32 %6, ptr %5 seq_cst: single-thread, a plain store of the handle
  %8 = load i32, ptr %5, align 4    ; IR: %7 = atomicrmw add ptr %5, i32 %2: the old value (the handle in the slot)
  %9 = call i32 @cq_template_add_i32_hl(i32 %8, i32 %2)    ; IR: %7: old + %2  [the new cell]
  store i32 %9, ptr %5, align 4    ; IR: %7: store the new cell's handle
  ; IR: fence seq_cst: no gate (single thread)
  %10 = load i32, ptr %5, align 4    ; IR: %8 = cmpxchg ptr %5, i32 %3, i32 %7: the loaded value, element 0 (%10)  [measured]
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 %3)    ; IR: %8: element 1 (%9), loaded == expected
  %12 = call i32 @cq_template_select_i32(i32 %11, i32 %8, i32 %10)    ; IR: %8: cell = equal ? %7 (the old value) : loaded  [the new cell]
  store i32 %12, ptr %5, align 4    ; IR: %8: store the new cell's handle
  %13 = call i32 @cq_template_zext_i1_to_i32(i32 %11)    ; IR: %11 = zext i1 %9 to i32  [measured]
  %14 = load i32, ptr %5, align 4    ; IR: %12 = load atomic i32, ptr %5 seq_cst: a plain load of the handle  [measured]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %10, i32 %3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  %15 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %13 = cq_measure_si32(%12)
  %16 = call i32 @cqrt_measure_i32(i32 %13)    ; IR: %14 = cq_measure_si32(%11)
  %17 = add nsw i32 %16, %15    ; IR: %15 = add nsw i32 %14, %13  (classical)
  %18 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %16 = cq_measure_si32(%10)
  %19 = add nsw i32 %17, %18    ; IR: %17 = add nsw i32 %15, %16  (classical)
  call void @cqrt_free(i32 %7)    ; IR: release the initial-value rail (never entangled, holds the classical c: 28's first s rail)
  ret i32 %19    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
