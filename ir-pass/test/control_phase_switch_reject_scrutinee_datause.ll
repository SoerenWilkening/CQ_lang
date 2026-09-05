; control_phase_switch_reject_scrutinee_datause.ll — DECLINE. An UNOWNED data use
; of the scrutinee (`int d = q + 1;` beside the switch).
;
; The eq-flag mints and strips keep `q` alive as a compare operand, but a data
; op off `q` mints a FRESH rail holding a copy of a function of `q`, entangled
; with it and with no downstream owner — a dirty rail (Rules 6/8). The allowlist
; is exact and short: the switch itself, a `ret` (the caller owns the handle) and
; a recognized `@cq_measure_<sfx>` sink (EXACT membership against
; `taint.MeasureCalls`, never a name prefix — an opaque `cq_measure_evil` must
; not confer ownership). This is the 4.5 G10 discipline, unchanged.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = add i32 %q, 1
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
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: condition data use neither escaped nor measured under quantum control
