; HAND-WRITTEN. Rules: 6 (witness: bijective update of a dead value, both outcomes), 3, 5, 18, 2, 4.
; Checked: x2 = f(x, y) ^ z (the final x, the x1 rail %7 after the in-place xor, measured -> %8).
; Clean: y = x0 + 1 (%5), z = x0 * c (%6) and the clone's internal rails, all freed. The clone's result x1 (%7) is not
; freed: rule 6 updates it in place into x2.
; Kept: x0 (%4, the rotated register: its composite update has no inverse, so it stays allocated, entangled with the
; result) and x2 (%7, the x1 rail, measured).
; Rotations: (Ry, x0, th, 1).
; x has three forward consumers (y, z, the call), so it is a fan-out source; it is the Ry-prepared user register.
; `x = f(x, y)` and `x ^= z` rebind the NAME x: x0 (the register) -> x1 = f(x0, y) = (y + 1) * x0 (the clone's copied-out
; result, rule 18; -O1 rewrote f's body to (b + 1) * a) -> x2 = x1 ^ z (on the x1 rail, rule 6's in-place update). Rule 6 is asked once per
; dead rail, after the rails that read it are uncomputed:
;   x1 is dead once x2 exists and x2 = x1 ^ z is a bijection in x1 for fixed z, so rule 6 applies, right after the
;   update: the plain xor with the rail z is the in-place update, ONE copy_i32(z, x1), and x2 is the x1 rail from there
;   on (no fresh rail, no inverse t, nothing freed). Nothing calls
;   the clone's _unc twin, so it is not defined (§1.4).
;   x0 is needed to uncompute z and y, so those are uncomputed first (LIFO: z, then y). Then rule 6 does NOT apply: the
;   composite update x2 = ((x0 + 2) * x0) ^ (x0 * c) is not a bijection in x0 for the other operand c (c = 0 sends x0 and
;   -2 - x0 to the same value), so no inverse exists and x0 stays allocated (garbage policy, 0): it is entangled with the
;   measured result and is never freed.
source_filename = "inplace_fanout_reassign.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @inplace_fanout_reassign(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x0]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)    ; IR: %5 = add nsw i32 %4, 1  [y]
  %6 = call i32 @cq_template_mul_i32_hl(i32 %4, i32 %2)    ; IR: %6 = mul nsw i32 %4, %2  [z]
  %7 = tail call fastcc i32 @__cq_q_f_11(i32 noundef %4, i32 noundef %5)    ; IR: %7 = call @f(%4, %5), quantum clone of f (both args quantum)  [x1]
  call void @cqrt_copy_i32(i32 %6, i32 %7)    ; IR: %8 = xor i32 %7, %6  [x2: rule 6's in-place update: x1 is dead after the xor, so x2 IS the x1 rail]
  call void @cq_template_mul_i32_hl_unc(i32 %6, i32 %4, i32 %2)    ; IR: uncompute %6 (reads x0)
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 1)    ; IR: uncompute %5 (reads x0)
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %9 = cq_measure_si32(%8); x0 (%4) stays allocated: no inverse of its composite update
  ret i32 %8    ; IR: ret i32 %9
}

define internal fastcc i32 @__cq_q_f_11(i32 noundef %0, i32 noundef %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %1, i32 1)    ; IR: %3 = add i32 %1, 1
  %4 = call i32 @cq_template_mul_i32(i32 %3, i32 %0)    ; IR: %4 = mul i32 %3, %0
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: ret i32 %4  [copy the result out]
  call void @cq_template_mul_i32_unc(i32 %4, i32 %3, i32 %0)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %1, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %5    ; IR: ret i32 %4
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
