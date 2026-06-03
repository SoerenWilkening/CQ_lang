; lowering_control_switch_gated_distinct_wrongarmmut.ll — Phase 4.x (npu.5/.6),
; DECLINE (gate G3b — per-arm correspondence). A distinct-base mux (case0→qx,
; case1→qy, default→qx) where arm c0 (which SELECTS qx) also applies a STRAY gate
; `cq_phi(qy, .77)` to qy — case-1's base. That gate lowers to
; `cqrt_rz_controlled(f0 = s==0, qy, .77)`, firing on a branch (s==0) where qy is
; NOT selected; the single `cqrt_ry_i32_controlled_inv(¬f_qy, qy, .5)` uncompute
; cannot undo the stray Rz, so qy would stay entangled with the scrutinee and
; regOut would decohere — a verify-clean SILENT MISCOMPILE. The G3 set-membership
; walk alone misses it (the stray gate IS in an arm shadow); the per-arm
; correspondence check rejects a gate mutating q from an arm whose φ-edge does not
; carry q. Declines to the always-safe WP12. (Adversarial review C1, 2026-06-03.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %x0, i32 %y0) {
entry:
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  %qy = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  switch i32 %s, label %dflt [ i32 0, label %c0
                               i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  %stray = call i32 @cq_phi_si32(i32 %qy, double 7.700000e-01)   ; STRAY: qy gated in qx's arm
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
