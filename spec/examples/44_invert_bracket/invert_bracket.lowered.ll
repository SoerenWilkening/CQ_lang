; HAND-WRITTEN. Rules: 17, 8, 4, 5, 2, §1.3.
; Checked: x (%6, measured as %9).
; Clean: the product y = x * c (%7) and the equality flag y == k (%8), uncomputed and freed inside the region.
; Kept: x (%6, the rotated register, measured).
; Rotations: (Ry, x, th, 1); then, as the backend emits the region: (P, flag, -phi, x * c == k).
; The bracketed region is lowered exactly as it would be anywhere else and sits between cqrt_invert_begin() and
; cqrt_invert_end() (rule 17, §1.3): the backend, which builds the circuit as this program runs (§0), emits the gates it
; recorded between the two calls reversed with each gate inverted. Here the recorded list is [y = mul; f = icmp;
; P(f, phi); unc f; unc y] with the two frees after it (a free is not a gate and is performed after the reversed list),
; so the emitted circuit is [unc y (= compute y); unc f (= compute f); P(f, -phi); f's uncompute; y's uncompute; free f;
; free y]: the compute/uncompute pairs reverse into themselves and only the phase changes sign. The compiler negates
; nothing and reverses nothing; the markers' asm fences are consumed. Regenerated 2026-11-02 (the first version
; constructed the adjoint at compile time).
source_filename = "invert_bracket.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @invert_bracket(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); its asm fence is consumed (rule 17)
  %7 = call i32 @cq_template_mul_i32_hl(i32 %6, i32 %2)    ; IR: %7 = mul nsw i32 %6, %2
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 %3)    ; IR: %8 = icmp eq i32 %7, %3  [path predicate of block %9]
  call void @cqrt_rz_i1(i32 %8, double %4)    ; IR: block %9: cq_phi(%4)  (kickback on the flag)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %7, i32 %6, i32 %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cqrt_invert_end()    ; IR: call @__cq_invert_end(); fence consumed: the backend now emits the recorded gates reversed and inverted
  %9 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_si32(%6)
  ret i32 %9    ; IR: ret i32 %11
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_invert_begin()
declare void @cqrt_invert_end()
declare void @cqrt_rz_i1(i32, double)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
