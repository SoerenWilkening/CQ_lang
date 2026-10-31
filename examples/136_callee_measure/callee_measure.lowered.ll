; HAND-WRITTEN. Rules: 18, 2, 4, 5.
; Checked: m + cq_measure(y), m = max(cq_measure(x), k) returned classically by the callee, y = x + c (y is a classical
; read by rule 2; its value is witnessed by the output).
; Clean: the y rail (%6): computed before x's measurement, it collapses with it (rule 2) and is uncomputed at the collapse
; point against x's rail, which holds the outcome; then freed.
; Kept: the user register x (measured inside the clone, never freed).
; Rotations: Ry(th) on x.
; Classical reads (rule 2): 1 (cq_measure(y): y is classical after x's measurement, no gate).
; A callee that MEASURES its quantum argument is not a pure function and has no _unc twin (rule 18): its clone measures
; the handle where the source measures the value, and from there on the callee is classical (the smax is classical
; arithmetic on the outcome). The clone returns the classical int, not a handle, so the caller's call result is
; classical: nothing to copy out, nothing to uncompute. The measurement is the user's: it collapses x and, through
; y = x + c, the entangled y.
; CLASSICAL COLLAPSE (rule 2, ruling 2026-10-29): y's only quantum source is x, and x is measured when the clone returns,
; so y is classical from there on although its rail was computed before the measurement. The clone returns smax(m, k),
; not m, so the caller RE-READS x's rail (cqrt_measure_i32 on a measured rail is a classical re-read of the outcome, not
; a measurement: rule 2, ABI 1.3; the backend logs no event), uncomputes y against that rail (which still holds m) and
; recomputes y = m + c by a classical add. The user's cq_measure(y) is a classical read and emits no gate. The argument
; rail is consumed by the measurement and is never freed.
source_filename = "callee_measure.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_measure(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %3)    ; IR: %6 = add nsw i32 %5, %3  [y, entangled with x]
  %7 = call fastcc i32 @__cq_q_readout_10(i32 %5, i32 %2)    ; IR: %7 = call @readout(%5, %2), quantum clone (arg 0 quantum): measures x inside, returns a CLASSICAL int
  %8 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: rule 2: classical re-read of x's outcome m (the clone measured %5 and returned smax(m, k), not m)
  call void @cq_template_add_i32_hl_unc(i32 %6, i32 %5, i32 %3)    ; IR: rule 2 collapse of y: its only quantum source is measured; %5 holds m
  call void @cqrt_free(i32 %6)    ; IR: release the y rail (|0>)
  %9 = add nsw i32 %8, %3    ; IR: y = m + c recomputed classically (rule 2); cq_measure_si32(%6) is a classical read of it: no gate
  %10 = add nsw i32 %9, %7    ; IR: %9 = add nsw i32 %8, %7  (classical)
  ret i32 %10    ; IR: ret i32 %9
}

define internal fastcc i32 @__cq_q_readout_10(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_measure_i32(i32 %0)    ; IR: %3 = cq_measure_si32(%0): the callee measures its argument handle
  %4 = call i32 @llvm.smax.i32(i32 %3, i32 %1)    ; IR: %4 = llvm.smax.i32(%3, %1)  (classical)
  ret i32 %4    ; IR: ret i32 %4  (a classical value, not a handle)
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @llvm.smax.i32(i32, i32)
