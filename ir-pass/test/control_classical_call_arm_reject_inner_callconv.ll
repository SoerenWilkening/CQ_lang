; control_classical_call_arm_reject_inner_callconv.ll — DECLINE (bd test_C_libtooling-bwfp, review round 2 F3).
; The hoisted `@pc` makes an INNER call whose calling convention (`fastcc`) differs from
; its callee's (`ccc`): UB when it runs, and the hoist runs it on basis states the
; guard excluded. The strict body walk never checked inner call sites; the poison-flow
; analysis asks the call-site contract (`callExecutionIsDefined`) of every inner call.
; IR-only in practice (InstCombine turns such a call into an UB marker at -O1).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @g2(i32 %y) #0 {
entry:
  %m = mul i32 %y, 3
  ret i32 %m
}
define internal i32 @pc(i32 %x) #0 {
entry:
  %r = call fastcc i32 @g2(i32 %x)
  ret i32 %r
}
define i32 @ex_innercc(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pc(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
