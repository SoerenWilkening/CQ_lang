; control_swap_reject_switch_value_qq.ll — DECLINE: a VALUE arm with a Q+Q link
; (`add %p, %r`, %p the routed base and %r an INDEPENDENT tainted handle, neither
; the scrutinee). The Rule-13 H2 over-accept: walkValueChain sets HasQQ and threads
; on %p, so the chain bottoms at %p, but a second superposed rail %r is entangled
; into the chain that method-B reverse-play cannot disentangle (Rule 8 no-cloning).
; Mirrors the flat if/else value twin's decline (ArmClassify.cpp).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}value-arm swap-route under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %p0, i32 %r0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %r0, double 3.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i32 %p, %r
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
