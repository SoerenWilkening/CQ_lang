; lowering_reject_uncompute_loopsink_keeps_decline.ll — NEGATIVE (Phase 5 §2.4).
; The at-most-once guard must NOT swallow the loud divergent-arm decline.
;
; bd 261j(a) risk 1, in its own words: a change that returns EARLIER than a loud
; diagnostic converts `opt` rc=1 into a silent rc-0 accept, and the Prime Directive's
; whole point is that a loud reject is a feature. The first draft of the §2.9
; at-most-once guard sat BEFORE the every-gate-dominates-`At` scan, and MEASURED on
; exactly this module it turned `cq uncompute: dead chain spans divergent
; control-flow arms` (rc=1) into rc=0 with the whole DAG silently leaked. The shipped
; guard runs AFTER that scan, so the diagnostic still wins.
;
; This module has BOTH properties at once, which is what makes it the pin: a
; loop-resident preserving sink (so the at-most-once guard is live) AND a recovered
; gate that does not dominate the insertion point (so the divergent-arm decline is
; owed). Exactly one of them may fire, and it must be the loud one.
;
; MEASURED at HEAD 1ec8c45 and on the bd uow0-only pass: rc=1, this diagnostic.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)

define void @loopsink_keeps_decline(i32 %u0, i32 %n, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = add i32 %q, 1
  %b = add i32 %a, 2                      ; dead terminal, anchored in %entry
  %tape = call i32 @cqrt_tape_alloc()
  br label %loop

loop:                                     ; the preserving read is LOOP-RESIDENT
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %w = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %a)
  %i1 = add i32 %i, 1
  %cc = icmp slt i32 %i1, %n
  br i1 %cc, label %loop, label %post

post:                                     ; a gate that does NOT dominate the anchor
  br i1 %c, label %arm, label %join

arm:
  %z = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %g = add i32 %z, 7
  br label %join

join:
  ret void
}

; The message is mirrored CHARACTER-FOR-CHARACTER from Uncomputation.cpp's
; kMsgDivergentArm so code and fixture cannot drift (Rule 12):
; CHECK: cq uncompute: dead chain spans divergent control-flow arms
