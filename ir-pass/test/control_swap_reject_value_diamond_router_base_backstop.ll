; control_swap_reject_value_diamond_router_base_backstop.ll — DECLINE pin (bd
; tayx audit): the router spelling on a VALUE diamond's ROUTED BASE. Unlike
; the phase paths (which had no fence and were fixed at detection), the value
; family is owned by the PRE-DETECT pass-wide stale-record guard
; (`declineStaleRecordOps`, position-aware WireWalk with CrossValueRouting
; ALREADY true): the arm's stock ops read %p's wire, which gained the
; router-hidden non-diagonal gate, so the module declines loudly BEFORE
; detection ever runs — in the opcode dialect. This fixture pins that
; ownership (the detection-time routed-base guard at ArmClassify was also
; flipped to CrossValueRouting=true for uniform posture, but it is
; unreachable for this shape — the backstop fires first).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i1 %cc) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p0 = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %p  = call i32 @cq_theta_si32(i32 %p0, double 3.000000e-01)     ; routed base, ancestry {p, p0}
  br i1 %cc, label %x, label %y
x:
  br label %pre
y:
  br label %pre
pre:
  %r = phi i32 [ %p0, %x ], [ %p0, %y ]                           ; router on the OLD alias
  %g = call i32 @cq_theta_si32(i32 %r, double 7.000000e-01)       ; hidden Ry on p's wire
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5                                             ; stock op reads the stale wire
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %pre ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  %m2 = call i32 @cq_measure_si32(i32 %g)
  ret i32 %m
}
