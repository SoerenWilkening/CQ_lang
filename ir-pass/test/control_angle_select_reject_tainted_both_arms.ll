; control_angle_select_reject_tainted_both_arms.ll — DECLINE (S1): BOTH angle
; operands tainted, reached through `fpext` carriers (bd drbq Inc 2b).
;
; The sibling of `..._reject_tainted_arm.ll` with the other polarity of the same
; fence, and with the taint arriving through a value-preserving CAST rather than
; directly — so it also pins that S1 asks `taint.Tainted`, which the carrier
; propagates through, rather than pattern-matching a rotation result.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare float @cq_theta_f32(float, double)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %f1 = call float @cq_theta_f32(float 1.000000e+00, double 2.500000e-01)
  %f2 = call float @cq_theta_f32(float 2.000000e+00, double 2.500000e-01)
  %d1 = fpext float %f1 to double
  %d2 = fpext float %f2 to double
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %d1, double %d2
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
