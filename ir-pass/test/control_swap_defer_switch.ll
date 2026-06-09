; control_swap_defer_switch.ll — tainted `switch` DEFERS to 4.5 (distinct string).
;
; A tainted-scrutinee `switch` is a gated multi-arm region, out of 4.1 scope. It
; declines with the existing "switch" string (→ "switch under quantum control").
; Regression guard mirroring control_swap_defer_select.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %q, %a0 ], [ %q, %a1 ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
