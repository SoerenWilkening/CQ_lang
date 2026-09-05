; control_phase_switch_reject_stale_scrutinee.ll — DECLINE. A chained `cq_theta`
; (an IN-PLACE, NON-DIAGONAL Ry) on the SCRUTINEE's wire.
;
; Every eq-flag is minted at the `switch`, so an Ry on `q`'s wire makes them read
; a different basis than the source `switch` did: the wrong case is marked and
; the strip does not return the flag to |0>, so the free becomes a hidden
; measurement (Rule 6). The guard is the 4.5 G10 walk verbatim
; (`findNonDiagonalWireGate` with `CrossValueRouting = TRUE`, so a theta reaching
; the wire only through a one-register router phi is caught too — bd tayx).
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)
  switch i32 %q, label %merge [
    i32 0, label %a0
    i32 1, label %a1
  ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
