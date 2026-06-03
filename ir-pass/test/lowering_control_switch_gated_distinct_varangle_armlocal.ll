; lowering_control_switch_gated_distinct_varangle_armlocal.ll — Phase 4.x
; (test_C_libtooling-5bl §9), DECLINE (gate G5 boundary). The G5 widening admits a non-constant
; prep angle ONLY when its def DOMINATES the merge uncompute anchor. Here base qy is prepped IN
; the case-1 arm with an arm-local computed angle `%b = fadd double %u, %v` (also in c1). `%b`
; does NOT dominate `merge` (c1 is just one of the merge's predecessors), so the merge-boundary
; uncompute `cqrt_ry_i32_controlled_inv(¬f_qy, qy, %b)` would reference a value out of scope.
; G5 therefore declines the WHOLE mux to the always-safe WP12 diagnostic (over-declining a
; non-dominating angle is safe). Contrast lowering_control_switch_gated_distinct_varangle.ll,
; where the computed angle lives in `entry` and DOES dominate the merge → lowers.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %x0, i32 %y0, double %u, double %v) {
entry:
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  switch i32 %s, label %dflt [ i32 0, label %c0
                               i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %merge
c1:
  %b = fadd double %u, %v                          ; arm-local angle — does NOT dominate merge
  %qy = call i32 @cq_theta_si32(i32 %y0, double %b)
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  br label %merge
dflt:
  %rd = call i32 @cq_phi_si32(i32 %qx, double 4.000000e-01)
  br label %merge
merge:
  %r = phi i32 [ %r0, %c0 ], [ %r1, %c1 ], [ %rd, %dflt ]
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
