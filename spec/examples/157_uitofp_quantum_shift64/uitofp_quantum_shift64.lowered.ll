; HAND-WRITTEN. Rules: 4, 3, 2, 1, 5, §1.2, §2.
; Checked: each function's measured result.
; Clean: the zext rail of shl_amount_q_i64 (uncomputed and freed before the measurement).
; Kept: every rotated register (user registers, frozen) and the measured result rail.
; Rotations: Ry(tx) on x; Ry(ts) on s; Ry(ta) on a and Ry(ts) on s.
; uitofp_q: the unsigned-to-double conversion is the cast template cq_template_uitofp_i32_to_f64 (rule 3: a cast is a
; representation change, a template per width pair as in 17). shl_amount_q_i64: the BASE is classical and the AMOUNT is
; quantum, so the shift is the non-commutative _lh shape cq_template_shl_i64_lh(literal base, amount handle) (§1.2);
; -O1's zext of the i32 register to i64 is a cast template whose rail is garbage after the shift. A quantum shift amount
; is TOTALIZED MOD 64 (§2, x86 semantics): the rotated i32 may hold any value, and an amount >= 64 shifts by amount & 63.
; lshr_qq_i64: both operands quantum, the bare qq shape; the amount is again taken mod 64.
source_filename = "uitofp_quantum_shift64.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @uitofp_q(i32 noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %3, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_uitofp_i32_to_f64(i32 %3)    ; IR: %4 = uitofp i32 %3 to double  [cast template, fresh f64 rail]
  %5 = call double @cqrt_measure_f64(i32 %4)    ; IR: %5 = cq_measure_f64(%4)
  ret double %5    ; IR: ret double %5
}

define i64 @shl_amount_q_i64(i64 noundef %0, i32 noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %4 = cq_theta_ui32(%1, %2)  [register s]
  call void @cqrt_ry_i32(i32 %4, double %2)    ; IR: %4 = cq_theta_ui32(%1, %2)  [Ry]
  %5 = call i32 @cq_template_zext_i32_to_i64(i32 %4)    ; IR: %5 = zext nneg i32 %4 to i64  [cast template: the amount at i64]
  %6 = call i32 @cq_template_shl_i64_lh(i64 %0, i32 %5)    ; IR: %6 = shl i64 %0, %5  [classical base, quantum amount: _lh; amount taken mod 64 (§2)]
  call void @cq_template_zext_i32_to_i64_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %7 = call i64 @cqrt_measure_i64(i32 %6)    ; IR: %7 = cq_measure_sll(%6)
  ret i64 %7    ; IR: ret i64 %7
}

define i64 @lshr_qq_i64(i64 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %5 = cq_theta_ull(%0, %2)  [register a]
  call void @cqrt_ry_i64(i32 %5, double %2)    ; IR: %5 = cq_theta_ull(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i64(i64 %1)    ; IR: %6 = cq_theta_ull(%1, %3)  [register s]
  call void @cqrt_ry_i64(i32 %6, double %3)    ; IR: %6 = cq_theta_ull(%1, %3)  [Ry]
  %7 = call i32 @cq_template_lshr_i64(i32 %5, i32 %6)    ; IR: %7 = lshr i64 %5, %6  [qq shape; the quantum amount taken mod 64 (§2)]
  %8 = call i64 @cqrt_measure_i64(i32 %7)    ; IR: %8 = cq_measure_ull(%7)
  ret i64 %8    ; IR: ret i64 %8
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i64(i32, double)
declare i32 @cq_template_uitofp_i32_to_f64(i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_shl_i64_lh(i64, i32)
declare i32 @cq_template_lshr_i64(i32, i32)
declare void @cqrt_free(i32)
declare i64 @cqrt_measure_i64(i32)
declare double @cqrt_measure_f64(i32)
