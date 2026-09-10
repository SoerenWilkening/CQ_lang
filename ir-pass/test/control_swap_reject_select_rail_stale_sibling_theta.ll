; control_swap_reject_select_rail_stale_sibling_theta.ll — DECLINE (bd
; test_C_libtooling-r9e5, Inc 1b-B.1): `bool t = (bool)(q & 1); bool b =
; cq_theta(t, .5); bool c = cq_theta(t, .9); int a = b ? 2 : 5;` — `b` and `c`
; are SIBLING in-place Ry on ONE physical rail (both chained on the TEMPLATE
; result `t`), and the select reads the STALE name `b`. The select form of the
; 3qlq.4 round-1 CONFIRMED silent miscompile F-1b-1, whose fix lives in the
; shared walker: `WireWalk::findNonDiagonalWireGate` crosses a chained theta's
; arg-0 edge whenever the parent is TAINTED (the relation `lowerRotations`
; builds the rail from), so the sibling is on the register's wire and the DT
; prong cannot prove it post-select (it precedes it).
;
; GREEN ON BOTH BINARIES, and that is what it pins: the 1b-B.1 DT-prong widening
; must NOT reach this class. MEASURED — with the DT re-ask deleted (accept
; whenever a tree exists) this fixture, `..._stale_chained_between.ll` and
; `..._inloop_stale_theta.ll` all flip to ACCEPT.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %t, double 9.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %n = call i32 @cq_measure_si32(i32 %a)
  %m = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %m to i32
  %r = add i32 %n, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
