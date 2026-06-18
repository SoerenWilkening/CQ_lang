; spec_reject_inbody_control.ll — Phase 6.1 WI-1.6b: a pure-classical callee
; whose tainted parameter reaches in-body CONTROL FLOW (`br` on `icmp %a, 5`) is
; loudly declined. 6.1's accepted body set is STRAIGHT-LINE value functions only
; (the open Rule-13 item, §8): in-body tainted control × the Bennett whole-body
; reverse is a genuine boundary hazard (swap-route's region-internal balanced
; control gates vs. the captured data stream) this plan does not yet prove. A
; multi-block body (a branch) declines until that lands as its own
; red→green→clear WI. Fired in the detection pre-pass; recorded in
; `plan6.Diagnosed`, so the generic `kMsgUnknownCallee` is not also emitted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @branchy(i32 %a) {
entry:
  %c = icmp sgt i32 %a, 5
  br i1 %c, label %t, label %f
t:
  ret i32 100
f:
  ret i32 200
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @branchy(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cq taint escape
