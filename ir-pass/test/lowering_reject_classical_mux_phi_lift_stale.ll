; lowering_reject_classical_mux_phi_lift_stale.ll — a classical merge phi
; renames one wire, then a sibling theta makes the lifted record stale (bd 2qyz).
;
; Both incoming phi values are %q. Lifting %p to %q exposes the add's read of
; the pre-theta record after %q2 has rotated that same physical wire.
; declineLiftedStaleRecordOps must revisit that consumer after the lift.
; lowering_classical_mux_phi_lift_op_before_sibling.ll is the accept boundary.
; The retired diagonal alias hops no longer occur in this input.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  br label %merge
merge:
  %p  = phi i32 [ %q, %arm ], [ %q, %entry ]   ; one register, two SSA names
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; SIBLING chained Ry on %q's wire
  %v  = add i32 %p, 3                                 ; reads the lifted phi (pre-%t2 record)
  %m  = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
