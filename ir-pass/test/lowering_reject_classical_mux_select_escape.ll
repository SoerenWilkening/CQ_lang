; lowering_reject_classical_mux_select_escape.ll — DECLINE: classical-cond
; select over tainted data whose base handle ESCAPES via `ret`
; (test_C_libtooling-wi5, the Escaped-bypass variant).
;
; Same family as the measured-base shape, bypassing the Phase-5 net through the
; OTHER early return: `computeFreePoint` classifies %q `Escaped` (the `ret` is a
; recognized escape — the caller owns the handle) BEFORE its FirstUnrecognized
; check, so pre-guard the select sailed through silently (confirmed exit 0).
; The escape classification itself is correct and stays pinned (ACCEPT:
; lowering_uncompute_escape_return.ll — an escaped handle with only recognized
; users gets no adjoint, no free, NO diagnostic); the select is what makes this
; module unprovable, and the select is what the guard declines.
;
; Guard: TaintPropagation::declineClassicalMuxes (post-control, pre-rotation,
; both entry points). It OWNS the exact `Msg` string; this CHECK mirrors it
; character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = select i1 %c, i32 %q, i32 5            ; classical-cond mux over the handle
  %m1 = call i32 @cq_measure_si32(i32 %s)     ; "handle-or-5" measured as a handle
  ret i32 %q                                  ; base escapes -> FreePoint net bypassed
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition select
