; control_classical_call_arm_reject_root_retattr_range.ll — DECLINE (bd test_C_libtooling-bwfp).
; R11 round 3 F1(b): the HOISTED call site is `noundef` and its callee `@pb` carries
; `range(i32 0, 5)` on its return without `noundef`. `pb(50)` yields poison, and a
; `noundef` call result that is poison is immediate UB, on basis states the guard
; `q > 3` excluded. Measured on the round-3 snapshot (sha 8c141046): hoisted into
; `entry`, opt rc=0. `hoistUBWithPoisonArgs` now counts the callee's unproven return
; constraint (and the call site's own) as a poison source for that sink.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal range(i32 0, 5) i32 @pb(i32 noundef %x) #0 {
entry:
  ret i32 %x
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call noundef i32 @pb(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
