; HAND-WRITTEN. Rules: 13, 9, 8, 4, 5.
; Checked: r (measured).
; Clean: the three case flags, the default arm value and the two inner merges, all freed.
; Kept: none.
; Rotations: (Ry, x, tx, 1).
; A switch on the register itself with sparse cases 1 / 5 / 9 and a REACHABLE default. Rule 13: one equality flag per case
; on the scrutinee (x is the scrutinee: no `and` prefix); the default is the complement of the case flags and gets no flag
; of its own: it is the innermost select operand. The three case arms are classical (-O1 folded `c - x` under `case 9` to
; `c - 9`), so they enter the merge as literals (select _lh); the default arm `x * c` is computed unguarded into a fresh rail.
; Rule 9: the phi is a chain of one select per case, default innermost, into a fresh result rail; arm rails and flags are
; uncomputed LIFO afterwards.
source_filename = "switch_sparse_default.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @switch_sparse_default(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x, the scrutinee]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 1)    ; IR: switch i32 %4: i32 1 -> %5
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 5)    ; IR: switch i32 %4: i32 5 -> %7
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 9)    ; IR: switch i32 %4: i32 9 -> %9  (default %11 is the complement: no flag)
  %8 = add nsw i32 %2, 1    ; IR: %6 = add nsw i32 %2, 1  (classical)
  %9 = mul nsw i32 %2, 3    ; IR: %8 = mul nsw i32 %2, 3  (classical)
  %10 = add nsw i32 %2, -9    ; IR: %10 = add nsw i32 %2, -9  (classical)
  %11 = call i32 @cq_template_mul_i32_hl(i32 %4, i32 %2)    ; IR: %12 = mul nsw i32 %4, %2  (default arm, unguarded)
  %12 = call i32 @cq_template_select_i32_lh(i32 %7, i32 %10, i32 %11)    ; IR: %14 = phi: [ %10, %9 ] else [ %12, %11 ] (default)
  %13 = call i32 @cq_template_select_i32_lh(i32 %6, i32 %9, i32 %12)    ; IR: %14 = phi: [ %8, %7 ]
  %14 = call i32 @cq_template_select_i32_lh(i32 %5, i32 %8, i32 %13)    ; IR: %14 = phi: [ %6, %5 ]  [result rail]
  call void @cq_template_select_i32_lh_unc(i32 %13, i32 %6, i32 %9, i32 %12)    ; IR: uncompute the inner merge
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %12, i32 %7, i32 %10, i32 %11)    ; IR: uncompute the innermost merge
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %11, i32 %4, i32 %2)    ; IR: uncompute %12
  call void @cqrt_free(i32 %11)    ; IR: release the %12 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %4, i32 9)    ; IR: uncompute the case-9 flag
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %4, i32 5)    ; IR: uncompute the case-5 flag
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %5, i32 %4, i32 1)    ; IR: uncompute the case-1 flag
  call void @cqrt_free(i32 %5)    ; IR: release it (|0>)
  %15 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %15    ; IR: ret i32 %15
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
