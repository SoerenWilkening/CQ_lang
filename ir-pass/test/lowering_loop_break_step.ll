; lowering_loop_break_step.ll — POSITIVE recognition (Phase 7.4 Inc 1, y05j.1; the
; B5 increment widening, owner 2026-06-26): a value-arm break loop with a NON-UNIT
; classical stride:
;     int q = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i += 2) {     // step-2 classical counter
;         q = q ^ 9;
;         if ((q & 1) == 0) break;         // tainted value-arm break
;     }
;     return cq_measure(q);
;
; Verified against real `clang -O1` output (Rule 11, /tmp/spike/odecl_step2.ll):
; clang CANNOT use an exact-equality exit for a step-2 counter (i = 0,2,4,… may step
; OVER n without equaling it), so it emits the bound as `icmp slt (i+2), n`, fused
; continue-polarity `select(%brk, %bound, false)` (= ¬break ∧ within-bound), with
; `br %cont, loop, exit`.
;
; `ScalarEvolution::getSymbolicMaxBackedgeTakenCount` is INCOMPLETE on this
; `slt`-with-non-unit-step shape (returns Unpredictable — verified even for the
; standalone loop with no break), so the B5 SCEV fast path declines. The structural
; termination proof `boundProvablyTerminates` recognizes it: the bound compares a
; no-wrap induction AddRec with a CONSTANT non-zero step (`add nuw nsw %i, 2`)
; against a loop-invariant limit, and SCEV's monotonicity oracle
; (`getMonotonicPredicateType`, run on the flag-bearing HEADER phi recurrence — the
; shifted `i+2` operand drops `<nsw>`) proves the bound drives the counter to the
; loop-exit value. Restricted to purely CLASSICAL constant increments.
;
; SOUNDNESS: the wrong-direction / non-terminating cousins still decline L1 — a
; counter-referencing-but-non-bounding compare (`i>=start`, `i>k` decrementing) has
; no monotonic-toward-exit direction; see lowering_reject_loop_quantum_bound*.ll.
;
; Increment 2 (y05j.2) UPDATE: the recognizer still ACCEPTS this non-unit stride,
; but the EMITTER proves the index-gated capture + whole-loop reverse-play only on
; the CANONICAL unit-stride up-counting rolled shape (the backward companion loop
; reconstructs the per-iteration index as `i' = n-1 … 0`, unit-stride). A non-unit
; stride is a decline-safe near-term widening: `emitBreakForward` declines LOUDLY
; with `kMsgBreakUnemittable` — NOT mis-emitted, and NOT mis-declined as the L1
; quantum-bounded `loop under quantum control` (the partition still holds).
; Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_step(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]    ; classical step-2 induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; tainted value-mutating rail
  %qn = xor i32 %q, 9
  %a0 = and i32 %qn, 1
  %brk = icmp ne i32 %a0, 0                         ; TAINTED ¬break flag (continue form)
  %inext = add nuw nsw i32 %i, 2                    ; NON-UNIT classical stride
  %bound = icmp slt i32 %inext, %n                  ; CLASSICAL slt bound (i+2 < n)
  %cont = select i1 %brk, i1 %bound, i1 false       ; AND-fused continue
  br i1 %cont, label %loop, label %exit

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]    ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
