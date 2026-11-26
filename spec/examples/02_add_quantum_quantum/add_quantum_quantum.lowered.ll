; HAND-WRITTEN. Rules: 4, 2, 1, 6.
; Checked: z = x + y (measured).
; Clean: nothing to free: y's rail is z's from the add on.
; Kept: x (%5, operand 1 of the add, read by the gate) and z (%6, the y rail; measured).
; Rotations: Ry(tx) on x; Ry(ty) on y.
; Both operands of the add are quantum registers. Both are dead after the add; it is a bijection in each for the other
; fixed, so rule 6's in-place update applies to operand 0 of the IR add (y): the add is ONE core gate, add_i32(x, y), on
; the y rail, and z is that rail from there on (no template, no fresh rail, no clean-up, no free). x is kept: it is the
; gate's other operand. The result rail is measured directly.
source_filename = "add_quantum_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @add_quantum_quantum(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_si32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%1, %3)  [Ry]
  call void @cqrt_add_i32(i32 %5, i32 %6)    ; IR: %7 = add nsw i32 %6, %5  [rule 6, in-place update: y is dead after the add, so z IS the y rail: y += x]
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %7    ; IR: ret i32 %8
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_add_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
