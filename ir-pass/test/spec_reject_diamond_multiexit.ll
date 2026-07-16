; spec_reject_diamond_multiexit.ll — Phase 6 / issue 5po2: a MULTI-EXIT (early
; return) tainted diamond in a lifted callee stays DECLINED after the I1
; single-exit merge-phi increment. This is the fp80-transcendental shape
; (openlibm expl: `if (x>MAXLOGL) return C; ... return f(x)`) — a controlled
; early-return guarding an expensive tainted fall-through, tracked as the I2
; increment (controlled-return-in-clone), NOT part of I1. It must keep declining
; loudly until that increment lands (Prime Directive: over-decline is safe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %t = icmp sgt i32 %b, 100
  br i1 %t, label %early, label %main
early:
  ret i32 999
main:
  %a = add i32 %b, 7
  ret i32 %a
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: cq specialization: callee contains tainted control flow under quantum lift
