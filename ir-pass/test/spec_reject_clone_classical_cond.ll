; spec_reject_clone_classical_cond.ll — Phase 6 / issue 5po2 I2 (over-accept
; probe): a CLASSICAL condition selecting between QUANTUM arms stays DECLINED. The
; callee `helper(b, k) = (k>5) ? b+1 : b+2` is called with `b` tainted and `k`
; CLASSICAL (a pass-through arg, mask bit clear). clang if-converts it to
; `select(icmp %k, %b+1, %b+2)`. In the clone the condition `icmp(%k,5)` compares
; only classical operands, so `lowerCloneSelect`'s taint trichotomy sees
; `!CondT && (TrueT||FalseT)` — classical control over quantum data, the
; unforgivable mixed shape — and LOUD-declines it (never lowers a classical flag
; over a quantum mux). Over-declining is safe (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %k) {
entry:
  %c = icmp sgt i32 %k, 5
  %r1 = add i32 %b, 1
  %r2 = add i32 %b, 2
  %r = select i1 %c, i32 %r1, i32 %r2
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %kk) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %kk)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: mixed classical/quantum select under quantum lift
; CHECK-NOT: cqrt_copy_i32_controlled
