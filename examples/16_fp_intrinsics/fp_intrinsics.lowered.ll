; HAND-WRITTEN. Rules: 1, 2, 4.
; Checked: fabs(x) (%4 -> %5), copysign(x, s) (%5 -> %6), sqrt(x) (%4 -> %5), floor(x) (%4 -> %5), trunc(x) (%4 -> %5),
; rint(x) (%4 -> %5), fmax(x, c) (%5 -> %6), each the function's measured return.
; Clean: nothing to clean: each function holds only its rotated register and the measured result.
; Kept: each function's rotated f64 register x and its measured result rail.
; Rotations: (Ry, x, th, 1) in each of the seven functions.
; clang lowers each libm call on a double to its llvm.* intrinsic at -O1 (fabs, copysign, sqrt, floor, trunc, rint,
; maxnum), and a tainted intrinsic is one cq_template_<name>_f64 into a fresh rail (rule 4), the direct hardware route
; for the keep-set intrinsics. A classical second operand (copysign's sign s, fmax's c) is the literal of the _hl form.
; The measurement is the sink; nothing is left to uncompute.
source_filename = "fp_intrinsics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fabs_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_fabs_f64(i32 %3)    ; IR: %4 = tail call double @llvm.fabs.f64(double %3)
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %5    ; IR: ret double %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #1

; Function Attrs: nounwind ssp uwtable
define double @copysign_qc(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_copysign_f64_hl(i32 %4, double %2)    ; IR: %5 = tail call double @llvm.copysign.f64(double %4, double %2)
  %6 = call double @cqrt_measure_f64(i32 %5)    ; IR: %6 = cq_measure_f64(%5)
  ret double %6    ; IR: ret double %6
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.copysign.f64(double, double) #1

; Function Attrs: nounwind ssp uwtable
define double @sqrt_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_sqrt_f64(i32 %3)    ; IR: %4 = tail call double @llvm.sqrt.f64(double %3)
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %5    ; IR: ret double %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #1

; Function Attrs: nounwind ssp uwtable
define double @floor_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_floor_f64(i32 %3)    ; IR: %4 = tail call double @llvm.floor.f64(double %3)
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %5    ; IR: ret double %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #1

; Function Attrs: nounwind ssp uwtable
define double @trunc_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_trunc_f64(i32 %3)    ; IR: %4 = tail call double @llvm.trunc.f64(double %3)
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %5    ; IR: ret double %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.trunc.f64(double) #1

; Function Attrs: nounwind ssp uwtable
define double @rint_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_rint_f64(i32 %3)    ; IR: %4 = tail call double @llvm.rint.f64(double %3)
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %5    ; IR: ret double %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.rint.f64(double) #1

; Function Attrs: nounwind ssp uwtable
define double @fmax_qc(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fmax_f64_hl(i32 %4, double %2)    ; IR: %5 = tail call double @llvm.maxnum.f64(double %4, double %2)
  %6 = call double @cqrt_measure_f64(i32 %5)    ; IR: %6 = cq_measure_f64(%5)
  ret double %6    ; IR: ret double %6
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.maxnum.f64(double, double) #1

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare i32 @cq_template_fabs_f64(i32)

declare i32 @cq_template_copysign_f64_hl(i32, double)

declare i32 @cq_template_sqrt_f64(i32)

declare i32 @cq_template_floor_f64(i32)

declare i32 @cq_template_trunc_f64(i32)

declare i32 @cq_template_rint_f64(i32)

declare i32 @cq_template_fmax_f64_hl(i32, double)

declare double @cqrt_measure_f64(i32)

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
