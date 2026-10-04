; lowering_reject_loop_quantum_bound_dead_counter.ll — DECLINE (Phase 7.4 Inc 1,
; y05j.1; PRD-7.4 §2.5 B5, §6 Risk 4). The ADVERSARIAL Risk-4 probe found by the
; Rule-13 review (2026-06-25, R4-8): a GENUINELY QUANTUM-BOUNDED loop disguised as
; a value-arm break by a dead counter + a loop-invariant classical guard —
;     int q = x; cq_theta(&q, 0.25);
;     int i = 0;
;     while ((q & 1) && (m != 0)) {   // sole real termination = (q&1)==0 (QUANTUM)
;         q = q ^ 9;
;         i++;                         // counter increments but NEVER bounds the loop
;     }
;     return cq_measure(q) + i;        // i escapes (survives DCE) but is not a bound
;
; Verified against real `clang -O1` output (Rule 11, /tmp/spike/r4_8.ll): the
; continue condition fuses as `and i1 %guard, %brk` where `%guard = icmp ne %m, 0`
; is LOOP-INVARIANT (computed in the preheader, never changes) and `%brk` is the
; tainted quantum termination. The loop's ONLY real exit is the quantum `%brk`;
; `%guard` is not a trip-count bound and the counter `%i` is dead (never compared).
;
; A naive recognizer (accept ANY non-tainted fused disjunct as "the classical
; bound" + ANY untainted header phi as "induction") MIS-RECOGNIZES this as a
; value-arm break — which (now that emission lands, y05j.2) would EMIT a
; WRONG UNITARY for a genuinely quantum-bounded loop (the verify-clean silent
; miscompile). The B5 fix REQUIRES the classical bound to compare a value derived
; from the loop's SELF-INCREMENTING induction variable (a real trip-count bound):
; `%guard` references only `%m`/0, never the counter `%i`, so the bound does NOT
; track induction ⇒ ride L1. The control (the identical loop with NO counter)
; already declines L1. PERMANENT decline (genuinely quantum-bounded, §2.6 / the
; existing 7.3 L1). Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control
; The genuinely-quantum-bounded loop must ride L1 — NOT be mis-claimed by the break
; emit path, which would surface kMsgBreakUnemittable on this same 2>&1 stream (rxx8:
; the retired kMsgBreakPending CHECK-NOT swapped for the LIVE break-emit diagnostic).
; CHECK-NOT: cq loop lowering: early break body is not a provable rolled single-rail loop

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @qbound_dead_counter(i32 %x, i32 %m) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp ne i32 %m, 0                       ; LOOP-INVARIANT classical guard
  %s0 = and i32 %q0, 1
  %b0 = icmp ne i32 %s0, 0
  %enter = and i1 %guard, %b0
  br i1 %enter, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]    ; dead counter (self-increments)
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; tainted rail
  %qn = xor i32 %q, 9
  %inext = add nuw nsw i32 %i, 1                   ; counter increments...
  %s = and i32 %qn, 1
  %brk = icmp ne i32 %s, 0                         ; TAINTED quantum termination
  %cont = and i1 %guard, %brk                      ; continue: INVARIANT-guard AND quantum
  br i1 %cont, label %loop, label %exit            ; ...but %inext NEVER bounds the loop

exit:                                             ; preds = %loop, %entry
  %ansq = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %ansi = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %m1 = call i32 @cq_measure_si32(i32 %ansq)
  %r = add nsw i32 %m1, %ansi
  ret i32 %r
}
