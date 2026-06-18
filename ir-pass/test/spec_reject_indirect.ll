; spec_reject_indirect.ll — Phase 6.1 WI-1.4: a tainted call through a function
; pointer (null `getCalledFunction()`) is NOT a candidate — there is no visible
; body to clone, and the null-callee check guards the body inspection. It never
; enters `plan6` and STILL fires `kMsgUnknownCallee` (and `readsTaintedValue`
; trips on the tainted argument).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, ptr %fp) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 %fp(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
