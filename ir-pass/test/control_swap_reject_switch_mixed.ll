; control_swap_reject_switch_mixed.ll — DECLINE: one PHASE arm + one VALUE arm
; (mixed content classes, G5).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}mixed phase/value arm under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %p0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %g0 = call i32 @cq_phi_si32(i32 0, double 1.000000e-01)
  br label %merge
a1:
  %v1 = add i32 %p, 1
  br label %merge
merge:
  %m_ = phi i32 [ %q, %entry ], [ %g0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %m_)
  ret i32 %m
}
