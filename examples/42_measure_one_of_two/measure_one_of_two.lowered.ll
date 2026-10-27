; HAND-WRITTEN. Rules: 2, 4, 5.
; Checked: mx = x (%6, measured as %9) and t = (x + y) * c (%10, measured as %11); the returned sum is classical.
; Clean: s = x + y (%8), uncomputed against x and y after t is computed, freed.
; Kept: x (%6, measured) and y (%7, the rotated register, a source of t); t (%10, measured).
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1).
; s = x + y is a fresh rail (rule 4) and t = s * c a fresh _hl rail. s is garbage once t exists and is uncomputed
; against x and y (rule 5); x was measured in between, and its _unc reads x's rail after that measurement. §1.3 permits
; this: a measured rail is never freed and afterwards holds the outcome, a known basis state that may still be read as an
; operand (never rotated again); on every surviving branch s = outcome + y, so the uncompute returns s to |0>. The two
; measurement results are added classically.
source_filename = "measure_one_of_two.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @measure_one_of_two(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %2)    ; IR: %6 = cq_theta_si32(%0, %2)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %7 = cq_theta_si32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_si32(%1, %3)  [Ry]
  %8 = call i32 @cq_template_add_i32(i32 %6, i32 %7)    ; IR: %8 = add nsw i32 %7, %6
  %9 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %9 = cq_measure_si32(%6)  [x measured; its rail now holds a classical value]
  %10 = call i32 @cq_template_mul_i32_hl(i32 %8, i32 %4)    ; IR: %10 = mul nsw i32 %8, %4
  call void @cq_template_add_i32_unc(i32 %8, i32 %6, i32 %7)    ; IR: uncompute %8 (x is measured but unchanged)
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %11 = cq_measure_si32(%10)
  %12 = add nsw i32 %11, %9    ; IR: %12 = add nsw i32 %11, %9  (classical)
  ret i32 %12    ; IR: ret i32 %12
}

declare void @cq_template_add_i32_unc(i32, i32, i32)
declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

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
