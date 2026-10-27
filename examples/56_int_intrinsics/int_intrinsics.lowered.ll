; HAND-WRITTEN. Rules: 4, 3, 5, 2, 25.
; Checked: each function's measured result: fshl_qq %7 -> %8; rotl_qc %8 -> %9; clz_q %4 -> %5; popcount_q %6 -> %7;
; smax_qc %5 -> %6; umax_qq %7 -> %8; abs_q %4 -> %5; fptoui_q %4 -> %5; same_operand_twice %8 -> %9 (the fptrunc of the
; measured x86_fp80 is classical).
; Clean: rotl_qc's two shift rails (%5, %7); popcount_q's mask rail x & c (%5); same_operand_twice's fpext (%5) and
; product (%7), all uncomputed and freed.
; Kept: every rotated register (a, b, x, y of each function) and each function's measured result rail.
; Rotations: fshl_qq: (Ry, a, ta, 1); (Ry, b, tb, 1). rotl_qc, clz_q, popcount_q, smax_qc, abs_q: (Ry, x, th, 1).
; umax_qq: (Ry, x, tx, 1); (Ry, y, ty, 1). fptoui_q, same_operand_twice: (Ry_f64, x, th, 1).
; Each intrinsic on quantum data is one template (fshl: a three-operand template, _qql = two quantum operands and a
; classical shift literal; ctlz/ctpop/abs: unary; smax/umax: binary with the _hl literal form for a classical operand).
; A classical shift amount (32 - k) stays classical. The NaN idiom t / t reads the SAME rail in both operand slots of
; fdiv: inputs are read-only, so one rail may feed both. The widening to long double is a cast template (rule 25: f80
; is a width variant); the fptrunc after the measurement is classical. Uncompute order is dependency order (rule 5):
; rotl_qc's two shift rails both read only x, so they commute (shl's is undone first); same_operand_twice undoes the
; product before the fpext it read.
; `freeze` (LLVM 19 emits it only for poison guards, e.g. k_rem_pio2's loop exit; no plain-C input here produced one) is
; the identity on the handle: a frozen quantum value is the same rail, no gate, no new rail.
source_filename = "int_intrinsics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fshl_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register a]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register b]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_fshl_i32_qql(i32 %5, i32 %6, i32 1)    ; IR: %7 = llvm.fshl.i32(%5, %6, 1)  [result rail]
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_ui32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @rotl_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_shl_i32_hl(i32 %4, i32 %2)    ; IR: %5 = shl i32 %4, %2
  %6 = sub i32 32, %2    ; IR: %6 = sub i32 32, %2  (classical)
  %7 = call i32 @cq_template_lshr_i32_hl(i32 %4, i32 %6)    ; IR: %7 = lshr i32 %4, %6
  %8 = call i32 @cq_template_or_i32(i32 %5, i32 %7)    ; IR: %8 = or i32 %5, %7  [result rail]
  call void @cq_template_shl_i32_hl_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %7, i32 %4, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %9 = cq_measure_ui32(%8)
  ret i32 %9    ; IR: ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @clz_q(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %3, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_ctlz_i32(i32 %3)    ; IR: %4 = llvm.ctlz.i32(%3, true)  [result rail]
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_si32(%4)
  ret i32 %5    ; IR: ret i32 %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctlz.i32(i32, i1 immarg) #1

; Function Attrs: nounwind ssp uwtable
define i32 @popcount_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 %2)    ; IR: %5 = and i32 %4, %2
  %6 = call i32 @cq_template_ctpop_i32(i32 %5)    ; IR: %6 = llvm.ctpop.i32(%5)  [result rail]
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctpop.i32(i32) #1

; Function Attrs: nounwind ssp uwtable
define i32 @smax_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_smax_i32_hl(i32 %4, i32 %2)    ; IR: %5 = llvm.smax.i32(%4, %2)  [result rail]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @umax_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_umax_i32(i32 %5, i32 %6)    ; IR: %7 = llvm.umax.i32(%5, %6)  [result rail]
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_ui32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @abs_q(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %3, double %1)    ; IR: %3 = cq_theta_si32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_abs_i32(i32 %3)    ; IR: %4 = llvm.abs.i32(%3, true)  [result rail]
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_si32(%4)
  ret i32 %5    ; IR: ret i32 %5
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #1

; Function Attrs: nounwind ssp uwtable
define i32 @fptoui_q(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_fptoui_f64_to_i32(i32 %3)    ; IR: %4 = fptoui double %3 to i32  [result rail]
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_ui32(%4)
  ret i32 %5    ; IR: ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define double @same_operand_twice(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fpext_f64_to_f80(i32 %4)    ; IR: %5 = fpext double %4 to x86_fp80
  %6 = fpext double %2 to x86_fp80    ; IR: %6 = fpext double %2 to x86_fp80  (classical)
  %7 = call i32 @cq_template_fmul_f80_hl(i32 %5, x86_fp80 %6)    ; IR: %7 = fmul x86_fp80 %6, %5  (commutative: the classical operand moved to the _hl slot)
  %8 = call i32 @cq_template_fdiv_f80(i32 %7, i32 %7)    ; IR: %8 = fdiv x86_fp80 %7, %7  [the same rail in both slots; result rail]
  call void @cq_template_fmul_f80_hl_unc(i32 %7, i32 %5, x86_fp80 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fpext_f64_to_f80_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %9 = call x86_fp80 @cqrt_measure_f80(i32 %8)    ; IR: %9 = cq_measure_f80(%8)
  %10 = fptrunc x86_fp80 %9 to double    ; IR: %10 = fptrunc x86_fp80 %9 to double  (classical)
  ret double %10    ; IR: ret double %10
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #1

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare i32 @cq_template_fshl_i32_qql(i32, i32, i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_or_i32(i32, i32)

declare i32 @cq_template_ctlz_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_ctpop_i32(i32)

declare i32 @cq_template_smax_i32_hl(i32, i32)

declare i32 @cq_template_umax_i32(i32, i32)

declare i32 @cq_template_abs_i32(i32)

declare i32 @cq_template_fptoui_f64_to_i32(i32)

declare i32 @cq_template_fpext_f64_to_f80(i32)

declare i32 @cq_template_fmul_f80_hl(i32, x86_fp80)

declare i32 @cq_template_fdiv_f80(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare x86_fp80 @cqrt_measure_f80(i32)

declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_fmul_f80_hl_unc(i32, i32, x86_fp80)

declare void @cq_template_fpext_f64_to_f80_unc(i32, i32)

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
