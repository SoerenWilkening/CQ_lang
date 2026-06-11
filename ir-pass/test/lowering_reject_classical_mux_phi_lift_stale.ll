; lowering_reject_classical_mux_phi_lift_stale.ll — DECLINE: a one-register
; merge-phi lift (test_C_libtooling-5j5) that, once it RAUWs the phi to its
; wire base, exposes a stale-record consumer the EARLIER straight-line guard
; could not see (test_C_libtooling-2qyz).
;
; `if (classical_c) q = cq_phi(q, ·)` survives `clang -O1` as the merge phi
; `%p = phi [%qd, %arm], [%q, %entry]` — a proven pure renaming of `%q`'s wire,
; lifted (RAUW `%p → %q`, then erased). But a SIBLING chained theta
; `%q2 = cq_theta(%q, %t2)` re-rotates `%q`'s wire in the merge block, and
; `%v = add %p, 3` reads the lifted phi AFTER it: post-RAUW `%v = add %q, 3`
; fires (at the add's position, after `cqrt_ry(%h, %t2)`) on the post-`%t2`
; basis while `%p`/`%q` denote the pre-`%t2` record — the stale-record family.
;
; declineStaleRecordOps runs BEFORE the lift and saw only the PHINode operand
; `%p` (not a `cq_phi` CALL): its backward closure stops, the forward walk from
; `%p` never reaches `%q`'s sibling theta, so it accepted — exit 0, verify-clean
; over-accept through the lift gateway. The fix re-adjudicates every lifted
; consumer after `declineClassicalMuxes` (OpcodeLowering::declineLiftedStaleRecordOps,
; seeded at the wire base `%q` where the sibling `%q2` IS a direct arg-0 user),
; emitting the same straight-line message. The op-before-sibling accept twin is
; lowering_classical_mux_phi_lift_op_before_sibling.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  %qd = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  br label %merge
merge:
  %p  = phi i32 [ %qd, %arm ], [ %q, %entry ]   ; one register, two SSA names
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; SIBLING chained Ry on %q's wire
  %v  = add i32 %p, 3                                 ; reads the lifted phi (pre-%t2 record)
  %m  = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
