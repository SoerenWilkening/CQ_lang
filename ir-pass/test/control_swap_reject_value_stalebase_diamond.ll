; control_swap_reject_value_stalebase_diamond.ll — DECLINE: a value diamond
; whose routed base's PHYSICAL WIRE gains a non-diagonal (Ry) gate via a
; SIBLING SSA name (4.2 WI-5 §8 adversarial review, 2026-06-11 — a latent
; WI-4 over-accept).
;
; The arm chain `add %q, 3` bottoms at %q, while `%q2 = cq_theta(%q, ·)` is a
; chained in-place Ry on the SAME wire through the sibling name %q2. Post-RAUW
; %q/%q2 are ONE i32 handle, so the value-arm lowering would read the POST-Ry
; wire while the chain's SSA base names the PRE-Ry RECORD — the stale-record
; family (lowering_reject_stale_record_add.ll), a verify-clean wrong unitary. At
; WI-5 this was invisible to every prior guard (condProvenance stops AT the theta,
; never entering its tainted arg-0, so the condition-seeded wire walk and
; diagonalAliasHit both missed the sibling) and classifyArms' routed-base
; diagonal-alias-closure walk owned the decline. Since test_C_libtooling-6j1
; moved that closure into the WireWalk core, the EARLIER straight-line guard
; (OpcodeLowering::declineStaleRecordOps) catches the arm's `add %q, 3`
; first — the pre-branch Ry can never be provably post-emission of an arm op
; — and opt exits at the FIRST DS_Error, so that is the observed message
; (same physics, earlier owner). The region-level routed-base guard remains
; live and is pinned by control_swap_reject_value_stalebase_inarm.ll, the
; layout the position-aware straight-line guard ACCEPTS.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01) ; chained Ry on the SIBLING name
  %c  = icmp sgt i32 %q2, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %q, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; never the condition-side string, never accepted
; CHECK-NOT: condition predates a non-diagonal gate
; CHECK-NOT: cqrt_copy
