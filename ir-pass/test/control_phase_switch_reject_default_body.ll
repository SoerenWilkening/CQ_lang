; control_phase_switch_reject_default_body.ll — DECLINE. A tainted-scrutinee
; phase `switch` with a NON-EMPTY default arm (the 4.5 C5 shape).
;
; The accept shape requires the default edge to go STRAIGHT to the merge. A
; default BODY fires on `¬(f_0 ∨ … ∨ f_{n-1})`, which needs an OR network over
; every case flag plus a negation bracket — buildable with the machinery already
; here (`CondTreeEmit`'s OR node), but a second network per region with its own
; teardown order and no probe family. The 4.5 ladder declined C5 for the same
; reason and this keeps that disposition rather than quietly widening it.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %def [
    i32 0, label %a0
    i32 1, label %a1
  ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
def:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
