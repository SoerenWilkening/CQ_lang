; r22 — AREA 7 (the round-2 §5 "clean" area I trust least, one level over): the
; 4.4 SELECT twin of the shipped `control_phase_kickback_rail_inplace_xor_bridge.ll`
; ACCEPT. That fixture's soundness rests on M-C's G6 ("no data use AFTER the
; site") refusing the in-place `xor` because the BRANCH reads `b` later. The 4.4
; select is ERASED by its own emitter at `lowerControlRegions` (pipeline 377),
; long before `lowerOps`/M-C (558), so by the time G6 asks, the later "data use"
; is an emitted `cqrt_cnot`, not a select. If M-C fires IN PLACE here the
; register is relabelled before the control read and neither the wire walk (it
; only recognizes `cq_theta_` users) nor the re-verification (same walk) can see
; it. Expected safe stream: `cq_template_xor_i1_hl` OUT of place, no `cqrt_xorc`.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %x = xor i1 %b, true
  %c = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  %mc = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %mc to i32
  %t = add i32 %m, %z
  ret i32 %t
}
