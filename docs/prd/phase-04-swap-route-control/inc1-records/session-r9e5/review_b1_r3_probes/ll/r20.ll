; r20 — THE READ-POINT GAP, no taint window at all. The Rz-stem ANGLE SELECT is
; the ONE consumer whose emission point is NOT the position its classifier asks
; about: `SelectClassify`'s rail ladder asks the DT prong with `EmitPoint = Sel`,
; while `emitPhaseAngleSelect` emits its two `cqrt_rz_i1` at the CONSUMING
; `cq_phi` `T`, which is LATER. A chained theta BETWEEN `Sel` and `T` is
; therefore "provably after Sel" (classifier: accept) and BEFORE the gate that
; actually fires (the truth: the kickback reads a register the theta moved).
; The fix's re-ask anchors on the RECORDED READ, so it should decline.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i1 @main2(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %a = select i1 %b, double 9.000000e-01, double 3.000000e-01
  %b2 = call i1 @cq_theta_i1(i1 %b, double 3.000000e-01)
  call void @cq_phi(double %a)
  %m = call i1 @cq_measure_i1(i1 %b2)
  ret i1 %m
}
