; control_classical_call_arm_reject_inner_noundef_param_poison.ll — DECLINE (bd test_C_libtooling-bwfp).
; The UB sink is one call deeper. `@pf` passes `x + 1` (`nsw`: poison on overflow) to
; `@g`'s `noundef` parameter, the C shape `int pf(int x) { return g(x + 1); }`. The
; strict body walk (`isSpeculatableTotalCallee`) admits both bodies, but on a basis
; state the guard excluded the hoisted `@pf(%k)` runs with `%k = INT_MAX` and passes
; poison to a `noundef` parameter: immediate UB. The poison-flow analysis follows the
; `nsw` add into `@g`'s `noundef` parameter and refuses the hoist. Contrast
; control_classical_call_arm_accept_inner_call_nsw.ll: there the inner `noundef`
; parameter receives a DEFINED value and the `nsw` poison reaches only the result.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @g(i32 noundef %y) #0 {
entry:
  %m = mul i32 %y, 3
  ret i32 %m
}

define internal i32 @pf(i32 noundef %x) #0 {
entry:
  %a = add nsw i32 %x, 1
  %r = call i32 @g(i32 noundef %a)
  ret i32 %r
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
