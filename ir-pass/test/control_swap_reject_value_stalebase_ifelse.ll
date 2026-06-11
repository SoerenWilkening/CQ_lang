; control_swap_reject_value_stalebase_ifelse.ll — DECLINE: the two-arm value
; if/else twin of control_swap_reject_value_stalebase_diamond.ll (4.2 WI-5 §8
; adversarial review, 2026-06-11 — the shape the removed staged WI-5 decline
; was incidentally masking).
;
; Both chains bottom at `%qd = cq_phi(%q, ·)` while `%q2 = cq_theta(%q, ·)`
; (a chained Ry through the sibling SSA name) fires on the same physical wire
; before the branch: the dual route-ins would read the POST-Ry wire while the
; chains' SSA base names the PRE-Ry RECORD (stale-record family — see the
; diamond twin for the full rationale). Declined by the routed-base
; diagonal-alias-closure wire walk in classifyArms.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 1.000000e+00)   ; shared routed base (alias of %q)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01) ; chained Ry on the SIBLING name
  %c  = icmp sgt i32 %q2, 5
  br i1 %c, label %then, label %else
then:
  %vt = add i32 %qd, 3
  br label %merge
else:
  %ve = mul i32 %qd, 7
  br label %merge
merge:
  %pm = phi i32 [ %vt, %then ], [ %ve, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: error{{.*}}routed base predates a non-diagonal gate under quantum control
; never the condition-side string, never accepted
; CHECK-NOT: condition predates a non-diagonal gate
; CHECK-NOT: cqrt_copy
