; lowering_ctlz_idiom_reject_ashr.ll — DECLINE (bd ww4c Inc 1, the Z3 direction
; probe). The accepted shape with ONE change: `shl` becomes `ashr`.
;
; Z3 requires the shift recurrence's latch value to be `shl <rec>, 1` — opcode
; EXACTLY Shl. This is not a formality. The PRD §4.1 closed form is derived from
; a value marching MONOTONICALLY INTO the sign bit, which is what makes `f` both
; well-defined and bounded by N. An ARITHMETIC right shift moves the other way
; and sign-extends: on any negative input it converges to -1 and this loop never
; terminates at all. There is no closed form to substitute.
;
; PRD §5.1: `ilogbl`/`logbl` fail Z3 too (they shift `lshr`), so this is one of
; the two independent grounds that fence keeps — defence in depth is deliberate
; (the loop campaign is 3-for-3 at finding over-accepts in adversarial rounds).
;
; The recognizer is ACCEPT-ONLY and never diagnoses: an off-fence loop is left
; byte-untouched and keeps its EXISTING loud owner, `tryCaseA`'s Q1
; (LoopLowering.cpp `taintedExit` -> `diagnoseUnderControl(TE, "loop")`), pinned
; character-for-character.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_ashr(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = ashr i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
