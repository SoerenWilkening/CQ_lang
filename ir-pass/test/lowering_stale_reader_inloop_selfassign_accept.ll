; lowering_stale_reader_inloop_selfassign_accept.ll — ACCEPT.
;
; THE WELL-FORMED TWIN of `lowering_reject_stale_reader_inloop_invariant_seed.ll`
; (bd test_C_libtooling-3d8q, Rule-13 round-1 finding F-D1-1), and the pin that
; keeps that finding's fix from becoming an over-decline.
;
;   int q = cq_theta(0, 0.3);
;   for (int i = 0; i < 3; i++) { q = cq_theta(q, 0.1); s += cq_measure(q); }
;
; The chain is SELF-ASSIGNED, so the loop header φ `%r` carries it: `%r`
; re-establishes the record on the back edge, `phiTracksWire` proves it, and the
; reader's own previous instance therefore cannot reach this read without
; crossing the barrier. The self-exemption is GRANTED and the module compiles to
; the rolled one-rail chain.
;
; ⚠ THE TWO FILES DIFFER BY ONE EDGE — the reader's arg-0 is the header φ here
; and the loop-INVARIANT preheader mint there — and they emit, on the pre-fix
; binary, the SAME STREAM. That is exactly the defect: two different programs,
; one circuit. Neither disposition was pinned before these two fixtures existed.
;
; ⚠ WHAT WOULD MAKE THIS FIXTURE GO GREEN FOR THE WRONG REASON: if the fix were
; spelled as "any loop-invariant seed declines" the twin would decline too and
; this file would fail; if it were spelled as a boolean over the walk it would
; accept both and the twin would fail. The pair is the discrimination.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XFCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %body ]
  %i = phi i32 [ 0, %entry ], [ %inext, %body ]
  br label %body
body:
  %rm    = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  %m     = call i32 @cq_measure_si32(i32 %rm)
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %m
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 9.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[H]])

; Counts in their OWN whole-file prefixes (Rule 12 fixture-hygiene (a): a
; positive COUNT inside a negative prefix WINDOWS every negative after it).
; The ry count is TWO, not four: the body's rotation is ROLLED.
; ACNT-COUNT-1: call i32 @cqrt_alloc_i32(
; ACNT-NOT: call i32 @cqrt_alloc_i32(

; RCNT-COUNT-2: call void @cqrt_ry_i32(
; RCNT-NOT: call void @cqrt_ry_i32(

; MCNT-COUNT-1: call i32 @cqrt_measure_i32(
; MCNT-NOT: call i32 @cqrt_measure_i32(

; XFCNT-NOT: call void @cqrt_x(
; XFCNT-NOT: call void @cqrt_free(

; NOQ-NOT: cq_theta_si32
; NOQ-NOT: cq_measure_si32
