; spec_overaccept_probe_invoke_visible.ll — Phase 6.4 WI-4.3 over-accept probe.
; The adversarial case: the callee `@liftable` IS a perfectly specializable body
; (a straight-line two-op i32 value function, the `spec_accept_single` shape), so
; a detection that keyed on the CALLEE shape alone would clone it. It is reached
; by an `invoke`, not a `call` — an `InvokeInst` is excluded by the
; `dyn_cast<CallInst>` SHAPE narrowing, so it never enters `plan6` and STILL fires
; `kMsgUnknownCallee` at the carve-out. Guards against a future weakening that
; classifies the body before checking the call SHAPE.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @__gxx_personality_v0(...)

define i32 @liftable(i32 %a) {
entry:
  %t = add i32 %a, 3
  %r = mul i32 %t, %a
  ret i32 %r
}

define i32 @example(i32 %u0) personality ptr @__gxx_personality_v0 {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = invoke i32 @liftable(i32 %q) to label %ok unwind label %bad
ok:
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
bad:
  %lp = landingpad { ptr, i32 } cleanup
  ret i32 0
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: @__cq_q_liftable
