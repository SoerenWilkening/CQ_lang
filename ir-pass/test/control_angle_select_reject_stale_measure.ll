; control_angle_select_reject_stale_measure.ll — a pre-gate SSA record of
; the rotated rail is measured after an angle-select Ry (bd drbq Inc 2b).
;
; Both %r and %t lower to the same physical handle. Measuring %r after the
; gate would observe the post-Ry state instead of the earlier record it names.
; This pins the loud stale-record fence until that record can be preserved.
; control_angle_select_ry_alias_pre_gate.ll puts the read before the gate.
; The retired diagonal alias hops no longer occur in this input.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  %mm = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %mm
  ret i32 %s
}
