; HAND-WRITTEN. Rules: 10 (a flag that read the rotated register stays allocated), 8, 2.
; Checked: x (%5 -> %7).
; Clean: none: nothing is freed.
; Kept: x (%5, the rotated register) and the flag f = (x > k) (%6): it was computed from x before the controlled rotation
; changed x, so it can no longer be uncomputed and stays allocated, entangled with x.
; Rotations: (Ry, x, t1, 1); (Ry, x, t2, x > k) with the predicate read from x before this rotation.
; The condition reads the register the arm rotates: the flag f = (x > k) is computed from x BEFORE the rotation, and after
; cRy(f, x, t2) it can no longer be uncomputed from x, because x has changed. We never decline: the flag is emitted, the
; rotation is controlled by it, and the flag simply STAYS ALLOCATED, entangled with x, like a user register (its which-branch
; record dephases later interference between the two arms: that is what the program says). C principle: the compiler does
; not stop the user shooting their own foot; it emits the program as written. Compare 39, where the condition reads a
; different register and the flag is uncomputed.
source_filename = "self_conditioned_rotation.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @self_conditioned_rotation(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 %2)    ; IR: %6 = icmp sgt i32 %5, %2  [path predicate of block %7, read from x before the rotation]
  call void @cqrt_ry_i32_controlled(i32 %6, i32 %5, double %3)    ; IR: block %7: %8 = cq_theta_si32(%5, %3); %10 = phi [ %8, %7 ], [ %5, %4 ]  [Ry under the predicate, in place]
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %11 = cq_measure_si32(%10)  (%f is NOT uncomputed: x changed under it; the flag rail stays allocated)
  ret i32 %7    ; IR: ret i32 %11
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare i32 @cqrt_measure_i32(i32)
