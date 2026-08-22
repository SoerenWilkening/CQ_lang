; lowering_ctlz_idiom_reject_mask_shift_f80.ll — DECLINE. THE SINGLE MOST
; IMPORTANT FIXTURE IN THIS MATRIX (PRD §10). The `ilogbl`/`logbl` f80 loop,
; TRANSCRIBED FROM THE REAL -O1 IR in PRD §5.3 — instruction for instruction,
; only the labels named and the fp80 bit-extraction preamble replaced by a
; direct tainted i64 seed (the fence is about the LOOP; the preamble is not).
;
; A recognizer that claims this loop IS A SILENT MISCOMPILE (bd ywws, bd k02s).
; Their safety TODAY is an accident: SCEV reports CouldNotCompute, so no unsound
; bound can be built from them, and the only bound that exists is conditional on
; a TAINTED guard that PredMux demonstrably removes. SCOPING-L3 §6 item 1
; proposes exactly a "shift-until-normalized" recognizer and bd k02s records
; that as its blocking precondition. This file is that precondition, discharged.
;
; It differs from the accepted idiom on FIVE axes (PRD §5.3's table), FOUR of
; which are independently fatal:
;
;   |                  | accepted (ilogb/ilogbf) | here (ilogbl/logbl)          |
;   | shift            | shl <rec>, 1            | lshr <mask>, 1        (Z3)   |
;   | what is shifted  | the DATA                | a MASK; data is invariant    |
;   | compared operand | the recurrence ITSELF   | and <rec>, <invariant> (Z5)  |
;   | predicate        | sgt ... 0               | eq ... 0              (Z5)   |
;   | counter          | add ..., -1             | add ..., 1            (Z4)   |
;   | terminates?      | YES, max 31 (measured)  | NO — diverges when the       |
;   |                  |                         | tested word is 0             |
;
; That last row is why Z5's "the compared operand must BE the recurrence's own
; latch value" is the load-bearing clause rather than a stylistic one. A value
; repeatedly shifted left marches monotonically into the sign bit, so the loop
; is bounded by N on EVERY input; a value DERIVED from the recurrence carries no
; such guarantee, and this one genuinely does not terminate on `%data == 0`.
; Z5 is therefore both the exclusion AND the termination argument.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @ilogbl_mask_scan(i64 %w) {
entry:
  %data = call i64 @cq_theta_sll(i64 %w, double 5.000000e-01)
  br label %scan

scan:                                             ; preds = %entry, %scan
  %ix = phi i32 [ 32, %entry ], [ %inc, %scan ]
  %mask = phi i64 [ 2147483648, %entry ], [ %next, %scan ]
  %inc = add nuw nsw i32 %ix, 1
  %next = lshr i64 %mask, 1
  %hit = and i64 %next, %data
  %miss = icmp eq i64 %hit, 0
  br i1 %miss, label %scan, label %out, !llvm.loop !0

out:                                              ; preds = %scan
  %m = call i32 @cq_measure_si32(i32 %inc)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}
