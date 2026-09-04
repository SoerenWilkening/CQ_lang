; lowering_reject_classical_mux_phi_crossblock_chain.ll — DECLINE: one-base
; merge phi whose gate chain ESCAPES the incoming block
; (test_C_libtooling-5j5 decline complement; pins lift condition (6)).
;
; Both incomings DO resolve to the one base %q — but the arm incoming's chain
; is {%q2 in %arm, %q3 in %entry}: the %q3 = cq_phi(%q, x) gate fired BEFORE
; the branch, unconditionally, on every path. The straight edge's incoming
; %q then claims the PRE-%q3 record while the physical register always
; carries rz(x): a stale record on every not-taken shot. Accepting + RAUW to
; %q would be the verify-clean wrong-unitary class, so the single-block-arm
; condition (every chain call's parent == its edge's incoming block) refuses
; and the wi5 decline fires.
;
; (The conservative cost: the variant whose straight edge carries %q3 itself
; — per-path records actually consistent — is ALSO declined by the same
; condition. Over-declining is always safe; documented in
; liftOneRegisterMergePhi.)
;
; ⚠ ONE NARROW EXCEPTION EXISTS SINCE bd test_C_libtooling-drbq Increment 3 and
; it does NOT reach this file. `resolveWireBase` now STOPS at a call recorded in
; `taint.ControlledRotations` — a gate `ControlDetect`/`classifyAngleSelect` and
; a region emitter already adjudicated — treating its result as the base. Those
; gates dominate every incoming edge, so they discharge condition (6)'s
; obligation by DOMINATION instead of by edge-locality. `%q3` here is an
; ORDINARY uncontrolled `cq_phi` in nobody's `ControlledRotations`, so this
; decline and the conservative-cost variant above both stand unchanged. Making
; the strip dominance-based in general would cover them too and is a real
; widening of this accept class — its own probe family, its own Rule-13 round.
; Accept siblings: control_inplace_ry_lifted_phi_after_region.ll,
; control_angle_select_ry_lifted_phi_after_select.ll.
;
; Guard: TaintPropagation::declineClassicalMuxes. It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q3 = call i32 @cq_phi_si32(i32 %q, double 1.250000e-01)   ; pre-branch gate
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  %q2 = call i32 @cq_phi_si32(i32 %q3, double 2.500000e-01)
  br label %merge
merge:
  %p = phi i32 [ %q2, %arm ], [ %q, %entry ]    ; straight edge: stale pre-%q3 record
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
