; control_swap_reject_switch_datause.ll — DECLINE: the scrutinee has an UNOWNED data
; use beyond the switch/merge/escape/measure (G10, v1 floor). A dead-within-function
; arithmetic use leaves a dirty rail with no owner.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition data use neither escaped nor measured under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = add i32 %q, 100
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
