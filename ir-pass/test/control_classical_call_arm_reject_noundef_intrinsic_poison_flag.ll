; control_classical_call_arm_reject_noundef_intrinsic_poison_flag.ll — DECLINE (bd test_C_libtooling-bwfp).
; R11 round 5 F1: `ctlz(%k, is_zero_poison=true)` is poison for `%k == 0`, and the call
; site is `noundef`, so `f(0)` is immediate UB. LLVM 19's `canCreateUndefOrPoison`
; answers "no poison" for a `noundef` ctlz/cttz/abs whatever its flag (it treats that
; as UB, not poison), so the dataflow never reached the sink. Round 4 declined only by
; accident (the call-site `range` was unproven); proving that range reopened it.
; Measured on the round-5 snapshot (sha b0f8aab1): `call i32 @f(i32 noundef %k)`
; hoisted into `entry`, opt rc=0. The flag is now asked of `curatedIntrinsicCanBePoison`,
; as `totalCall` does. (The `abs` twin with `i1 true` takes the same path.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.abs.i32(i32, i1 immarg)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)
declare i8 @llvm.ctlz.i8(i8, i1 immarg)
define internal i32 @g(i32 noundef %v) #0 {
entry:
  %r = xor i32 %v, 5
  ret i32 %r
}
define internal i32 @f(i32 noundef %k) #0 {
entry:
  %a = call noundef range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %k, i1 true)
  %r = xor i32 %a, 3
  ret i32 %r
}
define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 noundef %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
