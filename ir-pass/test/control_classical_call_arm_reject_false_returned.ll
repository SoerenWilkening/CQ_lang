; control_classical_call_arm_reject_false_returned.ll — DECLINE (bd test_C_libtooling-bwfp).
; R11 round 4 F1: `@g` claims `returned` on %x but returns %x + 4. LLVM's known bits
; trust `returned` (`CallBase::getReturnedArgOperand`), so `@f`'s `noundef range(i32 0, 4)`
; was "proven" from `and %k, 3` forwarded through `@g`. Real: f(k) = (k & 3) + 4, out of
; range, so `ret noundef poison` -- immediate UB on basis states the guard `q > 3`
; excluded (all of them, Ry(0)). Measured on the round-4 snapshot (sha 86f1d42c):
; `call i32 @f(i32 %k)` hoisted into `entry`, opt rc=0 (round 3 and e0af16ed: see the
; PredMux twin control_predmux_reject_false_returned_range.ll). `returned` is now
; admitted only when every `ret` of the callee returns that parameter.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @g(i32 returned %x) #0 {
entry:
  %y = add i32 %x, 4
  ret i32 %y
}
define internal noundef range(i32 0, 4) i32 @f(i32 noundef %k) #0 {
entry:
  %a = and i32 %k, 3
  %r = call i32 @g(i32 %a)
  ret i32 %r
}
define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
