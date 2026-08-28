; lowering_reject_live_record_router_phi.ll — DECLINE: the gate reaches its wire
; through a one-register ROUTER PHI (the bd tayx spelling), with a dead record
; minted before the branch (M-A Increment 1).
;
; This is the SPIKE §1.4 blind-spot-U4 witness program, verbatim except for the
; two record-building adds. At HEAD (pre-guard) it lowers with `opt` exit 0 and
; ONE `cqrt_alloc_i32`: `declineClassicalMuxes`'s one-register merge-phi LIFT
; (test_C_libtooling-5j5) proves `%p` a pure SSA renaming of `%q`'s register,
; RAUWs it to the wire base and erases it. The condition `%c` is CLASSICAL, so
; ControlDetect never sees a region here at all.
;
; THE PROBE: a chained theta whose arg-0 is the PHI. bd tayx measured that a
; pre-compare router phi hides a chained theta from the position-free wire walks
; on three separate paths; the guard must not be evadable the same way. It is
; not, and again structurally rather than by a special case — the lift runs at
; run-line 381, ~90 lines BEFORE `lowerRotations`, so at this late slot the
; recorded `cqrt_ry`'s arg-0 already IS the wire base and `%d` is found by an
; ordinary forward walk.
;
;
; VEHICLE-OP NOTE (bd test_C_libtooling-6uqc, M-C Increment 2a — `add` only).
; The terminal record used to be built with `add`. M-C now lowers a
; dead-parent `q + c` IN PLACE (`cqrt_addc_<W>`), which would COLLAPSE the two
; rails this fixture needs into one: the interior record and the terminal record
; would become the same register, the measurement would land on the interior
; record itself, and clause 4 (measured-before-the-gate ⇒ collapsed ⇒ exempt)
; would exempt it — the module would ACCEPT for a reason that has nothing to do
; with what this file pins. The vehicle is therefore `mul`, which is
; information-LOSING and so is deliberately outside the dtzb in-place bijection
; family (`inPlaceValueRailOperand`) at every batch, not just this one. The
; STRUCTURE under test — a dead interior record standing at the gate — is
; unchanged; only the arithmetic that builds the terminal record moved.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = add i32 %q, 3                                           ; DEAD record at the gate
  %e = mul i32 %d, 3                                           ; NOT an M-C shape (see below)
  %m = call i32 @cq_measure_si32(i32 %e)
  br i1 %c, label %arm, label %merge                           ; CLASSICAL condition

arm:
  %qz = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)     ; diagonal, in place
  br label %merge

merge:
  %p  = phi i32 [ %qz, %arm ], [ %q, %entry ]                  ; the one-register router
  %q2 = call i32 @cq_theta_si32(i32 %p, double 1.250000e-01)   ; chained Ry THROUGH the phi
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
