; control_phase_switch_reject_grouped.ll — DECLINE. GROUPED FALL-THROUGH: two
; case values targeting one arm block (`case 0: case 1: cq_phi(.1);`).
;
; Lowerable in principle — the arm would ride the OR of its two values' eq-flags,
; which is one more `CondTreeEmit` node — but that is a second network per arm
; and a widening nobody has probed. The 4.5 G9 decline covers it today and
; over-declining is safe.
;
; ⚠ DO NOT "FIX" THIS BY MINTING ONE FLAG PER ARM FROM THE FIRST VALUE ONLY. That
; is the shape of the mistake: `f = (q == 0)` would silently drop the `case 1`
; branch's phase, verify-clean, with every free still pairing.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [
    i32 0, label %a0
    i32 1, label %a0
    i32 2, label %a2
  ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a2:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
