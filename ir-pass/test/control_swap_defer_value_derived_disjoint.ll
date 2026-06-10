; control_swap_defer_value_derived_disjoint.ll — a value chain over a DERIVED
; pre-region cq_phi base DISJOINT from the condition stays accept-class (4.2
; WI-3; the positive contrast pin for control_swap_reject_value_alias_cond.ll
; — the diagonal-alias closure must not over-decline the legitimate 9hh
; derived-base discipline).
;
; `pd = rz(p, a); if (q > 5) { v = pd + 3; }` — the routed slot %pd is a
; diagonal alias of %p's wire, and NEITHER is in condProvenance(icmp %q): the
; alias-closure walk (%pd -> %p, stop at theta) finds no provenance hit, so
; the region classifies accept-class and (transitionally, until WI-4) declines
; with the defer string — NOT `control flow`, NOT §3c.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}value-arm swap-route under quantum control
; CHECK-NOT: arm rewrites a condition operand
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %pd = call i32 @cq_phi_si32(i32 %p, double %a)   ; derived base, DISJOINT from cond
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v = add i32 %pd, 3
  br label %merge
merge:
  %vm = phi i32 [ %v, %arm ], [ %pd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %vm)
  ret i32 %m
}
