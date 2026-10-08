; control_classical_call_arm_reject_inner_retattr_range.ll — DECLINE (bd test_C_libtooling-bwfp).
; R11 round 3 F1(a): a poison SOURCE that is a return attribute, not an instruction.
; `@ga` returns its argument under `range(i32 0, 5)` WITHOUT `noundef`: for `%x >= 5`
; the call yields poison. `@pa` forwards that result to its own `noundef` return, so
; `pa(50)` executes `ret noundef poison`: immediate UB. The 6.5 hoist runs `@pa(%k)`
; on every basis state, including those the guard `q > 3` excluded (here: all of
; them, Ry(0)). Measured on the round-3 snapshot (sha 8c141046): hoisted into
; `entry`, opt rc=0. The poison dataflow (`hoistedCallTreeIsUBFree`) now treats an
; unproven value-constraining return attribute on any callee as a poison source.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal range(i32 0, 5) i32 @ga(i32 %x) #0 {
entry:
  ret i32 %x
}

define internal noundef i32 @pa(i32 noundef %x) #0 {
entry:
  %r = call i32 @ga(i32 %x)
  ret i32 %r
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pa(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
