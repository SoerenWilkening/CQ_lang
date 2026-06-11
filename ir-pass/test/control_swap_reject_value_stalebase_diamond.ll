; control_swap_reject_value_stalebase_diamond.ll — DECLINE: a value diamond
; whose routed base's PHYSICAL WIRE gains a non-diagonal (Ry) gate via a
; SIBLING SSA name (4.2 WI-5 §8 adversarial review, 2026-06-11 — a latent
; WI-4 over-accept).
;
; `%qd = cq_phi(%q, ·)` is the routed base; `%q2 = cq_theta(%q, ·)` is a
; chained in-place Ry on the SAME wire through the sibling name %q. Post-RAUW
; %q/%qd/%q2 are ONE i32 handle, so the route-in at the branch reads the
; POST-Ry wire while the chain's SSA base names the PRE-Ry RECORD — the
; stale-record family (lowering_reject_stale_record_add.ll), replayed onto
; the rail as a verify-clean wrong unitary. Invisible to every prior guard:
; condProvenance stops AT the theta (never enters its tainted arg-0), so the
; condition-seeded wire walk and diagonalAliasHit both miss the sibling.
; classifyArms now seeds the position-free wire walk from the routed base's
; diagonal-alias closure ({%qd, %q}) and declines. Phase arms are immune
; (Rz is wire-named and diagonal — no basis record is read).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 1.000000e+00)   ; routed base (diagonal alias of %q)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01) ; chained Ry on the SIBLING name
  %c  = icmp sgt i32 %q2, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %qd, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %qd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: error{{.*}}routed base predates a non-diagonal gate under quantum control
; never the condition-side string, never accepted
; CHECK-NOT: condition predates a non-diagonal gate
; CHECK-NOT: cqrt_copy
