; lowering_control_angle_switch_crossblock.ll — Family B2, gated-switch, NEGATIVE
; (test_C_libtooling-byx, adversarial-review regression lock, 2026-06-03). The
; gated-switch analog of lowering_control_angle_diamond_crossblock.ll: a gated
; switch whose classical-angle merge `φ` feeds a rotation %rE in the merge block
; AND a rotation %rL in a CFG-later `tail` block.
;
; reduceAngleSwitchPhi shares the single-block anchorAfterLastConsumer assumption
; — a cross-block consumer would have its per-case controlled rotations fire on
; already-uncomputed eq-flags (verify-clean SILENT miscompile). The single-block
; consumer check in usersAreAngleFeeds (via classifyAngleMerge) rejects this, so
; it is DIAGNOSED rather than mislowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: cqrt_rz_i32_controlled
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
tail:
  %rL = call i32 @cq_phi_si32(i32 %v, double %ang)
  %m = call i32 @cq_measure_si32(i32 %rL)
  ret i32 %m
merge:
  %ang = phi double [ 1.000000e+00, %c0 ], [ 2.000000e+00, %c1 ], [ 3.000000e+00, %def ]
  %rE = call i32 @cq_phi_si32(i32 %v, double %ang)
  br label %tail
}
