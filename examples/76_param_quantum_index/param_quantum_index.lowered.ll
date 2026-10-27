; HAND-WRITTEN. Rules: 2, 4, 5, 20 (QROM over a pointer parameter, length from range facts).
; Checked: param_bounded: t[x % n] (%8 -> %9). param_unbounded: t[x] (%5 -> %6).
; Clean: param_bounded: the index rail x % n (%6), uncomputed and freed. param_unbounded: nothing to free (the register is
; the index).
; Kept: the register x in each function (%5 i32 / %4 i8, rotated) and each read value (%8 / %5, measured).
; Rotations: param_bounded: (Ry, x, th, 1). param_unbounded: (Ry, x, th, 1).
; A load from a classical pointer parameter at a quantum index is a QROM over that memory (example 29), indexed by the
; logical index rail at the width of the C index expression (x % n: i32; x: the i8 register itself); -O1's zext to i64 and
; the gep scaling are address arithmetic and are not emitted. The IR carries no length for the pointer. The table length n
; is what LLVM's own range facts prove about the index: param_bounded indexes with x % n, so the index lies in [0, n) and
; the QROM gets the runtime n (a classical operand, cq_template_qrom_load_i32 already takes i64 n). param_unbounded indexes
; with a bare register: the only fact is the index width, so n = 2^W of the index (here an 8-bit register, 256 entries).
; The QROM then reads every address the index can name, including past the object: that read is the program's own
; undefined behaviour and is emitted as written (the user's foot). For a 32-bit index the same rule gives 2^32 entries.
source_filename = "param_quantum_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @param_bounded(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_urem_i32_hl(i32 %5, i32 %3)    ; IR: %6 = urem i32 %5, %3  [index, proven in [0, %3)]
  %7 = zext i32 %3 to i64    ; IR: table length from the range of %6: [0, %3)  (classical)
  %8 = call i32 @cq_template_qrom_load_i32(ptr %2, i64 %7, i32 %6)    ; IR: %7 = zext %6; %8 = getelementptr i32, ptr %2, %7; %9 = load i32, ptr %8  [QROM over %2, %n entries, index = the logical-i32 rail %6]
  call void @cq_template_urem_i32_hl_unc(i32 %6, i32 %5, i32 %3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %10 = cq_measure_si32(%9)
  ret i32 %9    ; IR: ret i32 %10
}

define i32 @param_unbounded(i8 noundef zeroext %0, double noundef %1, ptr nocapture noundef readonly %2) {
  %4 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %4 = cq_theta_ui8(%0, %1)  [register x, 8 bits]
  call void @cqrt_ry_i8(i32 %4, double %1)    ; IR: %4 = cq_theta_ui8(%0, %1)  [Ry]
  %5 = call i32 @cq_template_qrom_load_i32(ptr %2, i64 256, i32 %4)    ; IR: %5 = zext %4; %6 = getelementptr i32, ptr %2, %5; %7 = load i32, ptr %6  [QROM, 2^8 entries, index = the i8 register itself: past the object is the program's UB]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %6    ; IR: ret i32 %8
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i8(i32, double)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
