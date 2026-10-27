; HAND-WRITTEN. Rules: 6 (witness: bijective update of a dead value), 8, 9, 10, 2, 4, 5.
; Checked: y' (the merged result %14 -> %18), r (%15 -> %19) and x (%10 -> %21), measured and summed.
; Clean: the arm rail y + 1 (%13), the rule-6 inverse chain (y' - 1 %16, t %17), the OLD y rail (%11, |0> after the
; copy) and the flag f = (x > k) (%12), all freed.
; Kept: x (%10, rotated user register), r (%15, rotated under f, frozen) and y' (%14, measured).
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1); (P, f, a, x > k); (P, f, b, NOT (x > k)); (Ry, r, t, x > k).
; One then-arm carries three arm classes at once, and each keeps its own method over ONE flag f = (x > k): the phase
; cq_phi(a) is kickback on f and cq_phi(b) kickback on NOT f (X-bracketed); the value y += 1 is computed unconditionally
; into a fresh rail and merged by a select into a fresh |0> result rail y' (never in place on y: the else value is y
; itself); the rotation of r is an in-place cqrt_ry_i32_controlled on f (r starts as the classical %5 in both arms, so it
; is a fresh register, then frozen). None of the three may borrow another's method: a basis copy of the phase arm would
; drop the phase, a phase on y would not change its label, a select merge of the rotated r would copy a label of an Ry
; superposition.
; Rule 6: after the merge y' = f ? y + 1 : y the old y rail is dead and the update is a bijection in y for fixed f, so
; the old rail is cleaned instead of leaked: the inverse t = f ? y' - 1 : y' recomputes y into a fresh rail, copy_i32(t,
; y_old) zeroes y_old, t and its chain are uncomputed, y_old is freed. The arm rail y + 1 is uncomputed first (it reads
; y_old); the flag is uncomputed last, after every gate it controls, including the cleanup select.
source_filename = "mixed_phase_value_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @mixed_phase_value_arm(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5, double noundef %6, double noundef %7, double noundef %8) {
  %10 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %10 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %10, double %1)    ; IR: %10 = cq_theta_si32(%0, %1)  [Ry]
  %11 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %11 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %11, double %3)    ; IR: %11 = cq_theta_si32(%2, %3)  [Ry]
  %12 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %10, i32 %4)    ; IR: %12 = icmp sgt i32 %10, %4  [path predicate of %13; its negation is the predicate of %16]
  call void @cqrt_rz_i1(i32 %12, double %6)    ; IR: block %13: cq_phi(%6)  [phase arm: kickback on f]
  call void @cqrt_not_i1(i32 %12)    ; IR: bracket: block %16 runs under NOT %12
  call void @cqrt_rz_i1(i32 %12, double %7)    ; IR: block %16: cq_phi(%7)
  call void @cqrt_not_i1(i32 %12)    ; IR: bracket
  %13 = call i32 @cq_template_add_i32_hl(i32 %11, i32 1)    ; IR: block %13: %14 = add nsw i32 %11, 1  (pure: computed unconditionally)
  %14 = call i32 @cq_template_select_i32(i32 %12, i32 %13, i32 %11)    ; IR: %18 = phi i32 [ %14, %13 ], [ %11, %16 ]  [value merge into a fresh result rail]
  %15 = call i32 @cqrt_alloc_i32(i32 %5)    ; IR: %19 = phi i32 [ %15, %13 ], [ %5, %16 ]  [register r, starts as %5 in both arms]
  call void @cqrt_ry_i32_controlled(i32 %12, i32 %15, double %8)    ; IR: block %13: %15 = cq_theta_si32(%5, %8)  [Ry under f]
  call void @cq_template_add_i32_hl_unc(i32 %13, i32 %11, i32 1)    ; IR: uncompute %14
  call void @cqrt_free(i32 %13)    ; IR: release the %14 rail (|0>)
  %16 = call i32 @cq_template_sub_i32_hl(i32 %14, i32 1)    ; IR: rule 6: y' - 1 (fresh)
  %17 = call i32 @cq_template_select_i32(i32 %12, i32 %16, i32 %14)    ; IR: rule 6: t = f ? y' - 1 : y' = the old y, recomputed from y'
  call void @cqrt_copy_i32(i32 %17, i32 %11)    ; IR: rule 6: y_old ^= t: the dead y rail is now |0>
  call void @cq_template_select_i32_unc(i32 %17, i32 %12, i32 %16, i32 %14)    ; IR: uncompute t
  call void @cqrt_free(i32 %17)    ; IR: release t (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %16, i32 %14, i32 1)    ; IR: uncompute y' - 1
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %11)    ; IR: release the old y rail (|0> after the copy)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %12, i32 %10, i32 %4)    ; IR: uncompute %12 (x untouched since)
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  %18 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %20 = cq_measure_si32(%18)
  %19 = call i32 @cqrt_measure_i32(i32 %15)    ; IR: %21 = cq_measure_si32(%19)
  %20 = add nsw i32 %19, %18    ; IR: %22 = add nsw i32 %21, %20  (classical)
  %21 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %23 = cq_measure_si32(%10)
  %22 = add nsw i32 %20, %21    ; IR: %24 = add nsw i32 %22, %23  (classical)
  ret i32 %22    ; IR: ret i32 %24
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
