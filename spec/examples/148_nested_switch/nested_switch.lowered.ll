; HAND-WRITTEN. Rules: 13, 8, 9, 4, 5.
; Checked: r (measured).
; Clean: both scrutinees, the four case flags, the conjunction flag of the phase arm, the two quantum arm values and
; the three inner merges, all freed.
; Kept: none.
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1); (P, g, p, (x & 3) == 1 && (y & 3) == 2).
; Outer switch on x & 3: flags f0, f1; its default (the complement) gets no flag. Inner switch on y & 3 inside case 1:
; flags g0, g2; its default is the complement inside the arm. The inner PHASE arm (case 2) fires under the conjunction of
; its path: g = f1 & g2 is one and_i1 into a fresh |0> flag, P(p) is a kickback on g, g is uncomputed right after (rule 8).
; The VALUE arms merge by rule 9 as nested select chains: the inner switch's phi contributes its own chain (g0 outer, g2,
; inner default `y + c` innermost; the phase arm's incoming is the classical c) and that chain is the case-1 operand of
; the outer chain (f0 outer, f1, outer default `x + c` innermost). An inner select is evaluated unguarded (pure) and only
; selected under f1, so no conjunction flag is needed for the value merge; the conjunction is needed only where a gate
; fires. Classical arm values (c + 1, c + 2, c) enter as literals (select _lh). Everything is uncomputed LIFO.
source_filename = "nested_switch.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nested_switch(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %8 = cq_theta_si32(%2, %3)  [Ry]
  %9 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %9 = and i32 %7, 3  [outer scrutinee]
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 0)    ; IR: switch i32 %9: i32 0 -> %10
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 1)    ; IR: switch i32 %9: i32 1 -> %12  (default %19 is the complement: no flag)
  %12 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %13 = and i32 %8, 3  [inner scrutinee, block %12, pure: computed unguarded]
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 0)    ; IR: switch i32 %13: i32 0 -> %14
  %14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 2)    ; IR: switch i32 %13: i32 2 -> %16  (default %17 is the complement: no flag)
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %16 = f1 & g2  [fresh |0> flag]
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %15)    ; IR: f1 & g2 (Toffoli into the |0> flag)
  call void @cqrt_rz_i1(i32 %15, double %5)    ; IR: block %16: cq_phi(%5)  [kickback on the conjunction]
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %15)    ; IR: uncompute the %16 predicate (f1, g2 unchanged)
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  %16 = add nsw i32 %4, 1    ; IR: %11 = add nsw i32 %4, 1  (classical)
  %17 = add nsw i32 %4, 2    ; IR: %15 = add nsw i32 %4, 2  (classical)
  %18 = call i32 @cq_template_add_i32_hl(i32 %8, i32 %4)    ; IR: %18 = add nsw i32 %8, %4  (inner default arm, unguarded)
  %19 = call i32 @cq_template_add_i32_hl(i32 %7, i32 %4)    ; IR: %20 = add nsw i32 %7, %4  (outer default arm, unguarded)
  %20 = call i32 @cq_template_select_i32_lh(i32 %14, i32 %4, i32 %18)    ; IR: %22 = phi: [ %4, %16 ] else [ %18, %17 ] (inner default)
  %21 = call i32 @cq_template_select_i32_lh(i32 %13, i32 %17, i32 %20)    ; IR: %22 = phi: [ %15, %14 ]  [the inner switch's merge]
  %22 = call i32 @cq_template_select_i32(i32 %11, i32 %21, i32 %19)    ; IR: %22 = phi: case 1 (the inner merge) else [ %20, %19 ] (outer default)
  %23 = call i32 @cq_template_select_i32_lh(i32 %10, i32 %16, i32 %22)    ; IR: %22 = phi: [ %11, %10 ]  [result rail]
  call void @cq_template_select_i32_unc(i32 %22, i32 %11, i32 %21, i32 %19)    ; IR: uncompute the case-1 merge
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %21, i32 %13, i32 %17, i32 %20)    ; IR: uncompute the inner merge
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %20, i32 %14, i32 %4, i32 %18)    ; IR: uncompute the innermost inner merge
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %19, i32 %7, i32 %4)    ; IR: uncompute %20
  call void @cqrt_free(i32 %19)    ; IR: release the %20 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %18, i32 %8, i32 %4)    ; IR: uncompute %18
  call void @cqrt_free(i32 %18)    ; IR: release the %18 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %14, i32 %12, i32 2)    ; IR: uncompute the inner case-2 flag
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 0)    ; IR: uncompute the inner case-0 flag
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %8, i32 3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %12)    ; IR: release the %13 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %9, i32 1)    ; IR: uncompute the outer case-1 flag
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 0)    ; IR: uncompute the outer case-0 flag
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %7, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %24 = call i32 @cqrt_measure_i32(i32 %23)    ; IR: %23 = cq_measure_si32(%22)
  ret i32 %24    ; IR: ret i32 %23
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
