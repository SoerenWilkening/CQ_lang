; lowering_control_switch_gated_distinct_wrongarmmut_default.ll — Phase 4.x
; (npu.5/.6), DECLINE (gate G3b). The DEFAULT-base variant of the wrong-arm
; mutation: case1's arm (which selects qy) applies a STRAY gate `cq_phi(qx, .77)`
; to qx — the DEFAULT-selected base. That stray `cqrt_rz_controlled(f1 = s==1, qx,
; .77)` fires on a branch (s==1) where qx is not selected; qx's uncompute fires on
; OtherCaseOr (≡ ¬f_qx) and cannot undo the stray Rz → qx left entangled, regOut
; decoheres. Per-arm correspondence (G3b) rejects it. (Adversarial review C1.)
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
  br label %merge
c1:
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  %stray = call i32 @cq_phi_si32(i32 %qx, double 7.700000e-01)   ; STRAY: default base qx gated in qy's arm
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
