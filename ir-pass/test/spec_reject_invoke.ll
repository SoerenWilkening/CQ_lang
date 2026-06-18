; spec_reject_invoke.ll — Phase 6.1 WI-1.3: a tainted-arg `invoke` of a visible
; body is NOT a `CallInst` (the `dyn_cast<CallInst>` narrowing excludes
; `InvokeInst`), so it never enters `plan6` and STILL fires `kMsgUnknownCallee`
; at the carve-out (C6). An invoke is a terminator with normal + unwind
; successors — terminator surgery the call-position lowering has no story for.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @__gxx_personality_v0(...)

define i32 @helper(i32 %x) {
entry:
  %y = add i32 %x, 1
  ret i32 %y
}

define i32 @example(i32 %u0) personality ptr @__gxx_personality_v0 {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = invoke i32 @helper(i32 %q) to label %ok unwind label %bad
ok:
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
bad:
  %lp = landingpad { ptr, i32 } cleanup
  ret i32 0
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
