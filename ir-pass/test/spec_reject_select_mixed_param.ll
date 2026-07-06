; spec_reject_select_mixed_param.ll — DECLINE (5po2 accept-shape boundary, the
; load-bearing safety gate): a lifted `select` whose CONDITION tests a DIFFERENT
; param than the true arm routes — `select(icmp(c,5), b, 0)`. If `b` is quantum
; and `c` classical this is a classical flag over quantum data (a mixed
; classical-control-over-quantum-data select) with NO single proven lowering.
; `isLiftableSelect` requires one compare operand to BE the true-arm param, so
; condition and data share taint by construction; this cross-param shape declines
; `InBodyControl`, lowers nothing (Prime Directive). The clone is built (arg 0 is
; tainted) but the select is never emitted as a controlled copy.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c) {
entry:
  %t = icmp slt i32 %c, 5            ; condition tests %c, true arm routes %b
  %s = select i1 %t, i32 %b, i32 0
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %u1)   ; arg0 tainted, arg1 classical
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
