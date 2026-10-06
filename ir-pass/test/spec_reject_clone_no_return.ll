; spec_reject_clone_no_return.ll — DECLINE (bd p3kd.7.1 review rounds 1 and 2):
; a lifted callee with no `ret` anywhere. Its parameter stays live through a tainted
; branch (every terminator is a liveness root, DeadValueLiveness.cpp), so the dead-
; argument drop keeps the quantum slot and the site is a candidate. `scanBody`
; admits `unreachable` since bd p3kd.7.1; the clone's PredMux flattens the empty
; triangle, the block merge leaves ONE block ending in `unreachable`, and the
; Bennett wrap finds no `ret` to copy out at. The wrap used to return false
; silently with the result dropped by `buildClone` (an unwrapped clone at exit 0);
; it now declines loudly. Every call of such a callee is UB, so no valid program is
; lost.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function __cq_q_g_1 i32 (i32): cq specialization: lifted callee never returns under quantum lift
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @g(i32 %x) {
entry:
  %c = icmp sgt i32 %x, 0
  br i1 %c, label %a, label %m
a:
  br label %m
m:
  unreachable
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @g(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
