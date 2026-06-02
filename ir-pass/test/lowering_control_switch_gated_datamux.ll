; lowering_control_switch_gated_datamux.ll — Phase 4.x WP18 follow-on
; (test_C_libtooling-6qg), NEGATIVE safety lock (adversarial check 2026-06-03).
; A gated `switch` whose merge carries a gate-handle φ (lowerable) AND a
; wholly-classical CONSTANT-data φ (`%dphi`, a classical value the switch selects
; and that is used after the switch). The value-merge normalizer (WP15) declines
; this — an arm is NON-empty (it gates a handle) — so it reaches the gated path.
; `lowerGatedSwitch` dissolves only tainted-handle φ (RAUW) and recorded angle φ
; (`reduceAngleSwitchPhi`); it does NOT lower a classical DATA mux (no
; `reduceClassicalMux`, unlike the `br`-diamond `dissolveBranchPhi`). Building a
; region would strand `%dphi` with no live predecessors after linearization (a
; `<badref>` φ → `report_fatal_error`). `tryBuildGatedSwitchRegion` DECLINES on
; the non-handle/non-angle φ, and the WP12 fallback diagnoses — never a crash.
; (Locks that the shared-arm case-set support did not open a broken-module path.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_rz_i32_controlled
; CHECK-NOT: badref
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_add_si32(i32, i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  switch i32 %q, label %dflt [ i32 1, label %c1
                               i32 2, label %c2 ]
c1:
  %v1 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c2:
  br label %merge
dflt:
  br label %merge
merge:
  %hphi = phi i32 [ %v1, %c1 ], [ %v, %c2 ], [ %v, %dflt ]
  %dphi = phi i32 [ 11, %c1 ], [ 22, %c2 ], [ 99, %dflt ]
  %r = call i32 @cq_add_si32(i32 %hphi, i32 %dphi)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
