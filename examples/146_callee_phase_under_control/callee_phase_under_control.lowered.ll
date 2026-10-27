; HAND-WRITTEN. Rules: 12, 19, 8, 18, 2, 5.
; Checked: x (measured).
; Clean: the flag f = (x > k), freed before the second Ry on x.
; Kept: none.
; Rotations: (Ry, x, tx, 1); (P, f, p, x > k) [g's phase]; (P, f, p, x > k when f != 0) [h's phase]; (Ry, x, -tx,
; 1).
; Rule 12 is scope-dependent. (1) g's cq_phi(p) is unconditional INSIDE g, but g is called from a block whose predicate is
; the quantum flag f, so it is a relative phase on f: g becomes the controlled clone __cq_q_g_0_ctl (rule 19: a callee under
; a quantum predicate with a non-pure gate; §1.4: the predicate is its first parameter, mask 0 = its one classical formal)
; whose body is rz_i1(pred, p). (2) h's phase sits under the CLASSICAL `if (f)` inside h, called under the same quantum
; predicate: the clone __cq_q_h_00_ctl keeps the classical branch and fires rz_i1(pred, p) inside it (rule 8: classical
; conjuncts stay classical branches around the quantum part). (3) The entry's own cq_phi(p) runs with no quantum predicate
; in scope at any depth: a global phase, deleted. Both calls are void with no results, so no twin and no merge. -O1 folded
; the two `if (x > k)` into one block: one flag serves both calls. The flag is uncomputed after its last controlled gate
; and before the non-diagonal Ry(-tx) on its source x (rule 5). The original g and h are dead and dropped.
source_filename = "callee_phase_under_control.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_phase_under_control(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %7 = icmp sgt i32 %6, %2  [path predicate of block %8]
  call fastcc void @__cq_q_g_0_ctl(i32 %7, double %3)    ; IR: block %8: call @g(%3) under predicate %7: controlled clone (its phase is relative to %7)
  call fastcc void @__cq_q_h_00_ctl(i32 %7, i32 %4, double %3)    ; IR: block %8: call @h(%4, %3) under predicate %7: controlled clone
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %6, i32 %2)    ; IR: uncompute %7 (x untouched since)
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %8 = fneg double %1    ; IR: %10 = fneg double %1  (classical); block %9: cq_phi(%3) is a global phase, deleted (rule 12)
  call void @cqrt_ry_i32(i32 %6, double %8)    ; IR: %11 = cq_theta_si32(%6, %10)  [Ry in place on x]
  %9 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %12 = cq_measure_si32(%11)
  ret i32 %9    ; IR: ret i32 %12
}

define internal fastcc void @__cq_q_g_0_ctl(i32 %0, double %1) {
  call void @cqrt_rz_i1(i32 %0, double %1)    ; IR: g: cq_phi(%0) under the caller's predicate: P(p) on the flag
  ret void    ; IR: ret void
}

define internal fastcc void @__cq_q_h_00_ctl(i32 %0, i32 %1, double %2) {
  %4 = icmp eq i32 %1, 0    ; IR: h: %3 = icmp eq i32 %0, 0  (classical: stays a classical branch)
  br i1 %4, label %6, label %5    ; IR: h: br i1 %3, label %5, label %4

5:
  call void @cqrt_rz_i1(i32 %0, double %2)    ; IR: h: block %4: cq_phi(%1) under the caller's predicate: P(p) on the flag
  br label %6    ; IR: h: br label %5

6:
  ret void    ; IR: h: ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
