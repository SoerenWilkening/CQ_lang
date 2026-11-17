; HAND-WRITTEN. Rules: 10, 8, 2 (measurement in arms; classical collapse), 5.
; Checked: x (%7 -> %10, measured once; the returned int is x or x + 1 by the classical re-derivation of which arm ran).
; Clean: the condition flag x > k (%8), uncomputed before the measurement and freed.
; Kept: x (%7, the rotated register, measured) and r (%9, rotated by a different angle in each arm and never measured:
; frozen, never reverse-played, never freed).
; Rotations: (Ry, x, th, 1); (Ry, r, t1, x > k); (Ry, r, t2, NOT (x > k)).
; The source has two return arms that never meet; at -O1 clang merges every return, so the IR reconverges in a phi of
; the two MEASURED values (%17) under the quantum condition. What remains to lower: the dead register r is rotated by a
; different angle in each arm (the controlled Ry of 39 and its NOT-bracketed twin) and never measured, so it stays
; allocated (frozen). Both arms measure x at the same point, so by rule 2 the two cq_measure calls are ONE unconditional
; measurement of x (the second a classical re-read). The merge phi %17 is then decided by rule 2's CLASSICAL COLLAPSE:
; its condition %8 = (x > k) is computed only from the measured rail x and the classical k, so it is classical. Its rail
; is uncomputed while x still holds the outcome's source state (here before the measurement, right after the last
; controlled Ry it guards), the condition is recomputed from the outcome by an ordinary `icmp sgt` (%11), and the merge
; is a classical `select` (%13); no quantum mux and no select template. No measurement is inserted: the user measures x
; in both arms, and that one measurement decides the return.
source_filename = "nonreconverging_returns.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nonreconverging_returns(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %8 = icmp sgt i32 %7, %2  [path predicate of %9; its negation is the predicate of %12]
  %9 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %10 / %13 = cq_theta_si32(%3, ...)  [register r, starts as %3 in both arms]
  call void @cqrt_ry_i32_controlled(i32 %8, i32 %9, double %4)    ; IR: block %9: %10 = cq_theta_si32(%3, %4)
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket: block %12 runs under NOT %8
  call void @cqrt_ry_i32_controlled(i32 %8, i32 %9, double %5)    ; IR: block %12: %13 = cq_theta_si32(%3, %5)
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %11 / %14 = cq_measure_si32(%7): both arms measure x, once
  %11 = icmp sgt i32 %10, %2    ; IR: %8 re-derived classically from the outcome: which arm returned
  %12 = add nsw i32 %10, 1    ; IR: %15 = add nsw i32 %14, 1  (classical)
  %13 = select i1 %11, i32 %10, i32 %12    ; IR: %17 = phi i32 [ %11, %9 ], [ %15, %12 ]  (classical mux; r stays allocated)
  ret i32 %13    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
