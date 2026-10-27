; HAND-WRITTEN. Rules: 1, 2, 3, 4, 5.
; Checked: z = (long long)x * y (%8, measured as %9).
; Clean: the sign extension of x to i64 (%7), uncomputed after the multiply and freed.
; Kept: x (%5, i32) and y (%6, i64), the rotated registers and sources of z; z (%8, measured).
; Rotations: (Ry, x, tx, 1); (Ry_i64, y, ty, 1).
; The i32 register is sign-extended into a fresh i64 rail (a cast is a representation change by rule 3, emitted as
; the width-changing template of rule 4) for the i64 multiply into a fresh rail; the extension is then uncomputed
; against x (rule 5). Every handle is an i32 regardless of the rail width (rule 1).
source_filename = "mixed_widths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @mixed_widths(i32 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register x, i32]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i64(i64 %1)    ; IR: %6 = cq_theta_sll(%1, %3)  [register y, i64]
  call void @cqrt_ry_i64(i32 %6, double %3)    ; IR: %6 = cq_theta_sll(%1, %3)  [Ry]
  %7 = call i32 @cq_template_sext_i32_to_i64(i32 %5)    ; IR: %7 = sext i32 %5 to i64
  %8 = call i32 @cq_template_mul_i64(i32 %6, i32 %7)    ; IR: %8 = mul nsw i64 %6, %7
  call void @cq_template_sext_i32_to_i64_unc(i32 %7, i32 %5)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %9 = call i64 @cqrt_measure_i64(i32 %8)    ; IR: %9 = cq_measure_sll(%8)
  ret i64 %9    ; IR: ret i64 %9
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i64(i32, double)

declare i32 @cqrt_alloc_i64(i64)

declare i32 @cq_template_sext_i32_to_i64(i32)

declare i32 @cq_template_mul_i64(i32, i32)

declare i64 @cqrt_measure_i64(i32)

declare void @cq_template_sext_i32_to_i64_unc(i32, i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
