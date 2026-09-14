; lowering_reject_stale_reader_inloop_repeatable_guard.ll — DECLINE.
;
; THE RULE-12 NEGATIVE FOR leg 1b OF `readerStalesItself` (bd
; test_C_libtooling-3d8q, Rule-13 round-2 finding F-D2-2). It is
; `lowering_stale_reader_inloop_once_guarded_accept.ll` with ONE token changed —
; the guard `icmp eq %i, 0` (provably false on every arrival from the latch)
; becomes `icmp slt %i, %n` on a FUNCTION ARGUMENT, which can hold on many trips:
;
;   int q = cq_theta(0, 0.3);
;   for (int i = 0; i < 3; i++)
;     if (i < n) { int b = cq_theta(q, 0.1); s += cq_measure(b); } else s += 1;
;
; With `n >= 2` the reader runs twice on the loop-INVARIANT `q`: at trip 2 the
; name `q` denotes `Ry(.25)|0>` while the register holds `Ry(1.15)|0>`. That is
; CLAUDE.md CORRECTNESS RISK §2's rail-staleness rule verbatim and the 2026-09-14
; owner ruling's exact subject — the source admits two realizable circuits and
; names neither.
;
; ⚠ THE FENCE CANNOT TELL THIS FROM THE ACCEPT BY LOOKING AT THE SOURCE SHAPE —
; both are "a `cq_theta` in a block guarded by a compare on the induction
; variable, inside a loop, on an invariant seed". The discrimination is
; ScalarEvolution's answer to the guard REWRITTEN ONTO THE LATCH EDGE, and here
; there is none: nothing proves `%inext >= %n`. Leg 1b returns "not provable",
; which is the DECLINE direction — the Prime Directive's own shape.
;
; ⚠ IF THIS FILE EVER ACCEPTS, leg 1b has become an OVER-ACCEPT in the
; unforgivable class (two different programs, one circuit — bd 3d8q's own
; definition of the defect). It is the negative that makes the F-D2-2 widening a
; red-green change rather than a relaxation.
;
; RETIREMENT TRIGGER: this stays a DECLINE for as long as the guard is a runtime
; comparison. It would become an over-decline only if the pass gained a proof
; that `%n <= 1` at this call site — which is an interprocedural fact this pass
; does not have and does not seek.
;
;
; ⚠ Rule 12 fixture-hygiene (b): a `DS_Error` decline writes 0 bytes to stdout,
; so the property is pinned by the `not` inversion on the RUN line plus the CHECK
; on stderr — never by an IR-text `CHECK-NOT`, which would be vacuous.

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %s = phi i32 [ 0, %entry ], [ %snext, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %g = icmp slt i32 %i, 2
  br i1 %g, label %read, label %latch
read:
  %b = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %b)
  br label %latch
latch:
  %add   = phi i32 [ %m, %read ], [ 1, %loop ]
  %snext = add nsw i32 %s, %add
  %inext = add nuw nsw i32 %i, 1
  %done  = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %snext
}

