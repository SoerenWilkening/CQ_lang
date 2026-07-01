; lowering_reject_bitcast_tape_stale.ll — bd iw81.1 DECLINE (Rule-13 BLOCKER #3,
; the Phase-7.6 I/O tape-sink shape). A tainted `printf` (reversible output tape)
; takes the folded bitcast RESULT `%b` as its source, while a sibling `cq_theta`
; re-rotates that wire in place. The tape sink's continued-lineage / terminality
; check is a BESPOKE walk (not the shared stale-record walker): a late fold leaving
; `%b` standing would let `%b` LOOK terminal (its only user is the printf) while its
; true wire `%q` has continued lineage — so the tape would record a STALE (post-Ry)
; basis (verify-clean silent miscompile). The EARLY fold replaces `%b` with `%q`
; before the tape sink runs, reducing this to the DIRECT `printf(%q)` form the pass
; DECLINES for continued lineage. (The printf result is left UNUSED — a used tainted
; output-call result trips a different decline in both forms.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b  = bitcast i32 %q to i32
  ; In-place Ry re-rotates %q's wire (continued lineage), hidden behind %b.
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  ; Tape source is the bitcast result %b === %q (which is NOT terminal).
  %r  = call i32 (ptr, ...) @printf(ptr @.str, i32 %b)
  ret void
}

; CHECK: error{{.*}}cq I/O output sink: tainted argument has continued lineage (only a terminal or measured value may be taped)
; CHECK-NOT: cqrt_tape_write
