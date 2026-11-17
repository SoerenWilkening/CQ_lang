; HAND-WRITTEN. Rules: 18, 8, 9, 12, 5.
; Checked: guard(x, lo, s, p) (measured, %7 -> %8).
; Clean: inside the clone __cq_q_guard_1000: the flag %5 = (v < lo), the product %6 = v * s and the merge select %7, all
; uncomputed LIFO and freed after the copy-out.
; Kept: x (%6, the rotated register) and the clone's result rail %7 (measured); nothing else.
; Rotations: (Ry, x, th, 1); (P, flag, p, x < lo).
; The early-return arm carries a phase: the condition's flag takes the kickback (rz_i1 inside the clone; rule 12: a
; quantum predicate is in scope), the two return values merge by one select, and the clone __cq_q_guard_1000 (mask left
; to right, §1.4) copies the result out.
source_filename = "callee_phase_early_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_phase_early_return(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call fastcc i32 @__cq_q_guard_1000(i32 %6, i32 %2, i32 %3, double %4)    ; IR: %7 = call @guard(%6, %2, %3, %4), quantum clone (arg 0 quantum)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

define internal fastcc i32 @__cq_q_guard_1000(i32 %0, i32 %1, i32 %2, double %3) {
  %5 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 %1)    ; IR: %5 = icmp slt i32 %0, %1  [path predicate of block %6]
  call void @cqrt_rz_i1(i32 %5, double %3)    ; IR: block %6: cq_phi(%3)
  %6 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 %2)    ; IR: %8 = mul nsw i32 %2, %0  (block %7; commutative: classical operand moved to the _hl slot)
  %7 = call i32 @cq_template_select_i32_lh(i32 %5, i32 %1, i32 %6)    ; IR: %10 = phi i32 [ %1, %6 ], [ %8, %7 ]
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %10  [result rail of the call]
  call void @cqrt_copy_i32(i32 %7, i32 %8)    ; IR: ret i32 %10  [copy the result out]
  call void @cq_template_select_i32_lh_unc(i32 %7, i32 %5, i32 %1, i32 %6)    ; IR: uncompute %10
  call void @cqrt_free(i32 %7)    ; IR: release the %10 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %6, i32 %0, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %6)    ; IR: release the %8 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %5, i32 %0, i32 %1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  ret i32 %8    ; IR: ret i32 %10
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
