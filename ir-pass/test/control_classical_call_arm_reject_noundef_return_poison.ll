; control_classical_call_arm_reject_noundef_return_poison.ll — DECLINE (bd test_C_libtooling-bwfp).
; control_classical_call_arm_accept_poisonselect_callee.ll plus ONE attribute: `@pf`'s
; RETURN is `noundef`. The 6.5 hoist runs `@pf(%k)` on every basis state, including
; the ones the source's guard (`q > 3`) excluded, and for `%k >= 32` the body computes
; `ret noundef poison`: immediate UB the source never executed. Without the attribute
; the poison result is never observed on a shielded state (the controlled copy is the
; identity there), which is why the sibling ACCEPTS; with it, the return itself is UB.
; Measured on e0af16ed: `%r = call i32 @pf(i32 %k)` hoisted into `entry`, opt rc=0.
; The poison-flow analysis (`hoistedCallTreeIsUBFree`, SpeculationSafety.h) follows the
; `shl`'s poison to that `noundef` return and refuses the hoist.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal noundef i32 @pf(i32 noundef %x) #0 {
entry:
  %s = shl i32 1, %x
  %c = icmp eq i32 %s, 7
  %v = select i1 %c, i32 1, i32 2
  ret i32 %v
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
