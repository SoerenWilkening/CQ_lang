; control_swap_reject_switch_grouped.ll — DECLINE: two case values target one block
; (grouped fall-through, C4/G9). Per-value-flag routing is deferred; v1 declines.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a0 ]
a0:
  %g0 = call i32 @cq_phi_si32(i32 0, double 1.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g0, %a0 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
