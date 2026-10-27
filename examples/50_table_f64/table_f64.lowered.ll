; HAND-WRITTEN. Rules: 2, 3, 4, 5, 20.
; Checked: r = x * c + HALF[sb] (%9, measured as %10).
; Clean: the bitcast of x (%5), the sign-bit index lshr (%6), the QROM load (%7) and the product rail x * c (%8), all
; uncomputed and freed.
; Kept: x (%4, the rotated register, a source of r) and r (%9, measured).
; Rotations: (Ry_f64, x, th, 1).
; A constant table of doubles read with a quantum index is a QROM over the classical table, the f64 width of 29's
; cq_template_qrom_load_<W>(ptr table, i64 n, idx). The index operand is the logical index rail (rule 20): the C index
; expression is sb = (unsigned)(bits >> 63); -O1 folds its trunc/zext pair into the i64 shift itself, so the rail is the
; lshr result and no cast and no gep scaling is emitted. The fmuladd that consumes the loaded entry is UNFUSED (§2, cf.
; 14): fmul_f64_hl of x and the literal c into a fresh product rail, then fadd_f64 of the product and the loaded entry
; (its quantum addend) into the result rail; the product rail is uncomputed by its fmul _unc and freed (rule 5).
source_filename = "table_f64.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@HALF = internal unnamed_addr constant [2 x double] [double 5.000000e-01, double -5.000000e-01], align 16    ; IR: @HALF: the classical table

define double @table_f64(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %4, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %5 = call i32 @cq_template_bitcast_f64_to_i64(i32 %4)    ; IR: %5 = bitcast double %4 to i64
  %6 = call i32 @cq_template_lshr_i64_hl(i32 %5, i64 63)    ; IR: %6 = lshr i64 %5, 63  [quantum index]
  %7 = call i32 @cq_template_qrom_load_f64(ptr @HALF, i64 2, i32 %6)    ; IR: %7 = getelementptr @HALF, %6; %8 = load double, ptr %7  [QROM: table literal, quantum index, fresh rail]
  %8 = call i32 @cq_template_fmul_f64_hl(i32 %4, double %2)    ; IR: %9 = llvm.fmuladd.f64(%4, %2, %8)  [product x * c]
  %9 = call i32 @cq_template_fadd_f64(i32 %8, i32 %7)    ; IR: %9 = llvm.fmuladd.f64(%4, %2, %8)  [sum + HALF[sb], result rail]
  call void @cq_template_fmul_f64_hl_unc(i32 %8, i32 %4, double %2)    ; IR: uncompute the %9 product
  call void @cqrt_free(i32 %8)    ; IR: release the product rail (|0>)
  call void @cq_template_qrom_load_f64_unc(i32 %7, ptr @HALF, i64 2, i32 %6)    ; IR: uncompute %8
  call void @cqrt_free(i32 %7)    ; IR: release the %8 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %6, i32 %5, i64 63)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %10 = call double @cqrt_measure_f64(i32 %9)    ; IR: %10 = cq_measure_f64(%9)
  ret double %10    ; IR: ret double %10
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_qrom_load_f64(ptr, i64, i32)
declare void @cq_template_qrom_load_f64_unc(i32, ptr, i64, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
