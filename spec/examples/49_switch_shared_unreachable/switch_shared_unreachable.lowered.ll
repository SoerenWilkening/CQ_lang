; HAND-WRITTEN. Rules: 13, 9, 8, 4, 5, 2.
; Checked: r (the outer select rail %15, measured as %16).
; Clean: the scrutinee x & 3 (%6), the case flags %7 (== 0), %8 (== 1), %10 (== 2), the shared-arm disjunction %9, the
; three arm rails %11 (x + a), %12 (x * b), %13 (x - a) and the inner select %14, all uncomputed and freed.
; Kept: x (%5, the rotated register, a source of every arm) and r (%15, measured).
; Rotations: (Ry, x, th, 1).
; Two switch cases that share one block: the arm's predicate is the OR of its edge flags, cqrt_or_i1 into a fresh |0>
; flag (rule 8; the equality flags on one scrutinee are disjoint, so two CNOTs would also do, but the spec spells a
; disjunction or_i1). The default label is `unreachable` by the user's own declaration: the compiler knows no execution
; reaches it, so it is a predicate that is provably 0 and gets no flag and no cqrt_abort_i1 (contrast 45, where an abort
; arm is reachable and keeps its flag). With default gone, the last case (3) is the complement of the others and needs no
; flag either (as 22): it is the innermost select operand. Value arms merge by a chain of selects (rule 9).
source_filename = "switch_shared_unreachable.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @switch_shared_unreachable(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)    ; IR: %6 = and i32 %5, 3  [scrutinee]
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)    ; IR: switch i32 %6: i32 0 -> %7
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 1)    ; IR: switch i32 %6: i32 1 -> %7
  %9 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %7 = (%6 == 0) | (%6 == 1)
  call void @cqrt_or_i1(i32 %7, i32 %8, i32 %9)    ; IR: OR of the two (disjoint) case flags into the fresh flag
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 2)    ; IR: switch i32 %6: i32 2 -> %9
  %11 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %2)    ; IR: %8 = add nsw i32 %5, %2  (block %7)
  %12 = call i32 @cq_template_mul_i32_hl(i32 %5, i32 %3)    ; IR: %10 = mul nsw i32 %5, %3  (block %9)
  %13 = call i32 @cq_template_sub_i32_hl(i32 %5, i32 %2)    ; IR: %12 = sub nsw i32 %5, %2  (block %11; case 3 is the complement: default %13 is unreachable)
  %14 = call i32 @cq_template_select_i32(i32 %10, i32 %12, i32 %13)    ; IR: %15 = phi: [ %10, %9 ] else [ %12, %11 ]
  %15 = call i32 @cq_template_select_i32(i32 %9, i32 %11, i32 %14)    ; IR: %15 = phi: [ %8, %7 ]  [result rail]
  call void @cq_template_select_i32_unc(i32 %14, i32 %10, i32 %12, i32 %13)    ; IR: uncompute the inner merge
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %13, i32 %5, i32 %2)    ; IR: uncompute %12
  call void @cqrt_free(i32 %13)    ; IR: release the %12 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %12, i32 %5, i32 %3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %12)    ; IR: release the %10 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %5, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %6, i32 2)    ; IR: uncompute the case-2 flag
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %7, i32 %8, i32 %9)    ; IR: uncompute the shared-arm predicate (self-inverse)
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %6, i32 1)    ; IR: uncompute the case-1 flag
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)    ; IR: uncompute the case-0 flag
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %16 = call i32 @cqrt_measure_i32(i32 %15)    ; IR: %16 = cq_measure_si32(%15)
  ret i32 %16    ; IR: ret i32 %16
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_or_i1(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
