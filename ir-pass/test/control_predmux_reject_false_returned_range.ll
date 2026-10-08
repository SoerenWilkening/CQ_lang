; control_predmux_reject_false_returned_range.ll — DECLINE (bd test_C_libtooling-bwfp).
; R11 round 4 F1, the PredMux twin of control_classical_call_arm_reject_false_returned.ll:
; the nested classical condition `f(k) == 0` sits inside the quantum arm, so PredMux's
; strict totality proof (`classicalCallCanBeSpeculated` -> `totalCall` ->
; `returnAttrsHold`) is asked. `@g`'s false `returned` let known bits "prove" `@f`'s
; `noundef range(i32 0, 4)`. Measured on the round-4 snapshot (sha 86f1d42c): `f(k)`
; hoisted into `entry`, opt rc=0, a NEW accept against e0af16ed and round 3 (both
; declined). The verified `returned` restores the decline.
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
define i32 @direct(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %mid, label %merge
mid:
  %r = call i32 @f(i32 noundef %k)
  %z = icmp eq i32 %r, 0
  br i1 %z, label %a1, label %a2
a1:
  %s = sub i32 %q, %k
  br label %merge
a2:
  %t = add i32 %q, %k
  br label %merge
merge:
  %y = phi i32 [ %s, %a1 ], [ %t, %a2 ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
