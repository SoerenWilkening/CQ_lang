; control_swap_reject_switch_value_router_base_backstop.ll — DECLINE pin (bd
; tayx audit): the router spelling on a VALUE switch's ROUTED BASE — the
; switch twin of control_swap_reject_value_diamond_router_base_backstop.ll.
; Owned by the pre-detect `declineStaleRecordOps` (position-aware, router-
; crossing): the arms' stock `add %p` ops read the stale wire, declining in
; the opcode dialect before SwitchArmProve's own routed-base guard (also
; flipped to CrossValueRouting=true, unreachable for this shape) could run.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %p0v, i1 %cc) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p0 = call i32 @cq_theta_si32(i32 %p0v, double 7.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %p0, double 3.000000e-01)     ; routed base, ancestry {p, p0}
  br i1 %cc, label %x, label %y
x:
  br label %pre
y:
  br label %pre
pre:
  %r = phi i32 [ %p0, %x ], [ %p0, %y ]                           ; router on the OLD alias
  %g = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)       ; hidden Ry on p's wire
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i32 %p, 1
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %pre ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  %m2 = call i32 @cq_measure_si32(i32 %g)
  ret i32 %m
}
