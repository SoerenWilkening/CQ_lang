; HAND-WRITTEN. Rules: 1, 3, 2, 4.
; Checked: each function's cast of x (%4 -> %5, measured): (short)x, (int)(unsigned short)x, (int)(signed char)x,
; (double)x, (int)x from a double, (double)x from a float, (float)x from a double.
; Clean: nothing to clean: each function holds only its rotated register and the measured result.
; Kept: each function's rotated register x (%3, at the source width) and its measured result rail at the target width.
; Rotations: (Ry, x, th, 1) in each of the seven functions.
; A cast is a representation change, never a measurement (rule 3): a tainted trunc/zext/sext/sitofp/fptosi/fpext/fptrunc
; is one cq_template_<cast>_<from>_to_<to> into a fresh rail at the target width (rule 4), and the source rail keeps its
; width. Taint flows through the cast into the result, which is measured at the target width. The measurement is the
; sink; nothing is left to uncompute.
source_filename = "casts.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define signext i16 @trunc_i32_i16(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_si32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %3, double %1)    ; IR: %3 = cq_theta_si32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_trunc_i32_to_i16(i32 %3)    ; IR: %4 = trunc i32 %3 to i16
  %5 = call i16 @cqrt_measure_i16(i32 %4)    ; IR: %5 = cq_measure_si16(%4)
  ret i16 %5    ; IR: ret i16 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @zext_u16_i32(i16 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_i16(i16 %0)    ; IR: %3 = cq_theta_ui16(%0, %1)  [register]
  call void @cqrt_ry_i16(i32 %3, double %1)    ; IR: %3 = cq_theta_ui16(%0, %1)  [Ry]
  %4 = call i32 @cq_template_zext_i16_to_i32(i32 %3)    ; IR: %4 = zext i16 %3 to i32
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_si32(%4)
  ret i32 %5    ; IR: ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @sext_i8_i32(i8 noundef signext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %3 = cq_theta_si8(%0, %1)  [register]
  call void @cqrt_ry_i8(i32 %3, double %1)    ; IR: %3 = cq_theta_si8(%0, %1)  [Ry]
  %4 = call i32 @cq_template_sext_i8_to_i32(i32 %3)    ; IR: %4 = sext i8 %3 to i32
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_si32(%4)
  ret i32 %5    ; IR: ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define double @sitofp_q(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_si32(%0, %1)  [register]
  call void @cqrt_ry_i32(i32 %3, double %1)    ; IR: %3 = cq_theta_si32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_sitofp_i32_to_f64(i32 %3)    ; IR: %4 = sitofp i32 %3 to double
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %5    ; IR: ret double %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @fptosi_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_fptosi_f64_to_i32(i32 %3)    ; IR: %4 = fptosi double %3 to i32
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_si32(%4)
  ret i32 %5    ; IR: ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define double @fpext_q(float noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f32(float %0)    ; IR: %3 = cq_theta_f32(%0, %1)  [register]
  call void @cqrt_ry_f32(i32 %3, double %1)    ; IR: %3 = cq_theta_f32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_fpext_f32_to_f64(i32 %3)    ; IR: %4 = fpext float %3 to double
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %5    ; IR: ret double %5
}

; Function Attrs: nounwind ssp uwtable
define float @fptrunc_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_fptrunc_f64_to_f32(i32 %3)    ; IR: %4 = fptrunc double %3 to float
  %5 = call float @cqrt_measure_f32(i32 %4)    ; IR: %5 = cq_measure_f32(%4)
  ret float %5    ; IR: ret float %5
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i16(i32, double)

declare i32 @cqrt_alloc_i16(i16 signext)

declare void @cqrt_ry_i8(i32, double)

declare i32 @cqrt_alloc_i8(i8 signext)

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_ry_f32(i32, double)

declare i32 @cqrt_alloc_f32(float)

declare i32 @cq_template_trunc_i32_to_i16(i32)

declare i32 @cq_template_zext_i16_to_i32(i32)

declare i32 @cq_template_sext_i8_to_i32(i32)

declare i32 @cq_template_sitofp_i32_to_f64(i32)

declare i32 @cq_template_fptosi_f64_to_i32(i32)

declare i32 @cq_template_fpext_f32_to_f64(i32)

declare i32 @cq_template_fptrunc_f64_to_f32(i32)

declare signext i16 @cqrt_measure_i16(i32)

declare i32 @cqrt_measure_i32(i32)

declare double @cqrt_measure_f64(i32)

declare float @cqrt_measure_f32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
