; control_swap_reject_nested_switch.ll — DECLINE: an inner switch under an outer
; tainted branch.
;
; `if (q>5) { q = rz(q,b); switch(q){...} }` — the Mid arm ends in a tainted
; `switch`, so the outer arm has no unconditional fall-through: recoverRegion
; classifies the outer branch OffPattern → `control flow` (fired on the OUTER
; branch, before the inner switch scan could emit the 4.5-unbuilt `switch`
; string). Over-declining is safe (Prime Directive); pinned to the string that
; actually fires on real -O1.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  switch i32 %g, label %merge [
    i32 1, label %a1
    i32 2, label %a2
  ]
a1:
  %h1 = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
a2:
  %h2 = call i32 @cq_phi_si32(i32 %g, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %g, %mid ], [ %h1, %a1 ], [ %h2, %a2 ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}control flow under quantum control
