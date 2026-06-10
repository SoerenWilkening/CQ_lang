; control_swap_value_reject_clobber_active_transitive.ll — §3c ACTIVE through
; TRANSITIVE condition provenance on a routable value chain (4.2 WI-3; PRD Part II
; §8.3 row 1: `if(q+1>5){q=q+3}` transitive; the multi-link variant here).
;
; The condition reads %q one pure wire-hop away (`%t = add %q, 1; icmp %t`), so
; %q is in the condition's TRANSITIVE taint provenance even though the compare
; never touches %q directly. The arm chain is fully routable over %q (the
; straight-through incoming) — and `Routed ∈ condProvenance` still binds: the
; §3c walk threads derived values exactly like the 4.1 phase-arm fixture
; control_swap_reject_derived.ll, now on the active chain predicate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = add i32 %q, 1         ; derived condition input — provenance threads %t -> %q
  %c = icmp sgt i32 %t, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = mul i32 %q, 5
  %q2 = add i32 %q1, 15
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
