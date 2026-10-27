; HAND-WRITTEN. Rules: 9, 8, 4, 5, 2.
; Checked: r = (x > k) ? x + c : x * s (measured, %10 -> %11).
; Clean: the flag f = (x > k) (%9), the then-arm value x + c (%7) and the else-arm value x * s (%8), each uncomputed
; by its template's _unc and freed, in LIFO order (flag, product, sum).
; Kept: x (%6, the rotated user register; a source of r, never freed).
; Rotations: (Ry, x, th, 1).
; Both arms are pure, so they are hoisted and computed unguarded into fresh rails (rule 9); the merge phi is one
; cq_template_select_i32(f, then, else) into a fresh |0> result rail. The classical c and s are literals of the _hl
; templates (rule 4). The flag is uncomputed after its last consumer (the select), then the two arm rails, since they are
; garbage once r exists; only x and r stay allocated, and r is measured.
source_filename = "value_arm_ifelse.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @value_arm_ifelse(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_add_i32_hl(i32 %6, i32 %3)    ; IR: %8 = add nsw i32 %6, %3
  %8 = call i32 @cq_template_mul_i32_hl(i32 %6, i32 %4)    ; IR: %9 = mul nsw i32 %6, %4
  %9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %7 = icmp sgt i32 %6, %2
  %10 = call i32 @cq_template_select_i32(i32 %9, i32 %7, i32 %8)    ; IR: %10 = select i1 %7, i32 %8, i32 %9  [result rail]
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %9, i32 %6, i32 %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %8, i32 %6, i32 %4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %7, i32 %6, i32 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %7)    ; IR: release the %8 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %11 = cq_measure_si32(%10)
  ret i32 %11    ; IR: ret i32 %11
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cq_template_select_i32(i32, i32, i32)


declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)


declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
