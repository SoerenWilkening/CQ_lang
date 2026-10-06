; spec_reject_select_mixed_param.ll — DECLINE, a goal-1 GAP (5po2 accept-shape
; boundary; re-pinned by bd p3kd.7.1): a lifted `select` whose CONDITION tests a
; DIFFERENT param than the true arm routes, `select(icmp(c,5), b, 0)`, called with
; `b` quantum and `c` classical: a classical flag over quantum data. Until bd
; p3kd.7.1 the retired `isLiftableSelect` declined it at detection (`InBodyControl`)
; because one compare operand had to BE the true-arm param. `scanBody` now admits
; every select the clone emitter may lower, so the clone is built and
; `lowerCloneSelect`'s taint trichotomy refuses the classical-condition/quantum-arm
; select loudly, at the clone, with its own message. The decline is a gap, not
; physics (a classical choice of rail is realizable); it is the classical-control-
; inside-a-lifted-body mechanism, bd p3kd.7.2, and this fixture flips when it lands.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function __cq_q_helper_01 i32 (i32, i32): cq specialization: mixed classical/quantum select under quantum lift
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
