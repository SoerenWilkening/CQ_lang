; spec_reject_clone_loop.ll — Phase 6 / issue 5po2 I2 (over-accept probe): a
; tainted-controlled LOOP in a lifted callee stays DECLINED. I2 lifts ACYCLIC
; controlled-return / value-diamond control (via `normalizeReturnMerge` + the
; scoped PredMux flatten); a loop is CYCLIC, so PredMux's E2 leaves it — ⚠ since bd fn1q increment 3 NOT
; because "E2 is acyclic" (it now admits a region strictly inside one loop body)
; but because this region STRADDLES: measured `gate=E2-loopstraddle`. The verdict
; and the diagnostic are unchanged; the recorded REASON was wrong (Rule-13 round 2),
; `MergeBlockIntoPredecessor` cannot fold a conditional back-edge, and the
; `lowerCloneControl` `Clone.size() != 1` backstop LOUD-declines it. Bounded loops
; in a clone are a later increment (7.3 territory inside specialization); over-
; declining is safe (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ %b, %entry ], [ %acc2, %loop ]
  %acc2 = add i32 %acc, %i
  %i2 = add i32 %i, 1
  %c = icmp slt i32 %i2, %b
  br i1 %c, label %loop, label %done
done:
  ret i32 %acc2
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
