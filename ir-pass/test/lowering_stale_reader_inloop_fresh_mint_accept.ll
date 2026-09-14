; lowering_stale_reader_inloop_fresh_mint_accept.ll — ACCEPT.
;
; THE SECOND OF THE TWO SPELLINGS THE 2026-09-14 OWNER RULING LEAVES THE USER
; (bd test_C_libtooling-3d8q, Rule-13 round-1 finding F-D1-1). The ruling declines
; the AMBIGUOUS in-loop read of a loop-invariant quantum name; it costs a two-token
; edit only because BOTH unambiguous readings already compile, and this file plus
; `lowering_stale_reader_inloop_selfassign_accept.ll` are what pin that. Neither
; was pinned by anything before the ruling.
;
;   the ALIAS reading          for (…) { q = cq_theta(q, .1); s += cq_measure(q); }
;                              -> one rail, chained  (…_inloop_selfassign_accept.ll)
;   the RE-PREPARATION reading for (…) { int q = cq_theta(0,.3);        <- THIS FILE
;                                        int b = cq_theta(q,.1); s += cq_measure(b); }
;                              -> a FRESH rail per trip
;   the AMBIGUOUS spelling     int q = cq_theta(0,.3);
;                              for (…) { int b = cq_theta(q,.1); … }   -> DECLINES
;                              (`lowering_reject_stale_reader_inloop_invariant_seed.ll`)
;
; ⚠ RE-PREPARATION IS NOT CLONING, and that distinction is what the ruling turned
; on. `%q`'s state is a KNOWN preparation from the seed, so producing it again is
; re-running a preparation, never duplicating an unknown state (Rule 8 forbids the
; latter only). This module is the measured proof that the compiler emits that
; circuit when the source asks for it unambiguously — which is why the ambiguous
; spelling has something to be ambiguous BETWEEN, and therefore declines.
;
; WHY IT ACCEPTS, mechanically: `%q` is a SOURCE theta (arg-0 is the classical
; `%u1`), so it carries no wire to be stale about and `staleReaderRecordOperand`
; returns nothing for it. The reader `%rm` reads `%q`, whose DEFINITION IS INSIDE
; THE LOOP BODY — so every back-edge path from `%rm` back to `%rm` crosses it, the
; record is re-established per trip, and `readerStalesItself`'s leg 2 grants the
; self-exemption. The barrier here is a NON-φ instruction, which is the leg a
; blanket "loop-invariant seed => decline" would have broken.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %body ]
  br label %body
body:
  %q     = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %rm    = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m     = call i32 @cq_measure_si32(i32 %rm)
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %m
}

; The mint is INSIDE the loop — a fresh rail every trip, which is the whole point.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 9.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; Counts in their OWN whole-file prefixes (Rule 12 fixture-hygiene (a)). The IR is
; ROLLED, so these are the per-trip gates once each, not three times.
; ACNT-COUNT-1: call i32 @cqrt_alloc_i32(
; ACNT-NOT: call i32 @cqrt_alloc_i32(

; RCNT-COUNT-2: call void @cqrt_ry_i32(
; RCNT-NOT: call void @cqrt_ry_i32(

; MCNT-COUNT-1: call i32 @cqrt_measure_i32(
; MCNT-NOT: call i32 @cqrt_measure_i32(

; NOQ-NOT: cq_theta_si32
; NOQ-NOT: cq_measure_si32
