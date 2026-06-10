; control_swap_value_reject_clobber_active.ll — §3c ACTIVE on a would-be-routable
; multi-link value chain (4.2 WI-3; PRD Part II §8.3 row 1, IMPLEMENTATION-4.2 §5f).
;
; `if (q > 5) { q = q*5; q = q+15; }` — the arm is a PURE LINEAR HL chain that
; bottoms at exactly the routed slot (the diamond's straight-through %q), i.e. it
; is routable in every structural respect — and the routed register IS in the
; condition's taint provenance. 4.1 shipped the §3c reject vacuously (the proxy
; fired at the first value op); 4.2's chain classification makes it ACTIVE: the
; region passes the full routability predicate (ChainBase == Routed, linear,
; supported stems, sole-tainted-operand links) and is §3c-rejected ONLY on
; `Routed ∈ condProvenance`. Once the arm overwrites q's computational-basis
; value, no control model and no Bennett copy can keep the flag strippable AND
; the answer disentangled — permanent reject, NOT a 4.2-deferred one.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = mul i32 %q, 5        ; link 1: HL, sole tainted operand %q (the routed base)
  %q2 = add i32 %q1, 15      ; link 2: HL, threaded value %q1
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
