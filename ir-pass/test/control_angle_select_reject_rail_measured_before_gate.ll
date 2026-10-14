; control_angle_select_reject_rail_measured_before_gate.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, S11): the bare `_Bool` condition is MEASURED between
; the angle select and its consumer.
;
; Gate 2's rail rung (ii) asks "measured before the control route?" with the
; SELECT as read point, which is exact for the 4.4 data select (its stream lands
; before the select). This stream's first read of the rail is the copy `cnot`,
; emitted immediately before the CONSUMER, after the measurement. S11 re-asks
; the rung with the consumer as read point — the same helper and seed set.
; Without it the copy would read a collapsed register the source read coherent.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: condition measured before the control route under quantum control

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %t0 = call i1 @cq_theta_i1(i1 false, double 4.000000e-01) #0
  %ang = select i1 %a, double 0x3FE6666666666666, double 3.000000e-01
  %ma = call i1 @cq_measure_i1(i1 %a)
  %t = call i1 @cq_theta_i1(i1 %t0, double %ang) #0
  %mt = call i1 @cq_measure_i1(i1 %t)
  %za = zext i1 %ma to i32
  %zt = zext i1 %mt to i32
  %s = add i32 %za, %zt
  ret i32 %s
}

attributes #0 = { nomerge nounwind }
