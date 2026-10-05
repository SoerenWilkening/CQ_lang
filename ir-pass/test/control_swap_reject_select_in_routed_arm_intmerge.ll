; control_swap_reject_select_in_routed_arm_intmerge.ll — DECLINE (bd vyqi; the
; type-agnostic RE-PIN of the kjd1 §5.9d tripwire formerly carried by
; control_swap_reject_select_fp_in_routed_arm.ll, whose fp body W5 now
; flattens): a select INSIDE a tainted-`br` triangle arm reaching ArmClassify.
; The W5 witness is fp-only, so an INTEGER sole-phi merge still goes to
; ArmClassify's value-arm path, whose arm vocabulary has no select member: the
; region declines `value-arm swap-route` (a swap-route-era name) before any
; select classification could fire inside the arm. This pin proves the ARM
; dialect still cannot accept (or half-lower) a select-bearing arm — the property
; the original scope-lens pin guarded — independent of the fp un-staging.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}value-arm swap-route under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %c2 = icmp sgt i32 %p, 1
  %s  = select i1 %c2, i32 %p, i32 2      ; select inside the arm
  br label %merge
merge:
  %y = phi i32 [ %s, %arm ], [ %p, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
