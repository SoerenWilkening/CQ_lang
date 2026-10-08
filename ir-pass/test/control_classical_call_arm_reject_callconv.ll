; control_classical_call_arm_reject_callconv.ll — DECLINE (bd test_C_libtooling-bwfp).
; A call whose calling convention differs from its callee's is immediate UB when it
; executes. The source runs it only under `q > 3`; the 6.5 hoist would run it on
; every basis state. PredMux's nested hoist refuses the same call
; (control_predmux_nested_classical_callconv.ll); the 6.5 owner now asks the same
; call-site contract (`callExecutionIsDefined`, SpeculationSafety.h).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @pf(i32 noundef %x) #0 {
entry:
  %v = mul i32 %x, 3
  ret i32 %v
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call fastcc i32 @pf(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
