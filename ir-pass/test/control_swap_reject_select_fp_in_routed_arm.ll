; control_swap_reject_select_fp_in_routed_arm.ll — DECLINE (kjd1 Rule-13
; implementation clearance, scope-lens pin §5.9d): an fp select INSIDE a
; tainted-`br` diamond arm. The arm vocabulary has no select member —
; ArmClassify declines the region (value-arm swap-route dialect) before any
; select classification could fire inside the arm; type-agnostic, so the fp
; un-staging cannot leak through it. The fp tripwire the suite lacked.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}value-arm swap-route under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %p = call double @cq_theta_f64(double %u1, double 2.500000e-01)
  %c = fcmp ogt double %q, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %c2 = fcmp ogt double %p, 1.000000e+00
  %s  = select i1 %c2, double %p, double 2.000000e+00   ; fp select inside the arm
  br label %merge
merge:
  %y = phi double [ %s, %arm ], [ %p, %entry ]
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}
