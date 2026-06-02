; lowering_control_switch_gated_extrapred.ll — Phase 4.x WP18 follow-on
; (test_C_libtooling-6qg), NEGATIVE safety lock. The switch's merge block has an
; EXTRA predecessor (`pre`) that is NOT one of the switch arms and not the switch
; block itself — the merge φ reconverges a path from OUTSIDE the switch region.
; This is not a clean gated-switch dispatch: the φ's `pre` incoming is not gated
; by any case, so the per-arm controlled substitution cannot account for it.
; `tryBuildGatedSwitchRegion` DECLINES (the extra-merge-predecessor check), and
; the WP12 fallback diagnoses "switch under quantum control" — never mislowered.
; (Locks that shared-arm support did not loosen this guard.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_rz_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %pc = icmp eq i32 %c, 0
  br i1 %pc, label %pre, label %sw
pre:
  %vp = call i32 @cq_phi_si32(i32 %v, double 7.000000e-01)
  br label %merge
sw:
  switch i32 %q, label %dflt [ i32 1, label %c1
                               i32 2, label %c2 ]
c1:
  %v1 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c2:
  %v2 = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  br label %merge
dflt:
  %vd = call i32 @cq_phi_si32(i32 %v, double 9.000000e-01)
  br label %merge
merge:
  %vm = phi i32 [ %vp, %pre ], [ %v1, %c1 ], [ %v2, %c2 ], [ %vd, %dflt ]
  %m = call i32 @cq_measure_si32(i32 %vm)
  ret i32 %m
}
