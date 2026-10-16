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
; RETIRED INTO THIS FILE (bd jttf, 2026-10-05):
; lowering_classical_mux_phi_lift_diaghop_before_sibling.ll, the twin whose add
; read the phi THROUGH an intervening diagonal hop `%qphi = cq_phi(%p, ·)` (the
; pre-3qlq register form). The 3qlq migration deleted the hop and left that
; file's normalized IR identical to this one's. Its register-free spelling (the
; hop as an in-place `cq_theta(%p, tc)`) is not an accept: the sibling chained Ry
; on the pre-hop name `%q` then reads a register the hop already rotated and
; declines `rotation/measure operand predates a non-diagonal gate`, measured
; 2026-10-05 (lowering_reject_classical_mux_phi_lift_thetahop_stale.ll is that
; family's decline).
;
; bd dm7f.83 (ruling-dm7f83-inplace-fence-refusal-loud-2026-10-16): FLIPPED TO
; LOUD. A classical-immediate in-place site here is refused by the M-C fence
; (`inPlaceFenceHolds`: G4's parameter immediate, G5 in a loop, or G6/G7 position)
; while its handle is a DEAD USER REGISTER beside a KEPT result, so the old rail
; would stand beside the result — the r2j3.33 wrong unitary the out-of-place
; fallback used to ship with at most a warning. The in-place round now fails
; loudly (InPlaceQQImm.cpp), as owner Q1 requires. The fixture's original
; expectation is kept dormant: its RUN lines are spelled MC-CMD and no RUN line
; reads its CHECK prefixes. RETIREMENT: restore them when the refused shape
; converts (the dm7f.83 follow-up drops G4; G5-G7 refusals need their own
; lowering).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DM7F83
; DM7F83: error: {{.*}}cq in-place lowering: quantum reassignment of a dead register is not provable in place
;
; MC-CMD: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; MC-CMD: %filecheck %s < %t.cqd0.ll
;
; CHECK:      call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])
; CHECK-NOT:  phi i32
; CHECK-NOT:  cq_phi_si32
; CHECK-NOT:  cq_theta_si32
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
  %v  = add i32 %p, 3                                 ; BEFORE the sibling Ry — pre-Ry on its own rail
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; SIBLING chained Ry, AFTER the add
  %m  = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
