; HAND-WRITTEN. Rules: 4, 2, 1, 6.
; Checked: z = x + y (measured).
; Clean: the old y rail (%6, rule 6: |0> after the copy) and the inverse t = z - x (%8), both freed.
; Kept: x (%5, a source of z with no inverse once y is gone) and z (%7, measured).
; Rotations: Ry(tx) on x; Ry(ty) on y.
; Both operands of the add are quantum registers, so the add is out of place: cq_template_add_i32 computes x + y into
; a fresh rail (rule 4) and neither register is rewritten. Both registers are dead after the add; it is a bijection in
; each for the other fixed, so rule 6 cleans operand 0 of the IR add (y: t = z - x) and keeps x (its inverse would read
; the rail just cleaned). The result rail is measured directly.
source_filename = "add_quantum_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @add_quantum_quantum(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_si32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_add_i32(i32 %6, i32 %5)    ; IR: %7 = add nsw i32 %6, %5
  %8 = call i32 @cq_template_sub_i32(i32 %7, i32 %5)    ; IR: rule 6: t = z - x recomputes the old y (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %8, i32 %6)    ; IR: rule 6: y ^= t: the dead y rail is now |0>
  call void @cq_template_sub_i32_unc(i32 %8, i32 %7, i32 %5)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %8)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %6)    ; IR: release the old y rail (|0> after the copy)
  %9 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %9    ; IR: ret i32 %8
}

declare void @cqrt_free(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_sub_i32_unc(i32, i32, i32)

declare i32 @cq_template_sub_i32(i32, i32)

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
