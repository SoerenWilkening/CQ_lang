; lowering_control_switch_gated_distinct_emptydefault.ll — Phase 4.x (npu.5/.6),
; DECLINE (gate G4). A distinct-base mux (case0→qx, case1→qy) whose default edge is
; routed STRAIGHT to the merge (an empty `default:`, SwitchDefaultDirect). There is
; no default block / gate body, so no ¬OrAll control exists for a default-selected
; base — the asymmetry the uncompute needs. The gate admits only a distinct
; reconverging default BLOCK with a gate body; this declines to WP12.
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
  switch i32 %s, label %merge [ i32 0, label %c0
                                i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %merge
c1:
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  br label %merge
merge:
  %r = phi i32 [ %qx, %entry ], [ %r0, %c0 ], [ %r1, %c1 ]
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
