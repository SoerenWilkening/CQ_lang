; control_classical_call_arm_reject_root_param_range.ll — DECLINE (bd test_C_libtooling-bwfp, review round 2 F2).
; The hoisted call's own parameter is `noundef range(i32 1, 10)`. The argument `%k` is
; DEFINED, so no freeze applies, but on a basis state the guard excluded `%k` may be 50:
; a defined value outside the range is poison, and poison in a `noundef` parameter is
; immediate UB the source never executed. Only inert parameter attributes pass now.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @pr(i32 noundef range(i32 1, 10) %x) #0 {
entry:
  %v = add i32 %x, 1
  ret i32 %v
}
define i32 @ex_range(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pr(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
