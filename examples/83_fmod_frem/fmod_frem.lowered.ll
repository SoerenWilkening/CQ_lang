; HAND-WRITTEN. Rules: 4, 2, 25.
; Checked: fmod_qc: fmod(x, c) (%5 -> %6). fmod_cq: fmod(c, x) (%5 -> %6). fmodf_qq: fmodf(x, y) (%7 -> %8).
; fmodl_qc: fmodl(x, c) (%5 -> %6).
; Clean: nothing to free: each function is one template from its register(s) to the measured rail.
; Kept: the rotated register(s) of each function (%4; %4; %5 and %6; %4) and each measured result rail.
; Rotations: fmod_qc: (Ry, x, th, 1). fmod_cq: (Ry, x, th, 1). fmodf_qq: (Ry, x, tx, 1); (Ry, y, ty, 1).
; fmodl_qc: (Ry, x, th, 1).
; fmod/fmodf/fmodl with builtins on reach -O1 IR as the frem instruction, not a call, so they lower like fdiv (13, 19):
; cq_template_frem_<W>[_hl|_lh] out of place into a fresh rail. Backend coverage: frem is exact (the IEEE remainder of a
; truncated quotient, never rounded), raises no INEXACT, and is the same op at f32/f64/f80. The f80 case is what amd64
; openlibm implements with x87 fprem.
source_filename = "fmod_frem.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fmod_qc(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_frem_f64_hl(i32 %4, double %2)    ; IR: %5 = frem double %4, %2
  %6 = call double @cqrt_measure_f64(i32 %5)    ; IR: %6 = cq_measure_f64(%5)
  ret double %6    ; IR: ret double %6
}

; Function Attrs: nounwind ssp uwtable
define double @fmod_cq(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_frem_f64_lh(double %2, i32 %4)    ; IR: %5 = frem double %2, %4
  %6 = call double @cqrt_measure_f64(i32 %5)    ; IR: %6 = cq_measure_f64(%5)
  ret double %6    ; IR: ret double %6
}

; Function Attrs: nounwind ssp uwtable
define float @fmodf_qq(float noundef %0, float noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_f32(float %0)    ; IR: %5 = cq_theta_f32(%0, %2)  [register]
  call void @cqrt_ry_f32(i32 %5, double %2)    ; IR: %5 = cq_theta_f32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_f32(float %1)    ; IR: %6 = cq_theta_f32(%1, %3)  [register]
  call void @cqrt_ry_f32(i32 %6, double %3)    ; IR: %6 = cq_theta_f32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_frem_f32(i32 %5, i32 %6)    ; IR: %7 = frem float %5, %6
  %8 = call float @cqrt_measure_f32(i32 %7)    ; IR: %8 = cq_measure_f32(%7)
  ret float %8    ; IR: ret float %8
}

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @fmodl_qc(x86_fp80 noundef %0, double noundef %1, x86_fp80 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f80(x86_fp80 %0)    ; IR: %4 = cq_theta_f80(%0, %1)  [register]
  call void @cqrt_ry_f80(i32 %4, double %1)    ; IR: %4 = cq_theta_f80(%0, %1)  [Ry]
  %5 = call i32 @cq_template_frem_f80_hl(i32 %4, x86_fp80 %2)    ; IR: %5 = frem x86_fp80 %4, %2
  %6 = call x86_fp80 @cqrt_measure_f80(i32 %5)    ; IR: %6 = cq_measure_f80(%5)
  ret x86_fp80 %6    ; IR: ret x86_fp80 %6
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cqrt_alloc_f32(float)
declare void @cqrt_ry_f32(i32, double)
declare i32 @cqrt_alloc_f80(x86_fp80)
declare void @cqrt_ry_f80(i32, double)
declare i32 @cq_template_frem_f64_hl(i32, double)
declare i32 @cq_template_frem_f64_lh(double, i32)
declare i32 @cq_template_frem_f32(i32, i32)
declare i32 @cq_template_frem_f80_hl(i32, x86_fp80)
declare double @cqrt_measure_f64(i32)
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
