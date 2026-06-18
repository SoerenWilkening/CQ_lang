; spec_reject_recursion.ll — Phase 6.3 WI-3.1: a recursive callee on the accepted
; subset has no static depth bound and is declined LOUDLY at the recursive call.
; Both forms reject with the same pinned message (mirrors `kMsgRecursion`
; char-for-char, Rule 12): a SELF call (the direct cycle) and a MUTUAL `ping`/`pong`
; cycle (the call-graph cycle the transitive worklist's DFS stack detects — the
; case that was a verify-clean "nested call" mis-message before 6.3). Both bodies
; are deliberately single-BB straight-line so the recursion verdict is reached
; BEFORE the in-body-control verdict (a real `if`-guarded recursion would decline
; as InBodyControl first — that is a separate axis).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=MUTUAL %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; --- self-recursion ----------------------------------------------------------
define i32 @selfrec(i32 %a) {
entry:
  %b = sub i32 %a, 1
  %r = call i32 @selfrec(i32 %b)
  %y = mul i32 %r, %a
  ret i32 %y
}

; --- mutual recursion --------------------------------------------------------
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

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s1 = call i32 @selfrec(i32 %q)
  %s2 = call i32 @ping(i32 %q)
  %m1 = call i32 @cq_measure_si32(i32 %s1)
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret void
}

; CHECK: error{{.*}}cq specialization: recursive callee has no static depth bound
; MUTUAL: error{{.*}}cq specialization: recursive callee has no static depth bound
