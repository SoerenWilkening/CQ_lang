; HAND-WRITTEN. Rules: 4, 2, 1.
; Checked: sdiv_qc: x / c (measured, %5 -> %6); udiv_qc: x / c (measured, %5 -> %6); srem_qc: x % c (measured,
; %5 -> %6); urem_qq: x % y (measured, %7 -> %8).
; Clean: none to free: each function allocates only its register(s) and the measured result rail.
; Kept: x (%4 in sdiv_qc, udiv_qc and srem_qc; %5 in urem_qq) and y (%6 in urem_qq): the rotated user registers, sources
; of the measured results.
; Rotations: (Ry, x, th, 1) in sdiv_qc, udiv_qc and srem_qc; (Ry, x, tx, 1); (Ry, y, ty, 1) in urem_qq.
; Integer division and remainder are ordinary out-of-place templates (rule 4): the signedness lives in the opcode name
; (sdiv/udiv, srem/urem) and the width in the suffix. A classical divisor is a literal of the _hl form; urem_qq divides
; two rails and takes the plain two-handle template. Division by zero and INT_MIN / -1 need no guard: every template
; is total (§2: udiv(a, 0) = 2^W - 1, urem(a, 0) = a, sdiv(a, 0) = -1 or +1 by the sign of a, srem(a, 0) = a,
; sdiv(INT_MIN, -1) = INT_MIN, srem(INT_MIN, -1) = 0), so the same call covers them.
; The result rail is measured; nothing else is allocated, so there is nothing to uncompute.
source_filename = "int_divrem.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @sdiv_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_sdiv_i32_hl(i32 %4, i32 %2)    ; IR: %5 = sdiv i32 %4, %2
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @udiv_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_udiv_i32_hl(i32 %4, i32 %2)    ; IR: %5 = udiv i32 %4, %2
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_ui32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @srem_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_srem_i32_hl(i32 %4, i32 %2)    ; IR: %5 = srem i32 %4, %2
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @urem_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_urem_i32(i32 %5, i32 %6)    ; IR: %7 = urem i32 %5, %6
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_ui32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_sdiv_i32_hl(i32, i32)

declare i32 @cq_template_udiv_i32_hl(i32, i32)

declare i32 @cq_template_srem_i32_hl(i32, i32)

declare i32 @cq_template_urem_i32(i32, i32)

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
