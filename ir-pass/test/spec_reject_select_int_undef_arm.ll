; spec_reject_select_int_undef_arm.ll — DECLINE (bd p3kd.7.1 decline fixture for
; the widened select gate, constant-arm clause, integer edition of
; spec_reject_fp_select_undef_arm.ll): an integer select whose false arm is
; `undef`. Since bd p3kd.7.1 an integer `ConstantInt` arm is admitted and
; materialized by `materializeCopySource`; a constant that is not a `ConstantInt`/
; `ConstantFP` (undef, poison, a ConstantExpr) has no defined basis value to
; materialize, so the select still declines `InBodyControl` at detection. The
; select result is dead, so the return cone is clean and the bd 3p2a undef-return
; fence cannot be the one that fires.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function helper i32 (i32): cq specialization: callee contains tainted control flow under quantum lift
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, i32 %b, i32 undef
  %u = add i32 %s, 1
  %r = add i32 %b, 2
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
