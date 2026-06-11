; lowering_reject_stale_record_alias_chain.ll — DECLINE: the TWO-hop diagonal
; alias layout of lowering_reject_stale_record_alias_sibling.ll
; (test_C_libtooling-6j1). Pins that the seed closure is a CHAIN walk to the
; record boundary, not a single-hop peephole: `%qd2 = cq_phi(%qd1 = cq_phi(%q))`
; still denotes `%q`'s wire (Rz∘Rz is diagonal), so the chained Ry consuming
; the chain-origin sibling `%q` makes the add's record stale exactly as in the
; one-hop fixture. Guard: the backward `cq_phi` arg-0 closure in
; WireWalk::findNonDiagonalWireGate, consumed by
; OpcodeLowering::declineStaleRecordOps.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %qd1 = call i32 @cq_phi_si32(i32 %q, double 1.000000e+00)   ; hop 1
  %qd2 = call i32 @cq_phi_si32(i32 %qd1, double 2.000000e+00) ; hop 2 — same wire
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)           ; chained Ry at the origin
  %d = add i32 %qd2, 3                                        ; PRE-Ry record, post-Ry schedule
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
