; lowering_reject_classical_mux_select_onereg.ll — DECLINE: the one-register
; SELECT, i.e. the speculation hazard that bounds the 5j5 phi lift
; (test_C_libtooling-5j5, the load-bearing select refutation).
;
; Shape today: `%s = select i1 %c, i32 %q, i32 %q`. Before bd 3qlq the true
; operand was an unconditional register-form gate `%q2 = cq_phi(%q, θ)`; the
; migration deleted that uncontrolled phase (note below), so both operands are %q.
;
; The lift is phi-only. A merge PHI's gate incoming is defined in the edge's own
; predecessor block, so the gate fires iff that edge runs. A select's operands
; DOMINATE it, so a gate on either operand has already fired on every path, and
; lifting the select (RAUW to the base) would be a verify-clean WRONG UNITARY.
; The guard therefore never lifts a select over tainted data, and this one
; declines.
;
; Guard: TaintPropagation::declineClassicalMuxes (selects are categorically
; never lifted). It OWNS the exact `Msg` string; this CHECK mirrors it
; character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = select i1 %c, i32 %q, i32 %q          ; false arm claims the pre-gate record
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition select
