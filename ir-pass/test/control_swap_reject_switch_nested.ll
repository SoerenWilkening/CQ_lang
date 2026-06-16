; control_swap_reject_switch_nested.ll — DECLINE: a case body that is itself a
; tainted-control region (a nested tainted br, G11). Deeper than the 4.3 nest.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %a0t, label %a0f
a0t:
  %g0t = call i32 @cq_phi_si32(i32 0, double 1.000000e-01)
  br label %merge
a0f:
  %g0f = call i32 @cq_phi_si32(i32 0, double 2.000000e-01)
  br label %merge
a1:
  %g1 = call i32 @cq_phi_si32(i32 1, double 3.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g0t, %a0t ], [ %g0f, %a0f ], [ %g1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
