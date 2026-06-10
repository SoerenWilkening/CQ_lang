; control_swap_reject_value_alias_cond.ll — a value arm routed over a DIAGONAL
; ALIAS of the condition register declines (4.2 WI-3 hardening, §8 review
; 2026-06-10: the accept-class disjointness must hold on the physical WIRE,
; not just the SSA value).
;
; `qd = rz(q, a); if (q > 5) { v = qd + 3; }` — the routed slot %qd is
; SSA-disjoint from condProvenance(icmp %q), and a derived pre-region cq_phi
; base is otherwise legitimate (the 9hh discipline). But rotation lowering
; RAUWs %q and %qd to the SAME i32 handle: routing %qd transforms the very
; wire the icmp_inv flag-strip reads, so the §8.2 "no reliance on the
; reverse-play" rationale does not cover this shape (mid-stream the wire holds
; the muxed value; only a strip-after-R-dagger order would save it). Declined
; through the diagonal-alias closure of the routed base — GENERIC `control
; flow`, not §3c: the source rewrites a DIFFERENT variable that merely shares
; the wire, so the shape is revisitable (lowerable under a binding stream
; order), not information-theoretically impossible. Contrast: the f64/sll
; derived-base PHASE fixtures stay accepted (diagonal arms never change the
; wire's basis), and a value arm over a derived base DISJOINT from the
; condition (e.g. pd = rz(p, a) with cond on q) remains accept-class.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: arm rewrites a condition operand
; CHECK-NOT: value-arm swap-route
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double %a)   ; diagonal ALIAS of %q's wire
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v = add i32 %qd, 3        ; routable chain over the aliased register
  br label %merge
merge:
  %vm = phi i32 [ %v, %arm ], [ %qd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %vm)
  ret i32 %m
}
