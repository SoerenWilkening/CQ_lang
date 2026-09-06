; control_phase_switch_reject_tainted_angle.ll — DECLINE. A QUANTUM-DERIVED angle
; in a switch arm's `cq_phi` (Rule 3).
;
; Same rule, same dialect and same string as every sibling phase path: a tainted
; angle would put quantum data in a gate's classical slot, and after rotation
; lowering's RAUW the emitted `cqrt_rz_i1(f, <i32 handle>)` reads a fixed per-run
; tag standing in for a value in superposition — no fixed unitary, the f64/angle
; miscompile family.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)

define i32 @example(i32 %u0, double %a0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = call double @cq_theta_f64(double %a0, double 1.000000e-01)
  switch i32 %q, label %merge [
    i32 0, label %c0
    i32 1, label %c1
  ]
c0:
  call void @cq_phi(double %ang)
  br label %merge
c1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: rotation angle under quantum control
