; HAND-WRITTEN. Rules: 1, 2, 4, 5.
; Checked: fmuladd_qcc's x * a + b (%6 -> %7) and fmuladd_qqq's x * y + z (%10 -> %11), each the function's measured
; return.
; Clean: each function's product rail (x * a; x * y), uncomputed by its fmul _unc after the fadd read it, then freed.
; Kept: each function's rotated f64 register(s) (%5; %7, %8, %9) and its measured result rail.
; Rotations: (Ry, x, th, 1) in fmuladd_qcc; (Ry, x, tx, 1); (Ry, y, ty, 1); (Ry, z, tz, 1) in fmuladd_qqq.
; clang contracts `x * a + b` into one llvm.fmuladd.f64 at -O1. llvm.fmuladd is UNFUSED (§2): the x86-64 baseline has
; no FMA unit, so the classical program rounds twice, and the lowering is an fmul into a fresh product rail, then an
; fadd of that product into a fresh result rail (rule 4, each out of place); only a genuine llvm.fma is one fused
; template. The product rail is garbage: its fmul _unc returns it to |0> once the fadd has read it (rule 5), and it is
; freed. The measurement is the sink.
source_filename = "fmuladd.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fmuladd_qcc(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @cq_template_fmul_f64_hl(i32 %5, double %2)    ; IR: %6 = tail call double @llvm.fmuladd.f64(double %5, double %2, double %3)  [product x * a]
  %7 = call i32 @cq_template_fadd_f64_hl(i32 %6, double %3)    ; IR: %6 = tail call double @llvm.fmuladd.f64(double %5, double %2, double %3)  [sum + b]
  call void @cq_template_fmul_f64_hl_unc(i32 %6, i32 %5, double %2)    ; IR: %6 [uncompute the product rail]
  call void @cqrt_free(i32 %6)    ; IR: %6 [free the product rail]
  %8 = call double @cqrt_measure_f64(i32 %7)    ; IR: %7 = cq_measure_f64(%6)
  ret double %8    ; IR: ret double %7
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: nounwind ssp uwtable
define double @fmuladd_qqq(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %7 = cq_theta_f64(%0, %3)  [register]
  call void @cqrt_ry_f64(i32 %7, double %3)    ; IR: %7 = cq_theta_f64(%0, %3)  [Ry]
  %8 = call i32 @cqrt_alloc_f64(double %1)    ; IR: %8 = cq_theta_f64(%1, %4)  [register]
  call void @cqrt_ry_f64(i32 %8, double %4)    ; IR: %8 = cq_theta_f64(%1, %4)  [Ry]
  %9 = call i32 @cqrt_alloc_f64(double %2)    ; IR: %9 = cq_theta_f64(%2, %5)  [register]
  call void @cqrt_ry_f64(i32 %9, double %5)    ; IR: %9 = cq_theta_f64(%2, %5)  [Ry]
  %10 = call i32 @cq_template_fmul_f64(i32 %7, i32 %8)    ; IR: %10 = tail call double @llvm.fmuladd.f64(double %7, double %8, double %9)  [product x * y]
  %11 = call i32 @cq_template_fadd_f64(i32 %10, i32 %9)    ; IR: %10 = tail call double @llvm.fmuladd.f64(double %7, double %8, double %9)  [sum + z]
  call void @cq_template_fmul_f64_unc(i32 %10, i32 %7, i32 %8)    ; IR: %10 [uncompute the product rail]
  call void @cqrt_free(i32 %10)    ; IR: %10 [free the product rail]
  %12 = call double @cqrt_measure_f64(i32 %11)    ; IR: %11 = cq_measure_f64(%10)
  ret double %12    ; IR: ret double %11
}

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare i32 @cq_template_fmul_f64_hl(i32, double)

declare i32 @cq_template_fadd_f64_hl(i32, double)

declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)

declare i32 @cq_template_fmul_f64(i32, i32)

declare i32 @cq_template_fadd_f64(i32, i32)

declare void @cq_template_fmul_f64_unc(i32, i32, i32)

declare void @cqrt_free(i32)

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
