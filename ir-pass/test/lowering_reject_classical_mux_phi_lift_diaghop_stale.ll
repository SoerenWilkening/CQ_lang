; lowering_reject_classical_mux_phi_lift_diaghop_stale.ll — DECLINE: a
; one-register merge-phi lift whose stale data op is one DIAGONAL hop (a
; cq_phi/Rz) below the lifted phi (test_C_libtooling-2qyz; the Rule-13
; adversarial "Probe B" — a transitive consumer the direct-user re-check
; missed).
;
; `if (classical_c) q = cq_phi(q, ·)` lifts `%p` to its base `%q`. The phi's
; only DIRECT user is `%qphi = cq_phi(%p, ·)` — a diagonal Rz, a legitimate
; wire-sharing consumer that is NOT a lowered op. The actual stale arithmetic
; op `%v = add %qphi, 3` is a TRANSITIVE user (of `%qphi`, not of the phi), and
; a SIBLING chained theta `%q2 = cq_theta(%q, %t2)` re-rotates `%q`'s wire
; before `%v`. Post-RAUW the emitted stream is ry(%h,g); rz(%h,·); rz(%h,0.1);
; ry(%h,%t2); cq_template_add_i32_hl(%h,3) — the add fires AFTER the sibling Ry
; while `%v`'s SSA chain denotes the pre-`%t2` record: a stale-record wrong
; unitary.
;
; The original direct-consumer re-check recorded only `%qphi` (skipped — not
; inLowerOpsScope) and never reached `%v`; the fix re-runs the COMPLETE
; declineStaleRecordOps on the post-lift IR (where `%p` is now `%q`), so the
; WireWalk closure walks `%v`'s full wire and finds `%q2`. The op-before-sibling
; accept twin is lowering_classical_mux_phi_lift_diaghop_before_sibling.ll.
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
  %p    = phi i32 [ %q, %arm ], [ %q, %entry ]            ; one register, two SSA names
  %q2   = call i32 @cq_theta_si32(i32 %q, double %t2)        ; SIBLING chained Ry on %q's wire
  %v    = add i32 %p, 3                                   ; stale arithmetic op — TRANSITIVE consumer
  %m    = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
