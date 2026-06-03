; lowering_control_switch_gated_distinct_varangle.ll — Phase 4.x (npu.5/.6),
; DECLINE (gate G5, conservative). Base qx's prep angle is a COMPUTED value
; `%a = fadd double %u, %v`, not a ConstantFP. The uncompute Ry†(angle) needs the
; angle materialized at the merge boundary; the conservative gate admits only a
; ConstantFP prep angle (the dominating-variable case is an over-decline-safe
; deferral) → WP12.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %x0, i32 %y0, double %u, double %v) {
entry:
  %a = fadd double %u, %v
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double %a)
  %qy = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
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
