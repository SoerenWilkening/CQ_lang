; control_swap_reject_switch_value_clobber.ll — DECLINE (G7 §3c clobber, the ONLY
; G7 fixture; the §3c clobber is a value-arm-only proof). The scrutinee %q is a
; DIAGONAL derivation of the routed base %p (`%q = cq_phi(%p, θ)` — Rz, basis-
; preserving), and every value arm rewrites %p. Routing+rewriting %p clobbers the
; very wire the eq-flags `(q == c_i)` are minted from (rotation lowering RAUWs %q
; and %p to ONE i32 handle — SSA-value disjointness from %q is NOT wire
; disjointness): the flag-strip premise `icmp_inv(q, c_i)` reads the same basis as
; the mint, and that premise dies with the rewrite. Information-theoretically
; impossible to both keep p's answer and disentangle the scrutinee — PERMANENT
; reject. p != q so this is the G7 clobber, NOT the C2 mis-anchor.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %p0) {
entry:
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  %q = call i32 @cq_phi_si32(i32 %p, double 3.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i32 %p, 1
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
