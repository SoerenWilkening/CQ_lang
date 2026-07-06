; spec_reject_select_derived_true.ll — DECLINE (5po2 accept-shape boundary): a
; lifted `select` whose TRUE arm is a DERIVED value (`b+1`), not a direct param.
; Slice 1 accepts only a param-direct true arm (`select(icmp(param,k), param, 0)`)
; so the condition and the routed data provably share the same param (and thus
; taint). A derived true arm is a wider shape (the derived op must itself be
; captured + reversed) deferred past slice 1 — declines `InBodyControl`, lowers
; nothing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %d = add i32 %b, 1
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, i32 %d, i32 0   ; derived (non-param) true arm
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
