; HAND-WRITTEN. Rules: 2, 4, 8, 5.
; Checked: y' = y + (mx > k ? mx : 0) (%12, measured as %14); mx = x (%7, measured as %8) feeds the classical select.
; Clean: the equality flag y' == k (%13), uncomputed after its kickback and freed.
; Kept: x (%7, measured), y (%9, the rotated register, a source of y') and y' (%12, measured).
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1); (P, flag, phi, y' == k).
; A measurement result is an ordinary classical value afterwards: the compare mx > k and the select stay classical SSA
; and feed the quantum add as a literal (the _hl template, rule 4), so y + mx is computed into a fresh rail, never in
; place on the user register. The phase arm `if (y == k) cq_phi(phi)` is a flag rail from the compare template and one
; rz_i1 kickback on it (rule 8); the flag is uncomputed right after its last controlled gate.
source_filename = "measure_then_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @measure_then_quantum(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %2)    ; IR: %7 = cq_theta_si32(%0, %2)  [Ry]
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  %9 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %9 = cq_theta_si32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %9, double %3)    ; IR: %9 = cq_theta_si32(%1, %3)  [Ry]
  %10 = icmp sgt i32 %8, %4    ; IR: %10 = icmp sgt i32 %8, %4  (classical)
  %11 = select i1 %10, i32 %8, i32 0    ; IR: %11 = select i1 %10, i32 %8, i32 0  (classical)
  %12 = call i32 @cq_template_add_i32_hl(i32 %9, i32 %11)    ; IR: %12 = add nsw i32 %11, %9  (commutative: classical operand in the _hl slot)
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 %4)    ; IR: %13 = icmp eq i32 %12, %4
  call void @cqrt_rz_i1(i32 %13, double %5)    ; IR: block %14 under br i1 %13: cq_phi(%5)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 %4)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  %14 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %16 = cq_measure_si32(%12)
  ret i32 %14    ; IR: ret i32 %16
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
