; lowering_control_switch.ll — Family D (WP12), negative. A `switch` on a
; tainted scrutinee surviving `-O1` (sparse / side-effecting arms) branches on
; the quantum HANDLE id, not the quantum state. Detection only ever matched
; `dyn_cast<BranchInst>` (`grep -rn Switch ir-pass/src` was empty), so the pass
; left the switch untouched and lowered the arm bodies uncontrolled — a SILENT
; MISCOMPILE. WP12 is a safety guard only: a tainted-scrutinee `SwitchInst`
; emits the loud diagnostic. The realized lowering stays Phase 4.1 (Family E:
; `-lowerswitch` + closed-diamond guard, depends on WP7 + WP8).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i32)
define i32 @example(i32 %u0) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %u, label %dflt [
    i32 0, label %c0
    i32 3, label %c3
  ]
c0:
  call void @sink(i32 10)
  br label %merge
c3:
  call void @sink(i32 20)
  br label %merge
dflt:
  call void @sink(i32 99)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %u)
  ret i32 %m
}
