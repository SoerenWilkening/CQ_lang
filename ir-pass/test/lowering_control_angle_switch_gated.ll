; lowering_control_angle_switch_gated.ll — Family B1, gated-switch form
; (test_C_libtooling-cwk sibling, discovered while verifying the diamond fix).
; The `SwitchRegion` analog of lowering_control_angle_diamond.ll: a gated
; multi-arm `switch` on a tainted scrutinee whose arms apply gate sequences and
; reconverge on a merge that ALSO carries a classical `phi double` (a rotation
; angle dispatched per case).
;
; `lowerGatedSwitch` dissolves only the TAINTED (handle) merge φ; before this
; guard the classical-double φ was left undissolved and the switch was then
; linearized away, leaving the φ with no live predecessors — a broken module
; ("PHI nodes not grouped"). Detection now diagnoses a classical-FP merge φ on a
; gated switch as "rotation angle under quantum control", the same surface as the
; br-diamond form. (Lowering the diamond/switch-form angle dispatch as
; controlled-rotation-by-difference is the cwk follow-on.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  switch i32 %q, label %def [ i32 0, label %c0
                              i32 1, label %c1 ]
c0:
  %g0 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c1:
  %g1 = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  br label %merge
def:
  %gd = call i32 @cq_phi_si32(i32 %v, double 3.000000e-01)
  br label %merge
merge:
  %ang = phi double [ 1.000000e+00, %c0 ], [ 2.000000e+00, %c1 ], [ 3.000000e+00, %def ]
  %r = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
