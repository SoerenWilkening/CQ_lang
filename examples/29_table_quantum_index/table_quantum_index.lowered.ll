; HAND-WRITTEN. Rules: 2, 4, 5, 20.
; Checked: v = TABLE[x & 7] (measured, %5 -> %6).
; Clean: the index rail %4 = x & 7, uncomputed and freed before the measurement.
; Kept: x (%3, the rotated register) and the QROM result rail %5 (measured); nothing else.
; Rotations: (Ry, x, th, 1).
; A constant table read with a quantum index is a QROM: the classical table is passed as a pointer literal and the
; quantum index selects the entry into a fresh rail. The index operand is the logical index rail at the width of the C
; index expression (x & 7, i32); -O1's zext to i64 and the gep scaling are address arithmetic and are not emitted
; (rule 20).
source_filename = "table_quantum_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@TABLE = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @table_quantum_index(i32 noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %3, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_and_i32_hl(i32 %3, i32 7)    ; IR: %4 = and i32 %3, 7
  %5 = call i32 @cq_template_qrom_load_i32(ptr @TABLE, i64 8, i32 %4)    ; IR: %5 = zext %4; %6 = getelementptr @TABLE, %5; %7 = load i32, ptr %6  [QROM: table literal, logical index rail %4 (the zext is address arithmetic), fresh result rail]
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %3, i32 7)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %6    ; IR: ret i32 %8
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
