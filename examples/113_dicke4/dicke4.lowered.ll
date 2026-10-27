; HAND-WRITTEN. Rules: 4 (every `t ^= c` is cq_template_xor_i1 into a fresh rail: no in-place CNOT on a user register),
; 6 (the dead old rail of each such update is cleaned by the bijection t_old = t_new ^ c: compute it fresh, cqrt_copy_i1
; it out, uncompute, free), 10 (CRy / CCRy are cqrt_ry_i1_controlled on the register's current rail; the rotated rail is
; frozen), 5, 2, 3.
; Checked: q1 (%14 -> %20), q2 (its final rail %18 -> %22), q3 (its final rail %16 -> %25), q4 (%4 -> %28): the four
; measured rails, q1 in bit 0 of the returned int.
; Clean: q2's two superseded rails (%3, %15) and q3's superseded rail (%8), the CCRy flag chain (zext %7, select %9, or
; %10, icmp %11) and the rule-6 temporaries (%17, %19), all uncomputed and freed.
; Kept: none beyond the four measured registers.
; Rotations: (Ry, q2, 2*acos(sqrt(1/2)), 1); (Ry, q2, 2*acos(sqrt(1/3)), NOT q2_old) with q2_old = q2 before this gate
; (the rail %4 = q3 = q4 of the source); (Ry, q1, 2*acos(sqrt(2/3)), 2*(q2 ^ NOT q2_old) + q2 == 3); (Ry, q1,
; 2*acos(sqrt(1/2)), q1_old ^ q2) (q2 ^= q1 of SCS_{2,1}; q1_old = q1 before this gate).
; Bärtschi–Eidenbenz |D^4_2> written as plain C: CNOT = `t ^= c`, CRy = `if (c) cq_theta(&t, a)`, CCRy = `s = 2*a + b;
; if (s == 3) cq_theta(&t, a)`. What -O1 did to the circuit (read the ; C: comments): the whole SCS_{4,2} prefix is
; classical except its CCRy, which became an unconditional Ry on q2 (`cq_theta_i1(false, θ)`, q2's register minted from
; |0>); its CRy is gone (control q4 == 0 classically); `q4 ^= q2` and SCS_{3,2}'s `q3 ^= q2` are the same value
; `%4 = xor i1 %3, true` (CSE); SCS_{3,2}'s CRy `if (q3)` is spelled as the inverted branch on q2 itself; `q3 ^= q1` with
; q1 == 0 is folded; and the second `q3 ^= q1` (`%32`) is placed after SCS_{2,1}'s rotation of q1 although it reads q1's
; earlier value `%22`.
; The lowering: `%4` is ONE SSA value, so it is ONE rail (cq_template_xor_i1_hl(q2, true) = NOT q2, fresh): it is q4 (measured
; at the end) and also the operand of `%12`. The inverted branch on `%3` rotates q2 under the flag NOT %3, which is the value
; `%4`, already a rail: cqrt_ry_i1_controlled(%4, q2). Every later `t ^= c` (`%12`, `%24`, `%32`, `%34`) is out of place into a
; fresh rail that becomes the register's current rail; `%32` reads q1's value before `%27` rotates q1, so it is emitted before
; that rotation. Garbage: `%12` (q3 before `q3 ^= q1`) is uncomputed by its own _unc after its last consumer `%32` (its
; operands q2 and `%4` are unchanged since); q2's old rail after `%24` and `%24` after `%34` are dead values of a bijective
; update (rule 6) and are cleaned by the inverse xor, which also holds after the rotations in between (the identity
; t_old = t_new ^ c is a basis identity that the Ry on q1 does not disturb, since it was computed after it). The CCRy
; flag chain (zext, select, or, icmp) is strict Bennett: fresh rails, the controlled Ry on q1 (fresh |0>), then uncomputed
; and freed before the xors that change its operands.
; Rotation list (gate, target, angle, control), identical before and after the out-of-place rewrite up to rail renaming:
;   Ry   q2  2*acos(sqrt(1/2))  1
;   Ry   q2  2*acos(sqrt(1/3))  NOT q2_old            (q2_old = q2 before this gate; the rail %4 = q3 = q4 of the source)
;   Ry   q1  2*acos(sqrt(2/3))  2*(q2 ^ NOT q2_old) + q2 == 3
;   Ry   q1  2*acos(sqrt(1/2))  q1_old ^ q2            (q2 ^= q1 of SCS_{2,1}; q1_old = q1 before this gate)
; The in-place form had the same four rotations on the same registers (q2's rail was never renamed there; q3 and q4 were
; two rails of one value). At the end exactly the four registers are allocated and the state is the six weight-2 strings
; with amplitude 1/sqrt(6) (replayed on a state vector; the measurements are the user's).
source_filename = "dicke4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @dicke4() {
  %1 = call double @llvm.acos.f64(double 0x3FE6A09E667F3BCD)    ; IR: %1 = acos(sqrt(1/2))  (classical)
  %2 = fmul double %1, 2.000000e+00    ; IR: %2 = 2 * %1  (classical: the angle of SCS_{4,2}'s CCRy and of SCS_{2,1}'s CRy)
  %3 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %3 = cq_theta_i1(false, %2)  [register q2, from |0>]
  call void @cqrt_ry_i1(i32 %3, double %2)    ; IR: %3 = cq_theta_i1(false, %2)  [Ry: SCS_{4,2}'s CCRy, its condition classically true]
  %4 = call i32 @cq_template_xor_i1_hl(i32 %3, i1 true)    ; IR: %4 = xor i1 %3, true: q4 ^= q2 and (CSE) q3 ^= q2, both with the classical 1: ONE fresh rail = NOT q2  [register q4; also q3 until %12]
  %5 = call double @llvm.acos.f64(double 0x3FE279A74590331C)    ; IR: %6 = acos(sqrt(1/3))  (classical)
  %6 = fmul double %5, 2.000000e+00    ; IR: %7  (classical)
  call void @cqrt_ry_i1_controlled(i32 %4, i32 %3, double %6)    ; IR: br i1 %3 (inverted) -> block %5: %8 = cq_theta_i1(%3, %7): q2 rotated under the flag NOT %3, which is the value %4 (a rail already); %10 = phi: q2's rail  [CRy(q3 -> q2)]
  %7 = call i32 @cq_template_zext_i1_to_i32(i32 %3)    ; IR: %11 = zext i1 %10 to i32
  %8 = call i32 @cq_template_xor_i1(i32 %3, i32 %4)    ; IR: %12 = xor i1 %10, %4: q3 ^= q2, out of place into a fresh rail  [q3's rail until %32]
  %9 = call i32 @cq_template_select_i32_ll(i32 %8, i32 2, i32 0)    ; IR: %13 = select i1 %12, i32 2, i32 0
  %10 = call i32 @cq_template_or_i32(i32 %9, i32 %7)    ; IR: %14 = or disjoint i32 %13, %11
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 3)    ; IR: %15 = icmp eq i32 %14, 3  [the CCRy flag: q3 && q2]
  %12 = call double @llvm.acos.f64(double 0x3FEA20BD700C2C3E)    ; IR: %17 = acos(sqrt(2/3))  (classical)
  %13 = fmul double %12, 2.000000e+00    ; IR: %18  (classical)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: block %16: %19 = cq_theta_i1(false, %18); %22 = phi i8 [%20, %16], [0, %9]: q1 is |0> on both paths  [register q1]
  call void @cqrt_ry_i1_controlled(i32 %11, i32 %14, double %13)    ; IR: br i1 %15 -> %19  [CCRy on q1 under the flag]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %10, i32 3)    ; IR: uncompute %15
  call void @cqrt_free(i32 %11)    ; IR: release the %15 rail (|0>)
  call void @cq_template_or_i32_unc(i32 %10, i32 %9, i32 %7)    ; IR: uncompute %14
  call void @cqrt_free(i32 %10)    ; IR: release the %14 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %9, i32 %8, i32 2, i32 0)    ; IR: uncompute %13
  call void @cqrt_free(i32 %9)    ; IR: release the %13 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %7, i32 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %7)    ; IR: release the %11 rail (|0>)
  %15 = call i32 @cq_template_xor_i1(i32 %14, i32 %3)    ; IR: %24 = icmp ne i8 %22, %23: q2 ^= q1, out of place into a fresh rail  [q2's rail until %34]
  %16 = call i32 @cq_template_xor_i1(i32 %14, i32 %8)    ; IR: %32 = icmp ne i8 %22, %31: q3 ^= q1, out of place; it reads q1's value %22 before %27 rotates q1, so it is emitted here  [register q3, final]
  call void @cq_template_xor_i1_unc(i32 %8, i32 %3, i32 %4)    ; IR: uncompute %12 after its last consumer %32 (its operands %10 and %4 are unchanged since)
  call void @cqrt_free(i32 %8)    ; IR: release the %12 rail (|0>)
  %17 = call i32 @cq_template_xor_i1(i32 %15, i32 %14)    ; IR: rule 6: q2's old rail (%10) is dead after %24 and %24 = %22 ^ %10 is a bijection in %10: t = %24 ^ %22 = its value
  call void @cqrt_copy_i1(i32 %17, i32 %3)    ; IR: rule 6: q2's old rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %17, i32 %15, i32 %14)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %17)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %3)    ; IR: release q2's old rail (|0>)
  call void @cqrt_ry_i1_controlled(i32 %15, i32 %14, double %2)    ; IR: br i1 %24 -> block %25: %27 = cq_theta_i1(%26, %2): the condition is q2's rail %24; %30 = phi: q1's rail  [CRy(q2 -> q1)]
  %18 = call i32 @cq_template_xor_i1(i32 %15, i32 %14)    ; IR: %34 = xor i1 %24, %33: q2 ^= q1, out of place  [register q2, final]
  %19 = call i32 @cq_template_xor_i1(i32 %18, i32 %14)    ; IR: rule 6: %24 is dead after %34 and %34 = %24 ^ %33 is a bijection in %24: t = %34 ^ %33 = its value (a basis identity; the Ry on q1 preceded %34)
  call void @cqrt_copy_i1(i32 %19, i32 %15)    ; IR: rule 6: the %24 rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %19, i32 %18, i32 %14)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %19)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %15)    ; IR: release the %24 rail (|0>)
  %20 = call i1 @cqrt_measure_i1(i32 %14)    ; IR: %35 = cq_measure_i1(%33)
  %21 = zext i1 %20 to i32    ; IR: %36  (classical)
  %22 = call i1 @cqrt_measure_i1(i32 %18)    ; IR: %37 = cq_measure_i1(%34)
  %23 = select i1 %22, i32 2, i32 0    ; IR: %38  (classical)
  %24 = or disjoint i32 %23, %21    ; IR: %39  (classical)
  %25 = call i1 @cqrt_measure_i1(i32 %16)    ; IR: %40 = cq_measure_i1(%32)
  %26 = select i1 %25, i32 4, i32 0    ; IR: %41  (classical)
  %27 = or disjoint i32 %24, %26    ; IR: %42  (classical)
  %28 = call i1 @cqrt_measure_i1(i32 %4)    ; IR: %43 = cq_measure_i1(%4)
  %29 = select i1 %28, i32 8, i32 0    ; IR: %44  (classical)
  %30 = or disjoint i32 %27, %29    ; IR: %45  (classical)
  ret i32 %30    ; IR: ret i32 %45
}

declare double @llvm.acos.f64(double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_copy_i1(i32, i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_xor_i1_hl(i32, i1)
declare i32 @cq_template_xor_i1(i32, i32)
declare void @cq_template_xor_i1_unc(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
