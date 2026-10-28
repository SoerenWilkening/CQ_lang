; HAND-WRITTEN. Rules: 1, 2, 4, 6.
; Checked: fadd_qc's x + c (%5 -> %6), fsub_qq's x - y (%7 -> %8), fmul_qq's x * y (%7 -> %8), fdiv_cq's c / x
; (%5 -> %6), fneg_q's -x (%4 -> %6), each the function's measured return.
; Clean: fneg_q: the old x rail (%3, rule 6: |0> after the copy) and t = -(-x) (%5), both freed.
; Kept: the rotated f64 register(s) of the other functions (FP arithmetic has no inverse) and every measured result rail.
; Rotations: (Ry, x, th, 1) in fadd_qc, fdiv_cq and fneg_q; (Ry, x, tx, 1); (Ry, y, ty, 1) in fsub_qq and fmul_qq.
; Floating-point arithmetic on a quantum double is the f64 width variant of rule 4: each tainted fadd/fsub/fmul/fdiv/fneg
; is one cq_template_<op>_f64 into a fresh rail. A classical operand is a literal: the handle-first form is _hl (x + c)
; and the classical-first form is _lh (c / x, where the order is not commutative); a quantum-quantum op takes two handles.
; The measurement is the sink. fneg is a bijection (a sign-bit flip, NaN included), so in fneg_q the dead x is cleaned by
; rule 6; the rounding ops keep their registers.
source_filename = "fp_arith.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @fadd_qc(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fadd_f64_hl(i32 %4, double %2)    ; IR: %5 = fadd double %4, %2
  %6 = call double @cqrt_measure_f64(i32 %5)    ; IR: %6 = cq_measure_f64(%5)
  ret double %6    ; IR: ret double %6
}

; Function Attrs: nounwind ssp uwtable
define double @fsub_qq(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %2)  [register]
  call void @cqrt_ry_f64(i32 %5, double %2)    ; IR: %5 = cq_theta_f64(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_f64(double %1)    ; IR: %6 = cq_theta_f64(%1, %3)  [register]
  call void @cqrt_ry_f64(i32 %6, double %3)    ; IR: %6 = cq_theta_f64(%1, %3)  [Ry]
  %7 = call i32 @cq_template_fsub_f64(i32 %5, i32 %6)    ; IR: %7 = fsub double %5, %6
  %8 = call double @cqrt_measure_f64(i32 %7)    ; IR: %8 = cq_measure_f64(%7)
  ret double %8    ; IR: ret double %8
}

; Function Attrs: nounwind ssp uwtable
define double @fmul_qq(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %2)  [register]
  call void @cqrt_ry_f64(i32 %5, double %2)    ; IR: %5 = cq_theta_f64(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_f64(double %1)    ; IR: %6 = cq_theta_f64(%1, %3)  [register]
  call void @cqrt_ry_f64(i32 %6, double %3)    ; IR: %6 = cq_theta_f64(%1, %3)  [Ry]
  %7 = call i32 @cq_template_fmul_f64(i32 %5, i32 %6)    ; IR: %7 = fmul double %5, %6
  %8 = call double @cqrt_measure_f64(i32 %7)    ; IR: %8 = cq_measure_f64(%7)
  ret double %8    ; IR: ret double %8
}

; Function Attrs: nounwind ssp uwtable
define double @fdiv_cq(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fdiv_f64_lh(double %2, i32 %4)    ; IR: %5 = fdiv double %2, %4
  %6 = call double @cqrt_measure_f64(i32 %5)    ; IR: %6 = cq_measure_f64(%5)
  ret double %6    ; IR: ret double %6
}

; Function Attrs: nounwind ssp uwtable
define double @fneg_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_fneg_f64(i32 %3)    ; IR: %4 = fneg double %3
  %5 = call i32 @cq_template_fneg_f64(i32 %4)    ; IR: rule 6: t = -(-x) recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_f64(i32 %5, i32 %3)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_fneg_f64_unc(i32 %5, i32 %4)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %5)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %3)    ; IR: release the old x rail (|0> after the copy)
  %6 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %6    ; IR: ret double %5
}

declare void @cqrt_free(i32)

declare void @cqrt_copy_f64(i32, i32)

declare void @cq_template_fneg_f64_unc(i32, i32)

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare i32 @cq_template_fadd_f64_hl(i32, double)

declare i32 @cq_template_fsub_f64(i32, i32)

declare i32 @cq_template_fmul_f64(i32, i32)

declare i32 @cq_template_fdiv_f64_lh(double, i32)

declare i32 @cq_template_fneg_f64(i32)

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
