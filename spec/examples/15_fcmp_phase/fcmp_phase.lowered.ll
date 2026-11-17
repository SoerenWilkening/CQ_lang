; HAND-WRITTEN. Rules: 8, 4, 5, 2.
; Checked: x (measured) in each function.
; Clean: the compare flag of each function.
; Kept: the user register x (and y in fcmp_qq).
; Rotations: fcmp_olt: Ry(th) on x; P(phi) on (x < k). fcmp_unordered: Ry(th) on x; P(phi) on NOT (x >= k), i.e. the
; `fcmp ult` flag (true for a NaN). fcmp_qq: Ry(tx) on x; Ry(ty) on y; P(phi) on (x == y).
; Three fp compares as branch flags (rule 8): a quantum-classical compare takes the literal (_hl), the quantum-quantum
; compare cq_template_fcmp_oeq_f64 takes two handles; each phase arm is the kickback cqrt_rz_i1 on its flag, and the
; flag is uncomputed by the compare's _unc and freed. The unordered predicate `ult` is kept as clang spells
; `!(x >= k)`, no rewrite to an ordered compare.
source_filename = "fcmp_phase.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fcmp_olt(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @cq_template_fcmp_olt_f64_hl(i32 %5, double %2)    ; IR: %6 = fcmp olt double %5, %2
  call void @cqrt_rz_i1(i32 %6, double %3), !cq.branchphase !6    ; IR: block %7 under br i1 %6: cq_phi(%3)
  call void @cq_template_fcmp_olt_f64_hl_unc(i32 %6, i32 %5, double %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %7 = call double @cqrt_measure_f64(i32 %5)    ; IR: %9 = cq_measure_f64(%5)
  ret double %7    ; IR: ret double %9
}

; Function Attrs: nounwind ssp uwtable
define double @fcmp_unordered(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @cq_template_fcmp_ult_f64_hl(i32 %5, double %2)    ; IR: %6 = fcmp ult double %5, %2
  call void @cqrt_rz_i1(i32 %6, double %3), !cq.branchphase !6    ; IR: block %7 under br i1 %6: cq_phi(%3)
  call void @cq_template_fcmp_ult_f64_hl_unc(i32 %6, i32 %5, double %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %7 = call double @cqrt_measure_f64(i32 %5)    ; IR: %9 = cq_measure_f64(%5)
  ret double %7    ; IR: ret double %9
}

define double @fcmp_qq(double noundef %0, double noundef %1, double noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %6 = cq_theta_f64(%0, %2)  [register]
  call void @cqrt_ry_f64(i32 %6, double %2)    ; IR: %6 = cq_theta_f64(%0, %2)  [Ry]
  %7 = call i32 @cqrt_alloc_f64(double %1)    ; IR: %7 = cq_theta_f64(%1, %3)  [register]
  call void @cqrt_ry_f64(i32 %7, double %3)    ; IR: %7 = cq_theta_f64(%1, %3)  [Ry]
  %8 = call i32 @cq_template_fcmp_oeq_f64(i32 %6, i32 %7)    ; IR: %8 = fcmp oeq double %6, %7
  call void @cqrt_rz_i1(i32 %8, double %4)    ; IR: block %9 under br i1 %8: cq_phi(%4)
  call void @cq_template_fcmp_oeq_f64_unc(i32 %8, i32 %6, i32 %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %9 = call double @cqrt_measure_f64(i32 %6)    ; IR: %11 = cq_measure_f64(%6)
  ret double %9    ; IR: ret double %11
}

declare void @cq_template_fcmp_oeq_f64_unc(i32, i32, i32)

declare i32 @cq_template_fcmp_oeq_f64(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_fcmp_olt_f64_hl(i32, double)

declare void @cqrt_not_i1(i32)

declare void @cq_template_fcmp_olt_f64_hl_unc(i32, i32, double)

declare void @cqrt_free(i32)

declare i32 @cq_template_fcmp_ult_f64_hl(i32, double)

declare void @cq_template_fcmp_ult_f64_hl_unc(i32, i32, double)

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare double @cqrt_measure_f64(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
