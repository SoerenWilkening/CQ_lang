; HAND-WRITTEN. Rules: 4, 9, 5, 2.
; Checked: fpclass_d: isnan(y) + 2*isinf(y) + 4*isfinite(y) + 8*isnormal(y) for y = x * c; fpclass_f: the
; fpclassify code of x (each measured).
; Clean: every intermediate rail (compares, fabs, zext, the constant selects, the or chain, the inner merges, y).
; Kept: the user register x of each function; the result rail (measured).
; Rotations: Ry(th) on x (fpclass_d, f64); Ry(th) on x (fpclass_f, f32).
; FLOATING-POINT CLASSIFICATION. clang 19 lowers the classification builtins to what suits each: isnan to `fcmp uno`,
; isinf/isfinite to `fcmp oeq/one |y|, inf` over llvm.fabs, isnormal to the intrinsic `llvm.is.fpclass(y, mask)`
; (mask 264 = 0x108: negative normal | positive normal), and __builtin_fpclassify to a chain of branches on compares
; that -O1 leaves as a diamond chain with a four-way phi. Each compare and fabs is its ordinary template (rule 4);
; `llvm.is.fpclass.<W>(y, mask)` is the template cq_template_is_fpclass_<W>_hl(h, mask) with the classical mask (an i1
; rail; the backend tests the bits of the representation against the ten-class mask); the selects on constants are
; select_i32_ll; the phi chain of fpclass_f is the nested select of 23 (condition tree, rule 9), every compare computed
; unguarded. On Darwin the `fpclassify()` macro calls the library's `__fpclassifyf` instead: that is a lifted clone
; (34), not shown.
source_filename = "fpclass.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @fpclass_d(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fmul_f64_hl(i32 %4, double %2)    ; IR: %5 = fmul double %4, %2
  %6 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %5, double 0.000000e+00)    ; IR: %6 = fcmp uno double %5, 0.0  (isnan)
  %7 = call i32 @cq_template_zext_i1_to_i32(i32 %6)    ; IR: %7 = zext i1 %6 to i32
  %8 = call i32 @cq_template_fabs_f64(i32 %5)    ; IR: %8 = llvm.fabs.f64(%5)
  %9 = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %8, double 0x7FF0000000000000)    ; IR: %9 = fcmp oeq double %8, inf  (isinf)
  %10 = call i32 @cq_template_select_i32_ll(i32 %9, i32 2, i32 0)    ; IR: %10 = select i1 %9, i32 2, i32 0
  %11 = call i32 @cq_template_fcmp_one_f64_hl(i32 %8, double 0x7FF0000000000000)    ; IR: %11 = fcmp one double %8, inf  (isfinite)
  %12 = call i32 @cq_template_select_i32_ll(i32 %11, i32 4, i32 0)    ; IR: %12 = select i1 %11, i32 4, i32 0
  %13 = call i32 @cq_template_is_fpclass_f64_hl(i32 %5, i32 264)    ; IR: %13 = llvm.is.fpclass.f64(%5, 264)  (isnormal: mask = negative normal | positive normal)
  %14 = call i32 @cq_template_select_i32_ll(i32 %13, i32 8, i32 0)    ; IR: %14 = select i1 %13, i32 8, i32 0
  %15 = call i32 @cq_template_or_i32(i32 %14, i32 %7)    ; IR: %15 = or disjoint i32 %14, %7
  %16 = call i32 @cq_template_or_i32(i32 %15, i32 %10)    ; IR: %16 = or disjoint i32 %15, %10
  %17 = call i32 @cq_template_or_i32(i32 %16, i32 %12)    ; IR: %17 = or disjoint i32 %16, %12  [result rail]
  call void @cq_template_or_i32_unc(i32 %16, i32 %15, i32 %10)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_or_i32_unc(i32 %15, i32 %14, i32 %7)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %14, i32 %13, i32 8, i32 0)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_is_fpclass_f64_hl_unc(i32 %13, i32 %5, i32 264)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %12, i32 %11, i32 4, i32 0)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fcmp_one_f64_hl_unc(i32 %11, i32 %8, double 0x7FF0000000000000)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %10, i32 %9, i32 2, i32 0)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %9, i32 %8, double 0x7FF0000000000000)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %8, i32 %5)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %7, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %6, i32 %5, double 0.000000e+00)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %5, i32 %4, double %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %18 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %18 = cq_measure_si32(%17)
  ret i32 %18    ; IR: ret i32 %18
}

define i32 @fpclass_f(float noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_alloc_f32(float %0)    ; IR: %3 = cq_theta_f32(%0, %1)  [register x]
  call void @cqrt_ry_f32(i32 %3, double %1)    ; IR: %3 = cq_theta_f32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %3, float 0.000000e+00)    ; IR: %4 = fcmp oeq float %3, 0.0  [predicate: FP_ZERO edge of the phi]
  %5 = call i32 @cq_template_fcmp_uno_f32_hl(i32 %3, float 0.000000e+00)    ; IR: %9 = fcmp uno float %3, 0.0  (block %8, unguarded)  [FP_NAN edge]
  %6 = call i32 @cq_template_fabs_f32(i32 %3)    ; IR: %11 = llvm.fabs.f32(%3)  (block %10)
  %7 = call i32 @cq_template_fcmp_oeq_f32_hl(i32 %6, float 0x7FF0000000000000)    ; IR: %12 = fcmp oeq float %11, inf  [FP_INFINITE edge]
  %8 = call i32 @cq_template_fcmp_uge_f32_hl(i32 %6, float 0x3810000000000000)    ; IR: %14 = fcmp uge float %11, FLT_MIN  (block %13)
  %9 = call i32 @cq_template_select_i32_ll(i32 %8, i32 4, i32 5)    ; IR: %15 = select i1 %14, i32 4, i32 5  (FP_NORMAL : FP_SUBNORMAL)
  %10 = call i32 @cq_template_select_i32_lh(i32 %7, i32 2, i32 %9)    ; IR: %6 = phi: from %10 (inf) 2, else %15
  %11 = call i32 @cq_template_select_i32_lh(i32 %5, i32 1, i32 %10)    ; IR: %6 = phi: from %8 (nan) 1, else the above
  %12 = call i32 @cq_template_select_i32_lh(i32 %4, i32 3, i32 %11)    ; IR: %6 = phi [3, %2], [1, %8], [2, %10], [%15, %13]  [result rail]
  call void @cq_template_select_i32_lh_unc(i32 %11, i32 %5, i32 1, i32 %10)    ; IR: uncompute the inner merge
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %10, i32 %7, i32 2, i32 %9)    ; IR: uncompute the innermost merge
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %9, i32 %8, i32 4, i32 5)    ; IR: uncompute %15
  call void @cqrt_free(i32 %9)    ; IR: release the %15 rail (|0>)
  call void @cq_template_fcmp_uge_f32_hl_unc(i32 %8, i32 %6, float 0x3810000000000000)    ; IR: uncompute %14
  call void @cqrt_free(i32 %8)    ; IR: release the %14 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %7, i32 %6, float 0x7FF0000000000000)    ; IR: uncompute %12
  call void @cqrt_free(i32 %7)    ; IR: release the %12 rail (|0>)
  call void @cq_template_fabs_f32_unc(i32 %6, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %6)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fcmp_uno_f32_hl_unc(i32 %5, i32 %3, float 0.000000e+00)    ; IR: uncompute %9
  call void @cqrt_free(i32 %5)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fcmp_oeq_f32_hl_unc(i32 %4, i32 %3, float 0.000000e+00)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  %13 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %13    ; IR: ret i32 %7
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cqrt_alloc_f32(float)
declare void @cqrt_ry_f32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fcmp_uno_f64_hl(i32, double)
declare void @cq_template_fcmp_uno_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
declare i32 @cq_template_fabs_f64(i32)
declare void @cq_template_fabs_f64_unc(i32, i32)
declare i32 @cq_template_fcmp_oeq_f64_hl(i32, double)
declare void @cq_template_fcmp_oeq_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fcmp_one_f64_hl(i32, double)
declare void @cq_template_fcmp_one_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_is_fpclass_f64_hl(i32, i32)
declare void @cq_template_is_fpclass_f64_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_oeq_f32_hl(i32, float)
declare void @cq_template_fcmp_oeq_f32_hl_unc(i32, i32, float)
declare i32 @cq_template_fcmp_uno_f32_hl(i32, float)
declare void @cq_template_fcmp_uno_f32_hl_unc(i32, i32, float)
declare i32 @cq_template_fabs_f32(i32)
declare void @cq_template_fabs_f32_unc(i32, i32)
declare i32 @cq_template_fcmp_uge_f32_hl(i32, float)
declare void @cq_template_fcmp_uge_f32_hl_unc(i32, i32, float)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
