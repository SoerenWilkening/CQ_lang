; lowering_reject_stale_record_alias_sibling.ll — DECLINE: the sibling
; diagonal-alias layout of lowering_reject_stale_record_add.ll
; (test_C_libtooling-6j1), straight-line, NO control flow.
;
; `%d = add i32 %qd, 3` reads the DIAGONAL ALIAS `%qd = cq_phi(%q, ·)` —
; Rz preserves the computational basis, so `%qd` denotes the PRE-Ry record of
; `%q`'s wire — while the chained, in-place, NON-diagonal `cq_theta(%q, %t2)`
; consumes the SIBLING SSA name `%q`. Rotation lowering RAUWs the whole
; `cq_phi` arg-0 chain to ONE i32 handle, so the template emitted at the add's
; scheduled position (AFTER the Ry) reads the post-Ry wire: the same
; stale-record physics as lowering_reject_stale_record_add.ll, one diagonal
; hop removed. Before the closure the pass ACCEPTED this shape (exit 0,
; verify-clean, confirmed 2026-06-11: `cq_template_add_i32_hl(%h, 3)` emitted
; after `cqrt_ry_i32(%h, 0.25)`) — a forward-only walk seeded at `%qd` can
; never reach a user of `%q`. Guard: WireWalk::findNonDiagonalWireGate now
; closes every seed BACKWARD through diagonal `cq_phi` arg-0 hops to its
; RECORD BOUNDARY — the nearest non-cq_phi ancestor, NOT the wire origin —
; before walking forward (cq_phi hops ONLY, never a theta hop; see
; lowering_stale_record_alias_producer.ll for that boundary, and
; test_C_libtooling-6vk for the still-open sibling-Ry-behind-a-CHAINED-theta
; over-accept family this stop leaves uncovered). The control-path twins are
; control_swap_reject_value_stalebase_{diamond,ifelse}.ll (WI-5); this
; fixture pins the remaining STRAIGHT-LINE surface
; (OpcodeLowering::declineStaleRecordOps).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)        ; chained Ry via the SIBLING name
  %d = add i32 %q, 3                                      ; SSA denotes the PRE-Ry record
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
