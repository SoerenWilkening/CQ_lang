; lowering_stale_reader_inloop_once_flag_accept.ll — ACCEPT.
;
; THE SECOND SPELLING of `lowering_stale_reader_inloop_once_guarded_accept.ll`
; (bd test_C_libtooling-3d8q, Rule-13 round-2 finding F-D2-2), and it is a
; separate fixture because `clang -O1` lowers it to a DIFFERENT IR SHAPE that the
; same predicate must handle through a different evaluator:
;
;   int q = cq_theta(0, 0.3); int first = 1;
;   for (int i = 0; i < 3; i++)
;     if (first) { int b = cq_theta(q, 0.1); s += cq_measure(b); first = 0; }
;     else s += 1;
;
; `-O1` turns the `first` flag into an `i1` HEADER φ with CONSTANT incomings —
; `[ false, %entry ], [ true, %latch ]`, polarity inverted, the reader on the
; FALSE edge (Rule 9). ScalarEvolution models no `i1` φ, so the `icmp`-on-the-IV
; evaluator that decides the sibling fixture answers NOTHING here; the one-shot
; FLAG evaluator reads the latch incoming off the φ directly. Two evaluators, one
; predicate, one question ("what is the guard worth on every arrival from the
; latch?") — `WireWalk.cpp`, `guardValueOnLatchEdge`.
;
; ⚠ IF SOMEONE FOLDS THE TWO EVALUATORS INTO ONE, this file is the one that
; fails: it is the only fixture in the tree whose guard is an `i1` φ rather than
; a compare. Its sibling would keep passing and the regression would be silent in
; the C spelling everyone actually writes.
;
; The emitted stream is BYTE-IDENTICAL to the sibling's, and to what the
; pre-fence compiler emitted for both (measured, `ob1b_first_iteration_flag.c`,
; trace 4 lines) — which is why declining it was an over-decline and not a fence.
;

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %s = phi i32 [ 0, %entry ], [ %snext, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %f = phi i1  [ false, %entry ], [ true, %latch ]
  br i1 %f, label %latch, label %read
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


; ACNT-COUNT-1: call i32 @cqrt_alloc_i32(
; ACNT-NOT: call i32 @cqrt_alloc_i32(

; RCNT-COUNT-2: call void @cqrt_ry_i32(
; RCNT-NOT: call void @cqrt_ry_i32(

; MCNT-COUNT-1: call i32 @cqrt_measure_i32(
; MCNT-NOT: call i32 @cqrt_measure_i32(

; NOQ-NOT: cq_theta_si32
; NOQ-NOT: cq_measure_si32
