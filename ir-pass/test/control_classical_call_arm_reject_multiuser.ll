; control_classical_call_arm_reject_multiuser.ll — multi-user reject (WI-5.8
; probe): the classical call's result reaches a SECOND, non-phi in-arm user
; (here `@sink(%r)`) in addition to the merge phi. Routing `%r` into `%out` and
; flattening the diamond would leave that user reading a value that is no longer
; computed on the live (flattened) path — and the second in-arm instruction is a
; side effect the flatten would silently ERASE. `classifyClassicalCallArm`
; requires the arm to be EXACTLY the call + its terminator AND the call result to
; have a single use (the merge), so it DECLINES loudly. NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @pure_f(i32) #0
declare void @sink(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pure_f(i32 7)
  call void @sink(i32 %r)       ; SECOND in-arm user of %r (and a side effect)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
