; lowering_reject_classical_mux_phi_lift_thetahop_stale.ll — DECLINE: a
; one-register merge-phi lift whose stale data op is one CHAINED-THETA hop (an
; in-place Ry) below the lifted phi (test_C_libtooling-2qyz; the Rule-13
; adversarial "Probe B4").
;
; The phi `%p` lifts to base `%q`. Its only DIRECT user is the chained theta
; `%qc = cq_theta(%p, %tc)` (an in-place Ry — a wire-sharing consumer, NOT a
; lowered op). The stale arithmetic op `%v = add %qc, 3` is a TRANSITIVE user,
; and a SIBLING chained theta `%q2 = cq_theta(%q, %t2)` re-rotates `%q`'s wire
; before `%v`. Post-RAUW: ry(%h,g); ry(%h,%tc); ry(%h,%t2);
; cq_template_add_i32_hl(%h,3) — the add fires after the off-ancestry sibling Ry
; while `%qc` denotes only Ry(%tc)·Ry(g): a stale-record wrong unitary. The
; intervening hop being a chained theta (not a cq_phi) confirms the blind spot
; is ANY in-place-gate hop, not just diagonal ones. The COMPLETE post-lift
; re-sweep walks `%v`'s wire (crossing the chained-theta hop via the 6vk
; closure) to the origin and flags `%q2`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c, double %g, double %tc, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  %qd = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  br label %merge
merge:
  %p  = phi i32 [ %qd, %arm ], [ %q, %entry ]          ; one register, two SSA names
  %qc = call i32 @cq_theta_si32(i32 %p, double %tc)    ; intervening chained Ry (direct phi user)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)    ; SIBLING chained Ry on %q's wire
  %v  = add i32 %qc, 3                                 ; stale arithmetic op — TRANSITIVE consumer
  %m  = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
