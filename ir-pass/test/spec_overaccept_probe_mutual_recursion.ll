; spec_overaccept_probe_mutual_recursion.ll — Phase 6.4 WI-4.3 over-accept probe.
; `@ping`/`@pong` are each a visible, single-BB, straight-line i32 body that
; LOOKS liftable in isolation — but they form a mutual call-graph CYCLE, so the
; convergence argument (the accepted subset must be acyclic, §2.8) fails. The DFS
; `OnStack` set detects the cycle when `scanBody(@ping)` recurses into `@pong`
; which calls `@ping` (already on the stack) and declines loudly. Guards against a
; weakening of cycle detection that would clone-recurse forever or over-accept an
; unbounded body.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ping(i32 %a) {
entry:
  %b = sub i32 %a, 1
  %r = call i32 @pong(i32 %b)
  ret i32 %r
}

define i32 @pong(i32 %a) {
entry:
  %b = sub i32 %a, 1
  %r = call i32 @ping(i32 %b)
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @ping(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: recursive callee has no static depth bound
; CHECK-NOT: @__cq_q_
