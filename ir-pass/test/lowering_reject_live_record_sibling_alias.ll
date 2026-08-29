; lowering_reject_live_record_sibling_alias.ll — DECLINE: the chained theta names
; the DIAGONAL SIBLING of the wire the record was built from (M-A Increment 1).
;
; The over-accept probe this answers (bd test_C_libtooling-lom0 names the
; spelling as "invisible to every other guard", ArmClassify.cpp:1104): the record
; `%d` is built off `%q`, while the gate is written on `%qd = cq_phi(%q, ·)`.
; A guard that compared SSA NAMES would see two different wires and accept.
;
; WHY THE LATE SLOT MAKES THIS STRUCTURAL RATHER THAN A SPECIAL CASE:
; `lowerRotations` RAUWs a `cq_phi` result to its own operand, so by the time
; this guard runs `%qd` and `%q` are LITERALLY THE SAME i32 handle and the
; record walk starts from it with no alias closure of any kind. The pre-mutation
; guards (WireWalk) need an explicit backward `cq_phi` arg-0 closure for exactly
; this shape; here there is nothing left to close over.
;
; `%e` is measured after nothing — it is measured BEFORE the gate, so it is
; exempt by clause 4; `%d` is the dead interior record that carries the decline.
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
;
; ── M-B INCREMENT 5b PRESERVATION NOTE (bd test_C_libtooling-6uqc) ───────────
; The `call void @cqrt_x(i32 %d)` below is NOT part of the shape this fixture
; was written to pin, and it is not decoration either — READ THIS BEFORE
; "simplifying" it away.
;
; Without it, M-B's interior partition now DISCHARGES the record `%d` minted off the sibling name — uncomputes it
; with its out-first `_unc` and frees it — BEFORE the chained `cq_theta`, and the
; guard then correctly ACCEPTS on clause 2 (a record whose own discharge is
; provably before the gate is not standing at it). That accept is right, and it
; is the whole point of Increment 5; what it costs is THIS fixture's premise. The
; program stops containing a live-at-the-gate record, so it stops exercising the
; walk this file exists to pin.
;
; `cqrt_x` is a permutation gate `ChainWalk::isInPlaceGateOn` deliberately does
; not recognize, so it is neither an in-place gate the interior DAG would adjoint
; nor a forward producer: the rail is refused and LEFT ALLOCATED (pinned
; independently by lowering_uncompute_interior_leak_route_consumer.ll). It is
; ALSO a NON-use for the guard's clause-3 observing-sink walk (a route moves a
; value onto a work rail and back; nothing is observed — owner ruling
; 2026-08-28, F1), so the record stays DEAD at the gate and the decline stays
; correct physics: an undischarged basis record entangled with the wire when a
; non-diagonal gate fires.
;
; So this file still measures exactly what it always measured — the seed closure through a DIAGONAL `cq_phi` alias of the same wire — on a
; program where the record really is still standing. The version WITHOUT the
; `cqrt_x` is now an accept, and lowering_live_record_mb_discharged_accept.ll
; is the twin that pins it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cqrt_x(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 1.000000e+00)      ; diagonal alias — SAME wire
  %d  = add i32 %q, 3                                          ; record off the SIBLING name
  call void @cqrt_x(i32 %d)                                 ; see the M-B note above
  %e  = mul i32 %d, 3                                          ; NOT an M-C shape (see below)
  %m  = call i32 @cq_measure_si32(i32 %e)
  %q2 = call i32 @cq_theta_si32(i32 %qd, double 2.500000e-01)  ; chained Ry written on %qd
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
