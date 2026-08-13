; lowering_classical_mux_phi_lift_op_before_sibling.ll — ACCEPT: the
; don't-over-decline twin of lowering_reject_classical_mux_phi_lift_stale.ll
; (test_C_libtooling-2qyz / -5j5).
;
; Same one-register merge-phi lift, same sibling chained theta `%q2` on `%q`'s
; wire — but `%v = add %p, 3` is scheduled BEFORE `%q2`. After the lift
; (`%p → %q`) the post-lift re-check (OpcodeLowering::declineLiftedStaleRecordOps)
; is POSITION-AWARE: the template is emitted at the add's own position, PRE-Ry,
; capturing exactly the record `%p` denotes onto its own fresh rail; the later
; Ry on `%q`'s wire cannot touch that rail. The lift still fires (the phi is a
; pure renaming) AND the add lowers — a legitimate use-then-re-rotate program.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:      call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])
; CHECK-NOT:  phi i32
; CHECK-NOT:  cq_phi_si32
; CHECK-NOT:  cq_theta_si32

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
  %v  = add i32 %p, 3                                 ; BEFORE the sibling Ry — pre-Ry on its own rail
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; SIBLING chained Ry, AFTER the add
  %m  = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
