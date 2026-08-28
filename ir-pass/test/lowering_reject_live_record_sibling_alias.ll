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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 1.000000e+00)      ; diagonal alias — SAME wire
  %d  = add i32 %q, 3                                          ; record off the SIBLING name
  %e  = add i32 %d, 1
  %m  = call i32 @cq_measure_si32(i32 %e)
  %q2 = call i32 @cq_theta_si32(i32 %qd, double 2.500000e-01)  ; chained Ry written on %qd
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %r  = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
