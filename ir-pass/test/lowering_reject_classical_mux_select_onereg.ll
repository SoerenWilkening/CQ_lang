; lowering_reject_classical_mux_select_onereg.ll — DECLINE: the one-register
; SELECT, i.e. the speculation hazard that bounds the 5j5 phi lift
; (test_C_libtooling-5j5, the load-bearing select refutation).
;
; Shape: %q2 = cq_phi(%q, θ) executed UNCONDITIONALLY, then
; `%s = select i1 %c, i32 %q2, i32 %q`. Superficially this is the same
; "two SSA names, one register" pattern the phi lift accepts — but SSA forces
; a select's operands to DOMINATE it, so the gate call has ALREADY FIRED on
; every path when the select executes. The false incoming %q names the
; PRE-gate record of a register that physically no longer holds it: honoring
; the IR would require undoing an applied rotation on the one register
; (non-unitary without cloning). Lifting the select the way the phi is lifted
; (RAUW to %q) would compile "%s is the un-rotated q when !c" to "the
; rotation always applies" — a verify-clean WRONG UNITARY, the exact
; silent-miscompile class this project exists to prevent.
;
; A merge PHI never has this problem: its gate incoming is defined in the
; edge's own predecessor block, so the gate fires iff that edge runs — which
; is why the lift is phi-only. (clang -O1 cannot even produce this select
; from `q = c ? cq_phi(q,θ) : q;` — the opaque call is not speculatable and
; compiles to the branch+phi form, verified 2026-06-10. This select shape is
; handwritten/foreign IR, and it stays declined.)
;
; Guard: TaintPropagation::declineClassicalMuxes (selects are categorically
; never lifted). It OWNS the exact `Msg` string; this CHECK mirrors it
; character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)  ; fires regardless of %c
  %s = select i1 %c, i32 %q2, i32 %q          ; false arm claims the pre-gate record
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition select
