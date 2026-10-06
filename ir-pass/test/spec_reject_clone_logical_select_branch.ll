; spec_reject_clone_logical_select_branch.ll — DECLINE, a goal-1 GAP (bd p3kd.7.1
; decline fixture for the widened select gate): `if (b > 0 && b < 10)` spelled the
; way `clang -O1` spells a short-circuit `&&`, as the i1 LOGICAL select
; `select i1 %a, i1 %c, i1 false`, feeding a tainted branch inside a lifted callee.
; Since bd p3kd.7.1 `scanBody` admits the i1 select, so the candidate is cloned.
; The clone's PredMux leaves the region at `E6-condtree` (its condition grammar
; does not take the logical-select spelling; the top-level control emitters do),
; the diamond survives, and the `lowerCloneControl` backstop declines loudly,
; naming the CLONE. Openlibm's acoshl/coshl/sinhl/tanhl/nextafter/fmod/remquo carry
; this spelling; this fixture flips when the clone's condition network takes it
; (bd p3kd.7.5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function __cq_q_helper_1 i32 (i32): cq specialization: callee contains tainted control flow under quantum lift
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %a = icmp sgt i32 %b, 0
  %c = icmp slt i32 %b, 10
  %l = select i1 %a, i1 %c, i1 false
  br i1 %l, label %t, label %f
t:
  %tb = add i32 %b, 7
  br label %m
f:
  %fb = mul i32 %b, 3
  br label %m
m:
  %r = phi i32 [ %tb, %t ], [ %fb, %f ]
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
