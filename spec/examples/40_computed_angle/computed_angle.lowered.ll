; HAND-WRITTEN. Rules: 2, 3.
; Checked: x (%11, measured as %12).
; Clean: none to free: the only rail is the user register.
; Kept: x (%11, measured).
; Rotations: (Ry, x, scale * pi / (n + 1) + i * 0.5, 1).
; The angle is classical arithmetic over classical parameters (rule 3: the angle operand of a rotation is classical),
; so it stays classical SSA (%10) and is consumed only by the Ry. cq_theta on the classical x0 mints alloc_i32(x0) and
; rotates it in place (rule 2); the measurement is the sink.
source_filename = "computed_angle.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @computed_angle(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = fmul double %3, 0x400921FB54442D18    ; IR: %5 (classical)
  %6 = add nsw i32 %1, 1    ; IR: %6 (classical)
  %7 = sitofp i32 %6 to double    ; IR: %7 (classical)
  %8 = fdiv double %5, %7    ; IR: %8 (classical)
  %9 = sitofp i32 %2 to double    ; IR: %9 (classical)
  %10 = tail call double @llvm.fmuladd.f64(double %9, double 5.000000e-01, double %8)    ; IR: %10 (classical angle)
  %11 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %11 = cq_theta_si32(%0, %10)  [register x]
  call void @cqrt_ry_i32(i32 %11, double %10)    ; IR: %11 = cq_theta_si32(%0, %10)  [Ry with the computed angle]
  %12 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %12 = cq_measure_si32(%11)
  ret i32 %12    ; IR: ret i32 %12
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)

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
