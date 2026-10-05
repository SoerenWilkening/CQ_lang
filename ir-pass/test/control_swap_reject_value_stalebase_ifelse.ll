; control_swap_reject_value_stalebase_ifelse.ll — DECLINE: the two-arm value
; if/else twin of control_swap_reject_value_stalebase_diamond.ll (4.2 WI-5 §8
; adversarial review, 2026-06-11 — the shape the removed staged WI-5 decline
; was incidentally masking).
;
; Both chains bottom at `%q` while `%q2 = cq_theta(%q, ·)` (a chained Ry through
; a sibling SSA name) fires on the same physical wire before the branch: the
; value-arm lowering would read the POST-Ry wire while the chains' SSA base names
; the PRE-Ry RECORD (stale-record family — see the diamond twin for the full
; rationale). Since test_C_libtooling-6j1 the observed message is the EARLIER
; straight-line guard's (OpcodeLowering::declineStaleRecordOps — its seed closure
; catches the arm ops over `%q` first; opt exits at the FIRST DS_Error); the
; region-level routed-base diagonal-alias-closure walk in classifyArms remains
; live behind it, pinned by control_swap_reject_value_stalebase_inarm.ll.
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
  br i1 %c, label %then, label %else
then:
  %vt = add i32 %q, 3
  br label %merge
else:
  %ve = mul i32 %q, 7
  br label %merge
merge:
  %pm = phi i32 [ %vt, %then ], [ %ve, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; never the condition-side string, never accepted
; CHECK-NOT: condition predates a non-diagonal gate
; CHECK-NOT: cqrt_copy
