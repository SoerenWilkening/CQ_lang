; control_swap_reject_inloop_value_arm.ll — DECLINE (bd test_C_libtooling-8h7d.5,
; the 7.3 Increment 3 IN-LOOP SCOPE FENCE, part 2). An INTEGER method-B VALUE arm
; inside a classically-bounded loop body:
;
;     for (...) { if (q > 5) q = q + 7; }
;
; The identical diamond OUTSIDE a loop is an ACCEPT — it is 4.2's method-B (`R` →
; `cqrt_copy_<W>` copy-out → reverse-play `R†`). Increment 3 admits only the
; PHASE-arm routed stream inside a loop, and this fixture is the boundary.
;
; WHY, in physics rather than bookkeeping. The phase emitter's route-back is the
; ADJOINT of its split, so `q`'s basis label leaves the region exactly as it
; entered and every ancilla (flag, work rail) is freed inside the iteration —
; nothing dirty crosses the back edge. Method-B's route-back is NOT its adjoint:
; it swaps in the arm's ANSWER on a FRESH `%out` rail, RAUWs the merge to it, and
; keeps the source rail alive (`emitRegion`'s own "B-keep leftover" note). So the
; loop-carried register would be a DIFFERENT handle every trip, nothing proves
; `%out` is `|0>` at the back edge, and the leftover is linear in the trip count.
; `lowerLoops`' X1 (`kMsgCrossIter`) catches the loop-CARRIED spelling of that,
; but not an ITERATION-LOCAL one — so the fence is here, where the whole shape is
; covered, rather than leaning on a guard that covers half of it.
;
; Deferred, not impossible: the 7.x-widenings tracker (bd test_C_libtooling-8h7d)
; owns the in-loop value arm.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %acc = phi i32 [ 0, %entry ], [ %accn, %merge ]
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5                              ; TAINTED condition
  br i1 %c, label %arm, label %merge
arm:
  %p1 = add i32 %p, 3          ; VALUE arm on a NON-condition register (no §3c clobber)
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %loop ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  %accn = add i32 %acc, %m
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n
  br i1 %done, label %loop, label %exit
exit:
  ret i32 %acc
}
