; HAND-WRITTEN. Rules: 2 (three cq_theta on classical false mint |0> rails and rotate them; `cq_theta(&a, -pi/2)` and
; `cq_theta(&c, -theta)` rotate existing rails in place; the three cq_measure_i1 are measure_i1 and every dominated use of the
; measured value is classical), 4 (`b = a ^ b` is cq_template_xor_i1 OUT OF PLACE into a fresh rail, the CNOT fan-out that
; makes the Bell pair; the X correction `c ^ m1` is cq_template_xor_i1_hl out of place with the classical m1 as literal),
; 6 (the old c rail after the X correction is dead and xor is a bijection in c for fixed m1: cleaned and freed),
; 8 (`if (m2 && c)`: the classical conjunct m2 is a classical branch around the quantum part; the quantum part is the bare
; rail c, so the phase is rz_i1 on c itself), 12 (cq_phi(pi) is under the quantum predicate c: not deleted),
; 3 (`c = b ^ 0` was folded by -O1: %3 is ONE rail that is both b and c until the CNOT; after it, %4 is b and %3 stays c).
; Checked: c (the final measured rail, %7; the return value).
; Clean: the old c rail %3 (rule 6: t = c' ^ m1 recomputes it, copy_i1 zeroes it, t is uncomputed) and t (%8), both freed.
; Kept: a (%2) and b (%4), measured and therefore never freed; c (%7, the corrected rail), measured at the end. The old b
;   rail after `b = a ^ b` is NOT a dead value to clean by rule 6: it IS the register c (c = b ^ 0 == b), read by the X
;   correction. Were it dead, rule 6 would clean it right after the CNOT, before the H on a (the inverse reads a).
; Rotations: Ry(theta) on a (control 1); Ry(pi/2) on b (control 1); Ry(-pi/2) on a (control 1);
;   [after the measurements, classical control:] P(pi) on c (%7) under the classical m2 (control predicate: m2 & c, with
;   c the bare rail); Ry(-theta) on c (%7, control 1). The X correction is a basis permutation (xor_i1_hl), not a rotation.
; Expected: teleport(0.7): the final measurement is 0 with probability 1 on every one of the four (m1, m2) branches, each
;   branch having probability 1/4 (state-vector replay of the trace with scripted outcomes: fidelity 1 on 00, 01, 10, 11,
;   every cqrt_free on |0>).
; What -O1 did: `c = b ^ c` with c = 0 is c = b, so %3 (the Ry(pi/2) rail) is both names; `b = a ^ b` is `%4 = xor i1 %2, %3`;
; `if (m1) c = !c` became `%8 = xor i1 %3, %6` (c xor the measured bit); `m2 && c` became `select i1 %7, i1 %8, i1 false` with
; the cq_phi block under it; the final cq_theta reads %8. Lowering: %4 is a fresh rail, so the state after it is
; sum_a amp(a) |a>_a |a ^ b>_b' |b>_c with (b, c) the Bell pair: the textbook circuit. H on a is Ry(-pi/2) in place. Both
; Bell outcomes are classical from their measurement on. `%8 = xor i1 %3, %6` has the classical m1 as an operand, so it is
; the _hl template into a fresh rail (rule 4, no branch: m1 is the literal), and the old c rail is cleaned by rule 6.
; `%9 = m2 && c` is a classical branch on m2 around the quantum predicate c itself, under which cq_phi(pi) is rz_i1 on c
; (the bare-rail phase of 118). The recipient's Ry(-theta) is in place on c; the measurement follows.
source_filename = "teleport.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @teleport(double noundef %0) {
  %2 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %2 = cq_theta_i1(false, %0)  [register a, from |0>]
  call void @cqrt_ry_i1(i32 %2, double %0)    ; IR: %2 = cq_theta_i1(false, %0)  [Ry(theta): the state to send]
  %3 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %3 = cq_theta_i1(false, pi/2)  [register b, from |0>; also c: `c = b ^ 0` is c = b, one rail for both names until the CNOT]
  call void @cqrt_ry_i1(i32 %3, double 0x3FF921FB54442D18)    ; IR: %3 = cq_theta_i1(false, pi/2)  [Ry(pi/2) on b]
  %4 = call i32 @cq_template_xor_i1(i32 %2, i32 %3)    ; IR: %4 = xor i1 %2, %3: b = a ^ b out of place (rule 4) into a fresh rail  [register b from here on; %3 remains c: the CNOT fan-out is the Bell pair (b, c) followed by CNOT a -> b]
  call void @cqrt_ry_i1(i32 %2, double 0xBFF921FB54442D18)    ; IR: %5 = cq_theta_i1(%2, -pi/2)  [H on a: Ry(-pi/2) in place; %5 is a's rail]
  %5 = call i1 @cqrt_measure_i1(i32 %4)    ; IR: %6 = cq_measure_i1(%4)  [m1; b's rail stays allocated]
  %6 = call i1 @cqrt_measure_i1(i32 %2)    ; IR: %7 = cq_measure_i1(%5)  [m2; a's rail stays allocated]
  %7 = call i32 @cq_template_xor_i1_hl(i32 %3, i1 %5)    ; IR: %8 = xor i1 %3, %6: c ^ m1 OUT OF PLACE (rule 4) with the measured, classical m1 as the literal operand (rule 2)  [register c from here on]
  %8 = call i32 @cq_template_xor_i1_hl(i32 %7, i1 %5)    ; IR: rule 6: t = %8 ^ m1 recomputes the old c (xor is its own inverse in c for fixed m1)
  call void @cqrt_copy_i1(i32 %8, i32 %3)    ; IR: rule 6: old c ^= t: the dead %3 rail is now |0>
  call void @cq_template_xor_i1_hl_unc(i32 %8, i32 %7, i1 %5)    ; IR: uncompute t
  call void @cqrt_free(i32 %8)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %3)    ; IR: release the old c rail (|0> after the copy)
  br i1 %6, label %9, label %10    ; IR: %9 = select i1 %7, i1 %8, i1 false: the classical conjunct m2 is a classical branch (rule 8); under it the predicate is the bare rail c (%8)

9:; IR: the m2 = true edge
  call void @cqrt_rz_i1(i32 %7, double 0x400921FB54442D18)    ; IR: br i1 %9 -> block %10: cq_phi(pi) under c: Z correction, the phase on the bare rail c itself (118)
  br label %10    ; IR: br label %11

10:; IR: block %11
  %11 = fneg double %0    ; IR: %12  (classical)
  call void @cqrt_ry_i1(i32 %7, double %11)    ; IR: %13 = cq_theta_i1(%8, %12)  [Ry(-theta) in place on c: the recipient un-rotates]
  %12 = call i1 @cqrt_measure_i1(i32 %7)    ; IR: %14 = cq_measure_i1(%13)
  %13 = zext i1 %12 to i32    ; IR: %15  (classical)
  ret i32 %13    ; IR: ret i32 %15
}

declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cq_template_xor_i1_hl(i32, i1)
declare void @cq_template_xor_i1_hl_unc(i32, i32, i1)
declare void @cqrt_copy_i1(i32, i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_xor_i1(i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
