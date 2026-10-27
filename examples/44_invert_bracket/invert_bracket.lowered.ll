; HAND-WRITTEN. Rules: 17, 8, 4, 5, 2.
; Checked: x (%6, measured as %10).
; Clean: the product y = x * c (%8) and the equality flag y == k (%9), both uncomputed inside the adjoint and freed.
; Kept: x (%6, the rotated register, measured).
; Rotations: (Ry, x, th, 1); (P, flag, -phi, x * c == k).
; The bracketed region is emitted as the ADJOINT of its body (rule 17): the gate sequence reversed with every gate
; replaced by its inverse. The compute/uncompute pairs of the product and the flag reverse into themselves (a compute
; of %8, then of %9, then the uncomputes in LIFO order), so only the phase changes sign: cq_phi(phi) becomes
; rz_i1(flag, -phi) with the negation a classical fneg. The begin/end markers are consumed.
source_filename = "invert_bracket.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @invert_bracket(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = fneg double %4    ; IR: adjoint of cq_phi(%4) is cq_phi(-%4)  (classical)
  %8 = call i32 @cq_template_mul_i32_hl(i32 %6, i32 %2)    ; IR: (adjoint, step 5 of 5 reversed) %7 = mul nsw i32 %6, %2: inverse of its own uncompute
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 %3)    ; IR: (step 4) %8 = icmp eq i32 %7, %3: inverse of its own uncompute
  call void @cqrt_rz_i1(i32 %9, double %7)    ; IR: (step 3) block %9: cq_phi(%4) inverted
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 %3)    ; IR: (step 2) inverse of computing %8
  call void @cqrt_free(i32 %9)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %8, i32 %6, i32 %2)    ; IR: (step 1) inverse of computing %7
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_si32(%6)
  ret i32 %10    ; IR: ret i32 %11
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
