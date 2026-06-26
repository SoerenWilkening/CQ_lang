; lowering_reject_loop_quantum_bound_diverging.ll — DECLINE (Phase 7.4 Inc 1,
; y05j.1; PRD-7.4 §2.5 B5, §6 Risk 4). The adversarial-review P3 probe
; (2026-06-26): a genuinely QUANTUM-BOUNDED loop disguised by a VACUOUS two-counter
; DIVERGING bound —
;     int q = cq_theta(x, 0.25);
;     int i = 0, m = 10;
;     while ((q & 1) && (i < m)) {   // i<m is ALWAYS TRUE: m outruns i
;         q = q ^ 9; i += 2; m += 4;
;     }
;     return cq_measure(q) + i + m;
;
; Verified against real `clang -O1` output (Rule 11, /tmp/spike/P3.ll): the bound
; fuses as `icmp ult (i+2), (m+4)` where BOTH operands are induction counters
; (i = {2,+,2}, m = {14,+,4}); since m steps faster and starts higher, `i < m` is
; always true, so the loop's ONLY real termination is the quantum break — genuinely
; quantum-bounded. `clang -O1` does NOT fold this two-counter relationship (unlike
; the single-counter `i>=0`, which it does fold to a bare quantum exit).
;
; The trap: `ScalarEvolution::getSymbolicMaxBackedgeTakenCount` returns a FINITE max
; (2147483646) — but it bounds the loop by the COUNTER'S OWN nsw/nuw OVERFLOW under
; `llvm.loop.mustprogress`, NOT by any real classical bound. So the SCEV B5 fast
; path (`hasFiniteClassicalTripBound`) over-accepts. The fix
; (`boundComparesInductionToInvariant`) requires the classical bound to compare the
; induction against a loop-INVARIANT limit; a two-counter diverging bound has NO
; loop-invariant operand (both are counters) ⇒ reject ⇒ ride L1. PERMANENT decline
; (genuinely quantum-bounded). Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control
; CHECK-NOT: cq loop lowering: early break emission not yet implemented

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @qbound_diverging(i32 %x) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %s0 = and i32 %q0, 1
  %b0 = icmp ne i32 %s0, 0
  br i1 %b0, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %m = phi i32 [ 10, %entry ], [ %mnext, %loop ]   ; counter, step +4 from 10
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]    ; counter, step +2 from 0
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; tainted rail
  %qn = xor i32 %q, 9
  %inext = add nuw nsw i32 %i, 2
  %mnext = add nuw nsw i32 %m, 4
  %s = and i32 %qn, 1
  %brk = icmp ne i32 %s, 0                          ; TAINTED ¬break (continue)
  %bound = icmp ult i32 %inext, %mnext             ; VACUOUS two-counter bound (always true)
  %cont = select i1 %brk, i1 %bound, i1 false
  br i1 %cont, label %loop, label %exit

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %r = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %r
}
