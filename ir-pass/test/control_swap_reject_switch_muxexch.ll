; control_swap_reject_switch_muxexch.ll — DECLINE: distinct-base TAINTED data-mux
; incomings (MUX-EXCH). Two distinct cq_theta handles selected by the switch — a
; quantum multiplexer; freeing superposed sources needs cswap (Rule 8). FIRING
; PATH (verified): a cq_theta handle is a phase leaf (isValueChangingOp == false),
; so caseArmClass classifies these arms PHASE; proveSwitchPhase then declines
; because the arm base is a tainted handle, not a ConstantInt equal to the case
; literal (the const-fold re-anchor signature fails) -> "control flow". Over-decline
; is always safe (Prime Directive).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qa = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %qb = call i32 @cq_theta_si32(i32 %u2, double 4.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %qa, %a0 ], [ %qb, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
