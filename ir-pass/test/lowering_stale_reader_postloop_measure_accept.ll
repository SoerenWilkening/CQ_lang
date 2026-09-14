; lowering_stale_reader_postloop_measure_accept.ll — ACCEPT. THE
; `RequireEmitDominance` LEG-2 PIN for bd test_C_libtooling-3d8q: a measurement
; AFTER a loop whose body re-rotates the rail every trip.
;
; `%rm` is the body's merge-of-one, the name the back edge carries; the loop
; header φ `%r` and `%rm` RE-ESTABLISH the record on every trip, so the exit
; read is FRESH. But the exit block dominates nothing in the body, so the shipped
; dominance PRECONDITION refuses before leg 2's record-barrier walk is ever
; reached. `RequireEmitDominance=false` asks leg 2 directly: the only path from
; the body gate to the measurement crosses `%rm`, which `phiTracksWire` proves
; re-establishes the record, so `reachesWithoutBarrier` is FALSE — harmless.
;
; ⚠ WITHOUT THE BIT, 12 shipped Rule-13-cleared in-loop fixtures flip
; (`control_inplace_ry_inloop_*`, `control_swap_inloop_*`). This is the reduced
; form of all of them, with a CLASSICAL condition so no control region is
; involved and the fence is the only thing under test.
;
; ⚠ AND IT IS WHY THE ANALYSIS RUNS EARLY. Asked AFTER `LoopLowering`'s rail-φ
; collapse, the header φ that IS the barrier has been replaced by the
; loop-INVARIANT preheader mint and this module declines — for a fact about the
; compiler's own rewrite. `recordStaleQuantumReaders` therefore runs beside
; `declineStaleRecordOps`, before `lowerLoops`; only the DIAGNOSTIC is deferred.
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
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 9.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[H]])

; Counts in their OWN whole-file prefixes. Added by the injection matrix:
; `dup_first_ry`, `extra_ry`, `extra_x`, `extra_free`, `extra_alloc` and
; `dup_measure` were each caught by NO block. ⚠ The ry count is TWO, not four:
; the body's rotation is ROLLED (one gate inside the loop, IR size independent of
; the trip count), which is also the property a `dup_first_ry` mutant breaks.
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
