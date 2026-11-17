; HAND-WRITTEN. Rules: 6, 9, 2, 4, 5.
; Checked: c | (a' << 1) | (b' << 8) (measured).
; Clean: the two rule-6 inverse rails and the OLD a and b rails (|0> after the copies), all freed.
; Kept: none (c, a', b' are user registers).
; Rotations: (Ry, a, ta, 1); (Ry, b, tb, 1); (Ry, c, pi/2, 1); (Ry, c, -pi/2, 1).
; The swap `if (c) { t = a; a = b; b = t; }` reaches -O1 as two selects on the _Bool rail c: b' = c ? a : b (%8) and
; a' = c ? b : a (%9). Rule 9: each merge is one cq_template_select_i32 into a fresh rail; the condition is the bare i1
; rail c (rule 8). Rule 6: the pair update (a, b) -> (a', b') is a bijection (a controlled swap) and the old values are
; dead, so the old rails are cleaned BEFORE the second rotation of c: a_old = c ? b' : a' and b_old = c ? a' : b' are
; recomputed fresh from the swapped pair, copied onto the old rails (which become |0>), the two inverse rails are
; uncomputed LIFO and everything is freed. Only then is c rotated back by -pi/2: were the old rails still allocated, they
; would hold a which-way record of c and the interference that gives P(c = 0) = (1 + |<a|b>|^2) / 2 would be lost.
source_filename = "swap_test.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @swap_test(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register a]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %6 = cq_theta_si32(%2, %3)  [register b]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%2, %3)  [Ry]
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %7 = cq_theta_i1(false, pi/2)  [register c, the swap control]
  call void @cqrt_ry_i1(i32 %7, double 0x3FF921FB54442D18)    ; IR: %7 = cq_theta_i1(false, pi/2)  [Ry]
  %8 = call i32 @cq_template_select_i32(i32 %7, i32 %5, i32 %6)    ; IR: %8 = select i1 %7, i32 %5, i32 %6  [b after the swap, fresh]
  %9 = call i32 @cq_template_select_i32(i32 %7, i32 %6, i32 %5)    ; IR: %9 = select i1 %7, i32 %6, i32 %5  [a after the swap, fresh]
  %10 = call i32 @cq_template_select_i32(i32 %7, i32 %8, i32 %9)    ; IR: rule 6: the old a = c ? %8 : %9, recomputed from the swapped pair (fresh)
  call void @cqrt_copy_i32(i32 %10, i32 %5)    ; IR: rule 6: a_old ^= ta: the dead a rail is now |0>
  %11 = call i32 @cq_template_select_i32(i32 %7, i32 %9, i32 %8)    ; IR: rule 6: the old b = c ? %9 : %8 (fresh)
  call void @cqrt_copy_i32(i32 %11, i32 %6)    ; IR: rule 6: b_old ^= tb: the dead b rail is now |0>
  call void @cq_template_select_i32_unc(i32 %11, i32 %7, i32 %9, i32 %8)    ; IR: uncompute tb
  call void @cqrt_free(i32 %11)    ; IR: release tb (|0>)
  call void @cq_template_select_i32_unc(i32 %10, i32 %7, i32 %8, i32 %9)    ; IR: uncompute ta
  call void @cqrt_free(i32 %10)    ; IR: release ta (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the old a rail (|0> after the copy)
  call void @cqrt_free(i32 %6)    ; IR: release the old b rail (|0> after the copy)
  call void @cqrt_ry_i1(i32 %7, double 0xBFF921FB54442D18)    ; IR: %10 = cq_theta_i1(%7, -pi/2)  [Ry in place on c; no record of the pre-swap values survives]
  %12 = call i1 @cqrt_measure_i1(i32 %7)    ; IR: %11 = cq_measure_i1(%10)
  %13 = zext i1 %12 to i32    ; IR: %12 = zext i1 %11 to i32  (classical)
  %14 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %13 = cq_measure_si32(%9)
  %15 = shl i32 %14, 1    ; IR: %14 = shl i32 %13, 1  (classical)
  %16 = or disjoint i32 %15, %13    ; IR: %15 = or disjoint i32 %14, %12  (classical)
  %17 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %16 = cq_measure_si32(%8)
  %18 = shl i32 %17, 8    ; IR: %17 = shl i32 %16, 8  (classical)
  %19 = or i32 %16, %18    ; IR: %18 = or i32 %15, %17  (classical)
  ret i32 %19    ; IR: ret i32 %18
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
