; control_classical_call_arm_reject_impure.ll — purity reject (DD-7 / WI-5.4): a
; classical call inside a tainted-condition diamond arm whose callee has a SIDE
; EFFECT. The 6.5 lowering HOISTS the call into the pred so it runs
; unconditionally — observationally inert ONLY for a pure callee. An impure callee
; (here `@impure_f`, declared with NO `memory(none)`/`nounwind`/`willreturn`
; attributes, so it may write memory / throw / not return) would be executed even
; on the inactive branch, changing observable behavior. `classifyClassicalCallArm`
; gates on `!doesNotAccessMemory() || mayHaveSideEffects()` and DECLINES loudly
; (the rejection set is load-bearing for the inert-hoist claim — §2.13). NEVER
; lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @impure_f(i32)            ; no purity attrs — may write memory / throw

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @impure_f(i32 7)      ; impure — hoisting it would not be inert
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
