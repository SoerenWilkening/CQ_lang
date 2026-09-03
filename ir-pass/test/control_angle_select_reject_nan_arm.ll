; control_angle_select_reject_nan_arm.ll — DECLINE (S1, the ARM-VALUE fence): the
; TRUE arm is a quiet NaN `ConstantFP`.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens L7-F2), the NaN cell of the
; non-finite family. `fl(NaN − 0.3) = NaN`, so the stream is
;
;     ry(h, 0.3) ; ry_controlled(f, h, NaN)
;
; and the FALSE edge is fine while the TRUE edge is a NaN rotation. The reason to
; fence it separately from `+inf` is that the two reach the same wrong stream by
; different arithmetic — an inf arm can produce a FINITE difference (inf − inf is
; NaN, but 1.0 − inf is −inf) while a NaN arm always propagates — so a repair that
; only checked `isInfinity()` would leave this cell green.
;
; This is the same clause as `control_angle_select_reject_inf_arm.ll`
; (`!ConstantFP::getValueAPF().isFinite()`), and the same distinction applies: an
; UNCONTROLLED user-written NaN angle is pre-existing and untouched; what 2b must
; not do is manufacture one for an arm the source wrote finite.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 0x7FF8000000000000, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
