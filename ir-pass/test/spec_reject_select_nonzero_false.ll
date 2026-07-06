; spec_reject_select_nonzero_false.ll — DECLINE (5po2 accept-shape boundary): a
; lifted `select` whose FALSE arm is a non-zero constant needs a SECOND (¬flag)
; controlled copy + `cqrt_x` bracket — outside the slice-1 accept shape
; (`select(icmp(param,k), param, 0)`, ONE controlled copy). `isLiftableSelect`
; requires the false arm to be constant ZERO; `7` declines `InBodyControl`, lowers
; nothing (Prime Directive — over-declining is safe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, i32 %b, i32 7   ; non-zero false arm
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
