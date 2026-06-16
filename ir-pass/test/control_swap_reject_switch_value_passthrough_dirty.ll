; control_swap_reject_switch_value_passthrough_dirty.ll — DECLINE: a VALUE switch with
; a PASSTHROUGH case (case 0: merge incoming == the routed base %p) whose arm BLOCK
; holds a stray live qubit + USER MEASUREMENT on a SIBLING handle %s. Same Rule-13
; round-3 over-accept as the phase twin: valuePureChain skips passthrough cases; the
; driver's uniform passthrough-arm-empty scan declines it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %p0, i32 %s0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %s = call i32 @cq_theta_si32(i32 %s0, double 9.000000e-01)
  %sm = call i32 @cq_measure_si32(i32 %s)
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %p, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
