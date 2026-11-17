; HAND-WRITTEN. Rules: 10, 8, 12, 5, 2.
; Checked: r + x in each function (measured).
; Clean: every predicate flag (x == k; x > k; x > k1, x < k2) and prep_twice's conjunction flag.
; Kept: the user register x of each function; r (prepared in place under control, frozen, measured).
; Rotations: prep_const_incoming: Ry(th) on x; Ry(t) on r under (x == k), after xorc(7) on r under the same flag.
; prep_beside_phase: Ry(th) on x; Ry(t) on r under (x > k) after xorc(r0) under the same flag; P(p) on NOT (x > k).
; prep_twice: Ry(th) on x; Ry(t1) on r under (x > k1) after xorc(r0) under it; Ry(-t1) on r under (x > k1) & (x < k2),
; then xorc(r0) on r under the same conjunction; xorc(r0) on r under (x < k2); Ry(t2) on r under (x < k2).
; A STATE PREP under a quantum condition is a controlled Ry on the variable's own rail (39, rule 10); when the arm first
; RESETS the variable (r = 0) and the straight-through value is something else (7, r0, or an earlier prep), the reset
; is a controlled XOR with the value the rail holds there: cqrt_xorc_<W>_controlled(flag, r, v) takes r from v to 0
; exactly where the arm runs, and the controlled Ry follows. No second rail, no merge copy. A phase in the other arm is
; the kickback under NOT the flag (39/21). OVERWRITING a register that an earlier arm may have prepared: where both
; conditions hold the earlier prep must be undone first, by its own adjoint under the conjunction flag (Ry(-t1), then
; the XOR back to r0); then the rail is r0 under the second flag and the second prep proceeds. The adjoint is sound
; because nothing read r between the two preps (a live reader would have entangled it; then the register is not dead
; and the program is 38/66's shape instead).
source_filename = "state_prep_overwrite.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @prep_const_incoming(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 %2)    ; IR: %6 = icmp eq i32 %5, %2  [path predicate of block %7]
  %7 = call i32 @cqrt_alloc_i32(i32 7)    ; IR: %10 = phi i32 [ %8, %7 ], [ 7, %4 ]  [register r, starts as the straight-through 7]
  call void @cqrt_xorc_i32_controlled(i32 %6, i32 %7, i32 7)    ; IR: block %7: r = 0 (the prep seed) where the arm runs: 7 -> 0 under the flag
  call void @cqrt_ry_i32_controlled(i32 %6, i32 %7, double %3)    ; IR: block %7: %8 = cq_theta_si32(0, %3)  [Ry under the predicate]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %11 = cq_measure_si32(%10)
  %9 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %12 = cq_measure_si32(%5)
  %10 = add nsw i32 %9, %8    ; IR: %13 = add nsw i32 %12, %11  (classical)
  ret i32 %10    ; IR: ret i32 %13
}

define i32 @prep_beside_phase(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %8 = icmp sgt i32 %7, %2  [path predicate of %9; its negation is the predicate of %11]
  %9 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %13 = phi i32 [ %10, %9 ], [ %3, %11 ]  [register r, starts as %3]
  call void @cqrt_xorc_i32_controlled(i32 %8, i32 %9, i32 %3)    ; IR: block %9: r = 0 where the arm runs: %3 -> 0 under the flag
  call void @cqrt_ry_i32_controlled(i32 %8, i32 %9, double %4)    ; IR: block %9: %10 = cq_theta_si32(0, %4)  [Ry under the predicate]
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket: block %11 runs under NOT %8
  call void @cqrt_rz_i1(i32 %8, double %5)    ; IR: block %11: cq_phi(%5)  [kickback on the negated flag]
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %14 = cq_measure_si32(%13)
  %11 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %15 = cq_measure_si32(%7)
  %12 = add nsw i32 %11, %10    ; IR: %16 = add nsw i32 %15, %14  (classical)
  ret i32 %12    ; IR: ret i32 %16
}

define i32 @prep_twice(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6) {
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %8 = cq_theta_si32(%0, %1)  [Ry]
  %9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %8, i32 %2)    ; IR: %9 = icmp sgt i32 %8, %2  [path predicate of block %10]
  %10 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: %13 = phi i32 [ %11, %10 ], [ %4, %7 ]  [register r, starts as %4]
  call void @cqrt_xorc_i32_controlled(i32 %9, i32 %10, i32 %4)    ; IR: block %10: r = 0 under %9
  call void @cqrt_ry_i32_controlled(i32 %9, i32 %10, double %5)    ; IR: block %10: %11 = cq_theta_si32(0, %5)  [first prep]
  %11 = call i32 @cq_template_icmp_slt_i32_hl(i32 %8, i32 %3)    ; IR: %14 = icmp slt i32 %8, %3  [path predicate of block %15]
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: both arms ran: %14 & %9
  call void @cqrt_and_i1(i32 %11, i32 %9, i32 %12)    ; IR: g = %14 & %9
  %13 = fneg double %5    ; IR: -%5  (classical)
  call void @cqrt_ry_i32_controlled(i32 %12, i32 %10, double %13)    ; IR: block %15 overwrites %13: undo the first prep where it happened (its adjoint, Ry(-%5))
  call void @cqrt_xorc_i32_controlled(i32 %12, i32 %10, i32 %4)    ; IR: ... and its reset: r is %4 again under %14 & %9
  call void @cqrt_and_i1(i32 %11, i32 %9, i32 %12)    ; IR: uncompute g
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cqrt_xorc_i32_controlled(i32 %11, i32 %10, i32 %4)    ; IR: block %15: r = 0 under %14 (r is %4 on every path that reaches it)
  call void @cqrt_ry_i32_controlled(i32 %11, i32 %10, double %6)    ; IR: block %15: %16 = cq_theta_si32(0, %6)  [second prep]
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %11, i32 %8, i32 %3)    ; IR: uncompute %14
  call void @cqrt_free(i32 %11)    ; IR: release the %14 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %9, i32 %8, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %14 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %19 = cq_measure_si32(%18)
  %15 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %20 = cq_measure_si32(%8)
  %16 = add nsw i32 %15, %14    ; IR: %21 = add nsw i32 %20, %19  (classical)
  ret i32 %16    ; IR: ret i32 %21
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_xorc_i32_controlled(i32, i32, i32)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
