; lowering_reject_stale_record_alias_over_theta.ll — DECLINE: the alias-over-a-
; CHAINED-theta variant of the sibling over-accept (test_C_libtooling-6vk,
; surface S2; straight-line, NO control flow).
;
; `%d = add i32 %qd2, 3` reads the diagonal alias `%qd2 = cq_phi(%q2, ·)` of a
; CHAINED theta `%q2 = cq_theta(%q, %t2)` — one cq_phi hop ABOVE a theta hop —
; while a SIBLING chained theta `%q3 = cq_theta(%q, %t3)` re-rotates `%q`'s
; physical wire. The backward seed closure crosses the diagonal `cq_phi` hop
; (`%qd2 → %q2`, test_C_libtooling-6j1) AND the chained-theta hop
; (`%q2 → %q`, test_C_libtooling-6vk) to the wire origin, exempts the
; on-ancestry producers (`%qd2`, `%q2`, `%q`), and flags only the OFF-ancestry
; sibling `%q3`. Before the theta-hop crossing the closure stopped at `%q2`
; and the forward walk never reached `%q3` (a user of the parent name `%q`) —
; exit 0, verify-clean over-accept. Guard:
; WireWalk::findNonDiagonalWireGate via OpcodeLowering::declineStaleRecordOps.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2, double %t3) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2  = call i32 @cq_theta_si32(i32 %q, double %t2)             ; chained, in-place Ry
  %qd2 = call i32 @cq_phi_si32(i32 %q2, double 1.000000e+00)     ; diagonal alias of %q2 (read by the add)
  %q3  = call i32 @cq_theta_si32(i32 %q, double %t3)             ; SIBLING chained Ry on %q's wire
  %d   = add i32 %qd2, 3                                         ; SSA denotes the pre-%t3 record
  %m   = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
