; lowering_control_switch_gated_mixedphi.ll — Phase 4.x WP18 follow-on
; (test_C_libtooling-6qg), NEGATIVE safety lock (adversarial review 2026-06-03).
; A gated `switch` whose merge φ MIXES a tainted gate-handle incoming (`%v1` from
; case 1, the in-place handle) with CLASSICAL-CONSTANT incomings (1000 on case 7,
; 2000 on default). `lowerGatedSwitch` step 4 dissolves a handle φ by RAUW to a
; tainted incoming, ASSUMING every incoming is that same in-place handle. Under a
; partial-taint mix that assumption is false: RAUW to `%v1` would silently DROP
; the classical case-7 / default edges, returning the raw handle id unconditionally
; — a verify-clean WRONG result (the gated path has no data-mux lowering, unlike
; the `br`-diamond's `reduceClassicalMux`, and cannot tell a value-propagated
; constant-equal-to-the-handle from a genuine distinct value). The detection guard
; requires EVERY incoming of a non-angle φ to be tainted, so this DECLINES to the
; WP12 "switch under quantum control" diagnostic — never a silent miscompile.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_rz_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  switch i32 %q, label %dflt [ i32 1, label %c1
                               i32 7, label %c7 ]
c1:
  %v1 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c7:
  br label %merge
dflt:
  br label %merge
merge:
  %mphi = phi i32 [ %v1, %c1 ], [ 1000, %c7 ], [ 2000, %dflt ]
  ret i32 %mphi
}
