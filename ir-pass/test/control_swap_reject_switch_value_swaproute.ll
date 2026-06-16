; control_swap_reject_switch_value_swaproute.ll — DECLINE (C2/G6 mis-anchor, the
; §6.5 kill-shot probe): a VALUE switch whose arm chain bottoms at an independent
; tainted handle %r, NOT the merge default-edge (straight-through) incoming %p. The
; C2 anchor requires every arm chain to bottom at the SHARED routed base p; routing
; p while the chain computes f(%r) would mux an unrelated wire (the routed base is
; mis-anchored). `proveSwitchValue` sees `Chain.Base (%r) != p` and declines.
;
; Distinct from `control_swap_reject_switch_value_qq.ll` (a Q+Q link `add %p, %r`,
; HasQQ): here the single tainted operand is %r itself (a base mismatch), not a
; second operand on the routed chain.
;
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
  %v0 = add i32 %r, 1
  br label %merge
a1:
  %v1 = add i32 %r, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
