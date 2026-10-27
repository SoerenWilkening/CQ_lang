; HAND-WRITTEN. Rules: 18, 2, 4.
; Checked: m + cq_measure(y), m = max(cq_measure(x), k) returned classically by the callee, y = x + c.
; Clean: none (no garbage rail is minted).
; Kept: the user register x (measured inside the clone, never freed); y (measured).
; Rotations: Ry(th) on x.
; A callee that MEASURES its quantum argument is not a pure function and has no _unc twin (rule 18): its clone measures
; the handle where the source measures the value, and from there on the callee is classical (the smax is classical
; arithmetic on the outcome). The clone returns the classical int, not a handle, so the caller's call result is
; classical: nothing to copy out, nothing to uncompute. The measurement is the user's: it collapses x and, through
; y = x + c, the entangled y, which the caller measures afterwards as written. The argument rail is consumed by the
; measurement and is never freed (rule 2: a measured name is not read again as a register; a re-measurement would be a
; classical re-read).
source_filename = "callee_measure.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_measure(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %3)    ; IR: %6 = add nsw i32 %5, %3  [y, entangled with x]
  %7 = call fastcc i32 @__cq_q_readout_10(i32 %5, i32 %2)    ; IR: %7 = call @readout(%5, %2), quantum clone (arg 0 quantum): returns a CLASSICAL int
  %8 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %8 = cq_measure_si32(%6)
  %9 = add nsw i32 %8, %7    ; IR: %9 = add nsw i32 %8, %7  (classical)
  ret i32 %9    ; IR: ret i32 %9
}

define internal fastcc i32 @__cq_q_readout_10(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_measure_i32(i32 %0)    ; IR: %3 = cq_measure_si32(%0): the callee measures its argument handle
  %4 = call i32 @llvm.smax.i32(i32 %3, i32 %1)    ; IR: %4 = llvm.smax.i32(%3, %1)  (classical)
  ret i32 %4    ; IR: ret i32 %4  (a classical value, not a handle)
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @llvm.smax.i32(i32, i32)
