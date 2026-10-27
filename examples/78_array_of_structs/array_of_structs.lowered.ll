; HAND-WRITTEN. Rules: 2, 4, 5, 20 (strided QROM), 26.
; Checked: p[x & 7].v + p[x & 7].k, the returned double (the fadd rail %10 -> %11).
; Clean: the index rail x & 7 (%5), the two strided QROM reads (%7 for v, %8 for k) and the sitofp of k (%9), uncomputed in
; LIFO order and freed.
; Kept: x (%4, the rotated register) and the sum (%10, measured).
; Rotations: (Ry, x, th, 1).
; An array of structs in classical memory read at a quantum index is one QROM per field read, indexed by the logical index
; rail x & 7 (i32; -O1's zext to i64 and the gep scaling are address arithmetic and are not emitted). Element i of field f
; lives at base + i * stride + offset(f), which the plain qrom_load(table, n, idx) cannot express, so the strided form
; cq_template_qrom_load_<W>_s(base, n, stride, idx) takes the base already offset to the field (p + 8 for v, p + 0 for k)
; and the struct size as the byte stride (16). n = 8 because the index is x & 7 (range [0, 8), as in example 76). -O1 reads
; v before k; the lowering keeps that order.
source_filename = "array_of_structs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @array_of_structs(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 7)    ; IR: %5 = and i32 %4, 7  [index, range [0, 8)]
  %6 = getelementptr inbounds i8, ptr %2, i64 8    ; IR: %8 = getelementptr i8, ptr %7, 8: field v at byte offset 8  (classical base)
  %7 = call i32 @cq_template_qrom_load_f64_s(ptr %6, i64 8, i64 16, i32 %5)    ; IR: %6 = zext %5; %7 = getelementptr %struct.P, ptr %2, %6; %9 = load double, ptr %8  [strided QROM, 16-byte elements, index = the logical-i32 rail %5]
  %8 = call i32 @cq_template_qrom_load_i32_s(ptr %2, i64 8, i64 16, i32 %5)    ; IR: %10 = load i32, ptr %7  [strided QROM over field k at offset 0]
  %9 = call i32 @cq_template_sitofp_i32_to_f64(i32 %8)    ; IR: %11 = sitofp i32 %10 to double
  %10 = call i32 @cq_template_fadd_f64(i32 %7, i32 %9)    ; IR: %12 = fadd double %9, %11  [result rail]
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %9, i32 %8)    ; IR: uncompute %11
  call void @cqrt_free(i32 %9)    ; IR: release the %11 rail (|0>)
  call void @cq_template_qrom_load_i32_s_unc(i32 %8, ptr %2, i64 8, i64 16, i32 %5)    ; IR: uncompute %10
  call void @cqrt_free(i32 %8)    ; IR: release the %10 rail (|0>)
  call void @cq_template_qrom_load_f64_s_unc(i32 %7, ptr %6, i64 8, i64 16, i32 %5)    ; IR: uncompute %9
  call void @cqrt_free(i32 %7)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 7)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %11 = call double @cqrt_measure_f64(i32 %10)    ; IR: %13 = cq_measure_f64(%12)
  ret double %11    ; IR: ret double %13
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_qrom_load_f64_s(ptr, i64, i64, i32)
declare void @cq_template_qrom_load_f64_s_unc(i32, ptr, i64, i64, i32)
declare i32 @cq_template_qrom_load_i32_s(ptr, i64, i64, i32)
declare void @cq_template_qrom_load_i32_s_unc(i32, ptr, i64, i64, i32)
declare i32 @cq_template_sitofp_i32_to_f64(i32)
declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
