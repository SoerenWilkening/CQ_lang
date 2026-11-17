; HAND-WRITTEN. Rules: 1, 2, 4, 25.
; Checked: fadd_f32: x + c (measured, %5 -> %6); fadd_f80: x + c (measured, %5 -> %6); fmul_f80_qq: x * y (measured, %7 -> %8).
; Clean: none to free: each entry computes exactly one template into the rail it measures.
; Kept: the registers (x %4 in fadd_f32 and fadd_f80; x %5 and y %6 in fmul_f80_qq) and the three measured result rails.
; Rotations: (Ry, x, th, 1) in fadd_f32; (Ry, x, th, 1) in fadd_f80; (Ry, x, tx, 1), (Ry, y, ty, 1) in fmul_f80_qq.
; Floating-point widths are width variants of the same ABI (rule 25): cq_theta on a float mints alloc_f32 and rotates
; with cqrt_ry_f32, on a long double alloc_f80 / cqrt_ry_f80 (x86_fp80 literals and handles). The mixed Q+C adds are
; _hl fadd templates with the classical c as a literal; the quantum-quantum product is the two-handle fmul_f80 template.
source_filename = "fp_widths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define float @fadd_f32(float noundef %0, double noundef %1, float noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f32(float %0)    ; IR: %4 = cq_theta_f32(%0, %1)  [register]
  call void @cqrt_ry_f32(i32 %4, double %1)    ; IR: %4 = cq_theta_f32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fadd_f32_hl(i32 %4, float %2)    ; IR: %5 = fadd float %4, %2
  %6 = call float @cqrt_measure_f32(i32 %5)    ; IR: %6 = cq_measure_f32(%5)
  ret float %6    ; IR: ret float %6
}

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @fadd_f80(x86_fp80 noundef %0, double noundef %1, x86_fp80 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f80(x86_fp80 %0)    ; IR: %4 = cq_theta_f80(%0, %1)  [register]
  call void @cqrt_ry_f80(i32 %4, double %1)    ; IR: %4 = cq_theta_f80(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fadd_f80_hl(i32 %4, x86_fp80 %2)    ; IR: %5 = fadd x86_fp80 %4, %2
  %6 = call x86_fp80 @cqrt_measure_f80(i32 %5)    ; IR: %6 = cq_measure_f80(%5)
  ret x86_fp80 %6    ; IR: ret x86_fp80 %6
}

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @fmul_f80_qq(x86_fp80 noundef %0, x86_fp80 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_f80(x86_fp80 %0)    ; IR: %5 = cq_theta_f80(%0, %2)  [register]
  call void @cqrt_ry_f80(i32 %5, double %2)    ; IR: %5 = cq_theta_f80(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_f80(x86_fp80 %1)    ; IR: %6 = cq_theta_f80(%1, %3)  [register]
  call void @cqrt_ry_f80(i32 %6, double %3)    ; IR: %6 = cq_theta_f80(%1, %3)  [Ry]
  %7 = call i32 @cq_template_fmul_f80(i32 %5, i32 %6)    ; IR: %7 = fmul x86_fp80 %5, %6
  %8 = call x86_fp80 @cqrt_measure_f80(i32 %7)    ; IR: %8 = cq_measure_f80(%7)
  ret x86_fp80 %8    ; IR: ret x86_fp80 %8
}

declare void @cqrt_ry_f32(i32, double)

declare i32 @cqrt_alloc_f32(float)

declare void @cqrt_ry_f80(i32, double)

declare i32 @cqrt_alloc_f80(x86_fp80)

declare i32 @cq_template_fadd_f32_hl(i32, float)

declare i32 @cq_template_fadd_f80_hl(i32, x86_fp80)

declare i32 @cq_template_fmul_f80(i32, i32)

declare float @cqrt_measure_f32(i32)

declare x86_fp80 @cqrt_measure_f80(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
