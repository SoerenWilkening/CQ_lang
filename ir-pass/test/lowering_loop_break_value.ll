; lowering_loop_break_value.ll — POSITIVE recognition (Phase 7.4 Inc 1, y05j.1;
; PRD-7.4 §2.5 B1-B5, §2.10 accept row): a classically-bounded, DATA-MUTATING
; loop with a SINGLE tainted-condition value-arm early break, measured after:
;     int q = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 9;                 // value mutation (the dirty rail)
;         if ((q & 1) == 0) break;   // TAINTED value-arm break
;     }
;     return cq_measure(q);
;
; Verified against real `clang -O1` output (Rule 11, /tmp/spike/v1_value.ll): the
; tainted break flag (`%brk`) and the CLASSICAL loop bound (`%bound = icmp eq
; %i.next, %n`) are FUSED into one `select(%brk, i1 true, %bound)` exit, so the
; loop-exit branch is TAINTED — today (7.3) indistinguishable by terminator-taint
; alone from a genuinely quantum-bounded `while(q<k)`, and both decline identically
; via the L1 `loop under quantum control` (PRD-7.4 §1.1).
;
; Inc-1 `tryBreak` DECOMPOSES that fused select to PARTITION the value-arm break
; (one tainted disjunct + one classical bound, value-class escaping answer,
; reconverging single exit, non-nested) from the quantum-bounded loop. Recognition
; is COMPLETE here; EMISSION (the index-gated copy-not-move capture + whole-loop
; reverse-play, §2.2/§2.3) lands in Increment 2 (y05j.2), where this interim
; decline FLIPS to an ACCEPT (no diagnostic). The interim decline is the proof of
; the partition: this loop is recognized as a value-arm break, NOT mis-declined as
; the L1 `loop under quantum control` (cf. lowering_reject_loop_quantum_bound.ll).
; Decline-safe today (Prime Directive: nothing lowers yet). Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break emission not yet implemented
; CHECK-NOT: cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_value(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %a0 = and i32 %qn, 1
  %brk = icmp eq i32 %a0, 0                          ; TAINTED break flag
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                    ; CLASSICAL loop bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound    ; FUSED select(brk, true, bound)
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
