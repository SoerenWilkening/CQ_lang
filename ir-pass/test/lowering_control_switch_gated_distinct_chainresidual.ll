; lowering_control_switch_gated_distinct_chainresidual.ll — Phase 4.x (test_C_libtooling-u5f),
; DECLINE (G2 chain-root boundary). PROVES the u5f G2/G3 widening did NOT over-accept:
; base qy is a chain `cq_theta(cq_phi(cq_theta(z0,.9),.3),.7)` whose descent stops at a
; NON-theta tainted node — the `cq_phi(%qz,.3)` prep-Rz sits BELOW the outer theta, so
; the theta-only chain walk cannot reach a classical root (the chain root `%qyp` is a
; tainted `cq_phi`, not a fresh classical seed). The ry/rz-only reverse-inverse chain
; the MUX-EXCH uncompute emits is anchored on the base handle's own uncontrolled preps;
; it cannot reproduce a prep whose root is itself an entangled quantum value. The whole
; mux declines to the always-safe WP12 diagnostic (over-decline-safe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %x0, i32 %z0) {
entry:
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  %qz = call i32 @cq_theta_si32(i32 %z0, double 9.000000e-01)
  %qyp = call i32 @cq_phi_si32(i32 %qz, double 3.000000e-01)
  %qy = call i32 @cq_theta_si32(i32 %qyp, double 7.000000e-01)
  switch i32 %s, label %dflt [ i32 0, label %c0
                               i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %merge
c1:
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
