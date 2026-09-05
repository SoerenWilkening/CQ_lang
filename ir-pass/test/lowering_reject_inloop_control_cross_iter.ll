; lowering_reject_inloop_control_cross_iter.ll — DECLINE (bd test_C_libtooling-8h7d.5):
; the X1 CROSS-ITERATION DIRTY RAIL, reached through the NEW round-2 path.
;
;     for (...) { if (q > 5) q = cq_phi(q, b); q = q * 3; }
;
; The tainted region itself is admissible (flat, phase, wholly inside a reducible
; loop) and IS emitted + flattened. What is not admissible is the loop-carried
; register: `%qn = mul %qm, 3` is not a reversible in-place bijection of the rail
; (a `mul` has no `cqrt_mulc`), so the value crossing the back edge is a FRESH
; out-of-place rail each trip while the collapse would have serialised every trip
; onto ONE handle. `collapseFlattenedLoopRails` sees the latch incoming fail to
; peel back to the header phi, finds the peel base tainted, and fires the SAME
; `kMsgCrossIter` round 1 fires for the control-free spelling
; (lowering_reject_loop_cross_iter.ll) — one message, two entry points (Rule 14).
;
; THIS IS THE FIXTURE THAT PROVES THE X1 DECLINE SURVIVED THE FLATTEN. Round 1
; cannot reach it (gate L2 leaves any loop with in-body tainted control
; unclaimed), so before Increment 3 this program declined at the d8jl guard and
; X1 was never asked. If round 2 is ever dropped, this goes to a broken module or
; a silently serialised rail rather than a message.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = mul i32 %q, 3                                 ; NOT an in-place rail op
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %qn)
  ret i32 %m
}
