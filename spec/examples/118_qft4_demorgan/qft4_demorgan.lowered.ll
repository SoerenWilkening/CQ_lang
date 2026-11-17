; HAND-WRITTEN. Rules: 8, 4, 2, 5.
; Checked: c0 (%2 -> %16), c1 (%3 -> %18), c2 (%4 -> %21), c3 (%5 -> %24), all measured and packed into the returned int.
; Clean: every negation rail (NOT c3 %6, NOT c1 %8, NOT c2 %10, NOT c0 %12) and every flag rail (%7, %9, %11, %13, %14,
; %15), each |0> at its free.
; Kept: the four user registers c0..c3 (measured; a measured rail stays allocated).
; Rotations: (Ry, c0, th, 1); (Ry, c1, th, 1); (Ry, c2, th, 1); (Ry, c3, th, 1); (P, c3, pi, c3); (Ry, c3, pi/2, 1);
; (P, flag, -pi/2, c3&c2); (P, c2, pi, c2); (Ry, c2, pi/2, 1); (P, flag, -pi/4, c3&c1); (P, flag, -pi/2, c2&c1);
; (P, c1, pi, c1); (Ry, c1, pi/2, 1); (P, flag, -pi/8, c3&c0); (P, flag, -pi/4, c2&c0); (P, flag, -pi/2, c1&c0);
; (P, c0, pi, c0); (Ry, c0, pi/2, 1). A middle-four control c_i&c_j is the X-bracketed flag NOT(NOT c_i | NOT c_j).
; The 4-qubit QFT^-1 written with `a && b` conditions: -O1 keeps the first and last conjunctions as
; `select i1 a, i1 b, i1 false` (the Toffoli flag of 59/60), but De-Morgans the middle four: it hoists the NEGATIONS as
; values (%9 = xor i1 %8, true = NOT c3, %16 = NOT c1, %20 = NOT c2, %27 = NOT c0 in the -O1 IR), rewrites each condition
; as `select i1 NOT a, i1 true, i1 NOT b` (= NOT(a && b)) and INVERTS the branches, so the phase block runs under the
; negated flag. Lowered as spelled:
;  - a negation value is a fresh rail: cq_template_xor_i1_hl(rail, 1) (out of place; the register is untouched);
;  - the or-select of two rails, `select i1 NOT a, i1 true, i1 NOT b` = NOT a | NOT b, is a branch flag: cqrt_or_i1 of the
;    two negation rails into a fresh |0> flag (rule 8); the phase block runs under NOT of that flag, so it is an X-bracketed
;    kickback (21, 39); the flag is re-applied (self-inverse) and freed right after;
;  - the two `select i1 a, i1 b, i1 false` conjunctions are the Toffoli flag of 59 (cqrt_and_i1), kickback, un-Toffoli;
;  - `if (q) cq_phi(pi)` on a bare register is cqrt_rz_i1 on that rail (115); cq_theta rotates the rail in place.
; A negation rail is uncomputed after its LAST use and before the next in-place gate on its operand, because the
; uncompute needs the operand's value unchanged: NOT c1 (%8) dies before c1's rotation, NOT c0 (%12) before c0's;
; NOT c3 and NOT c2 die at the end (their registers are not rotated again). Every flag is |0> at its free.
; Replayed on alg_test's sim_qpe.py: |+>^4 (th = pi/2) -> |0000> with p = 1, no ancilla left allocated.
source_filename = "qft4_demorgan.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @qft4_demorgan(double noundef %0) {
  %2 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %2 = cq_theta_i1(false, %0)  [register c0]
  call void @cqrt_ry_i1(i32 %2, double %0)    ; IR: %2 = cq_theta_i1(false, %0)  [Ry]
  %3 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %3 = cq_theta_i1(false, %0)  [register c1]
  call void @cqrt_ry_i1(i32 %3, double %0)    ; IR: %3  [Ry]
  %4 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %4 = cq_theta_i1(false, %0)  [register c2]
  call void @cqrt_ry_i1(i32 %4, double %0)    ; IR: %4  [Ry]
  %5 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %5 = cq_theta_i1(false, %0)  [register c3]
  call void @cqrt_ry_i1(i32 %5, double %0)    ; IR: %5  [Ry]
  call void @cqrt_rz_i1(i32 %5, double 0x400921FB54442D18)    ; IR: br i1 %5 -> block %6: cq_phi(pi)  [bare rail: phase on c3 itself]
  call void @cqrt_ry_i1(i32 %5, double 0x3FF921FB54442D18)    ; IR: %8 = cq_theta_i1(%5, pi/2)  [Ry in place on c3; %8 is c3's rail]
  %6 = call i32 @cq_template_xor_i1_hl(i32 %5, i1 true)    ; IR: %9 = xor i1 %8, true  [NOT c3, a fresh rail; read by %17 and %28]
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %10 = select i1 %8, i1 %4, i1 false  [flag rail for c3 && c2]
  call void @cqrt_and_i1(i32 %5, i32 %4, i32 %7)    ; IR: %10 = c3 & c2  (Toffoli into the |0> flag)
  call void @cqrt_rz_i1(i32 %7, double 0xBFF921FB54442D18)    ; IR: block %11: cq_phi(-pi/2)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %5, i32 %4, i32 %7)    ; IR: uncompute %10 (c3, c2 unchanged)
  call void @cqrt_free(i32 %7)    ; IR: release the flag (|0>)
  call void @cqrt_rz_i1(i32 %4, double 0x400921FB54442D18)    ; IR: br i1 %4 -> block %13: cq_phi(pi)  [phase on c2 itself]
  call void @cqrt_ry_i1(i32 %4, double 0x3FF921FB54442D18)    ; IR: %15 = cq_theta_i1(%4, pi/2)  [Ry in place on c2]
  %8 = call i32 @cq_template_xor_i1_hl(i32 %3, i1 true)    ; IR: %16 = xor i1 %3, true  [NOT c1; read by %17 and %21]
  %9 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %17 = select i1 %9, i1 true, i1 %16  [NOT(c3 && c1); block %18 runs under NOT %17]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %6, i32 %8, i32 %9)    ; IR: %17 = NOT a | NOT b into the flag
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket: block %18 runs under NOT %17
  call void @cqrt_rz_i1(i32 %9, double 0xBFE921FB54442D18)    ; IR: block %18: cq_phi(-pi/4)  [kickback]
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket
  call void @cqrt_or_i1(i32 %6, i32 %8, i32 %9)    ; IR: uncompute %17 (self-inverse)
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  %10 = call i32 @cq_template_xor_i1_hl(i32 %4, i1 true)    ; IR: %20 = xor i1 %15, true  [NOT c2 (after its rotation); read by %21 and %31]
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %21 = select i1 %20, i1 true, i1 %16  [NOT(c2 && c1)]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %10, i32 %8, i32 %11)    ; IR: %21 = NOT a | NOT b into the flag
  call void @cqrt_not_i1(i32 %11)    ; IR: bracket: block %22 runs under NOT %21
  call void @cqrt_rz_i1(i32 %11, double 0xBFF921FB54442D18)    ; IR: block %22: cq_phi(-pi/2)
  call void @cqrt_not_i1(i32 %11)    ; IR: bracket
  call void @cqrt_or_i1(i32 %10, i32 %8, i32 %11)    ; IR: uncompute %21 (self-inverse)
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_xor_i1_hl_unc(i32 %8, i32 %3, i1 true)    ; IR: uncompute %16 after its last use (%21), before c1 is rotated (%26)
  call void @cqrt_free(i32 %8)    ; IR: release NOT c1 (|0>)
  call void @cqrt_rz_i1(i32 %3, double 0x400921FB54442D18)    ; IR: br i1 %3 -> block %24: cq_phi(pi)  [phase on c1 itself]
  call void @cqrt_ry_i1(i32 %3, double 0x3FF921FB54442D18)    ; IR: %26 = cq_theta_i1(%3, pi/2)  [Ry in place on c1]
  %12 = call i32 @cq_template_xor_i1_hl(i32 %2, i1 true)    ; IR: %27 = xor i1 %2, true  [NOT c0; read by %28 and %31]
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %28 = select i1 %9, i1 true, i1 %27  [NOT(c3 && c0)]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %6, i32 %12, i32 %13)    ; IR: %28 = NOT a | NOT b into the flag
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket: block %29 runs under NOT %28
  call void @cqrt_rz_i1(i32 %13, double 0xBFD921FB54442D18)    ; IR: block %29: cq_phi(-pi/8)
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket
  call void @cqrt_or_i1(i32 %6, i32 %12, i32 %13)    ; IR: uncompute %28 (self-inverse)
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %31 = select i1 %20, i1 true, i1 %27  [NOT(c2 && c0)]  [fresh flag rail]
  call void @cqrt_or_i1(i32 %10, i32 %12, i32 %14)    ; IR: %31 = NOT a | NOT b into the flag
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket: block %32 runs under NOT %31
  call void @cqrt_rz_i1(i32 %14, double 0xBFE921FB54442D18)    ; IR: block %32: cq_phi(-pi/4)
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket
  call void @cqrt_or_i1(i32 %10, i32 %12, i32 %14)    ; IR: uncompute %31 (self-inverse)
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_xor_i1_hl_unc(i32 %12, i32 %2, i1 true)    ; IR: uncompute %27 after its last use (%31), before c0 is rotated (%39)
  call void @cqrt_free(i32 %12)    ; IR: release NOT c0 (|0>)
  call void @cq_template_xor_i1_hl_unc(i32 %10, i32 %4, i1 true)    ; IR: uncompute %20 (no later use; c2 unchanged)
  call void @cqrt_free(i32 %10)    ; IR: release NOT c2 (|0>)
  call void @cq_template_xor_i1_hl_unc(i32 %6, i32 %5, i1 true)    ; IR: uncompute %9 (no later use; c3 unchanged)
  call void @cqrt_free(i32 %6)    ; IR: release NOT c3 (|0>)
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %34 = select i1 %26, i1 %2, i1 false  [flag rail for c1 && c0]
  call void @cqrt_and_i1(i32 %3, i32 %2, i32 %15)    ; IR: %34 = c1 & c0  (Toffoli)
  call void @cqrt_rz_i1(i32 %15, double 0xBFF921FB54442D18)    ; IR: block %35: cq_phi(-pi/2)
  call void @cqrt_and_i1(i32 %3, i32 %2, i32 %15)    ; IR: uncompute %34
  call void @cqrt_free(i32 %15)    ; IR: release the flag (|0>)
  call void @cqrt_rz_i1(i32 %2, double 0x400921FB54442D18)    ; IR: br i1 %2 -> block %37: cq_phi(pi)  [phase on c0 itself]
  call void @cqrt_ry_i1(i32 %2, double 0x3FF921FB54442D18)    ; IR: %39 = cq_theta_i1(%2, pi/2)  [Ry in place on c0]
  %16 = call i1 @cqrt_measure_i1(i32 %2)    ; IR: %40 = cq_measure_i1(%39)
  %17 = zext i1 %16 to i32    ; IR: %41  (classical)
  %18 = call i1 @cqrt_measure_i1(i32 %3)    ; IR: %42 = cq_measure_i1(%26)
  %19 = select i1 %18, i32 2, i32 0    ; IR: %43  (classical)
  %20 = or disjoint i32 %19, %17    ; IR: %44  (classical)
  %21 = call i1 @cqrt_measure_i1(i32 %4)    ; IR: %45 = cq_measure_i1(%15)
  %22 = select i1 %21, i32 4, i32 0    ; IR: %46  (classical)
  %23 = or disjoint i32 %20, %22    ; IR: %47  (classical)
  %24 = call i1 @cqrt_measure_i1(i32 %5)    ; IR: %48 = cq_measure_i1(%8)
  %25 = select i1 %24, i32 8, i32 0    ; IR: %49  (classical)
  %26 = or disjoint i32 %23, %25    ; IR: %50  (classical)
  ret i32 %26    ; IR: ret i32 %50
}

declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_or_i1(i32, i32, i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_xor_i1_hl(i32, i1)
declare void @cq_template_xor_i1_hl_unc(i32, i32, i1)
