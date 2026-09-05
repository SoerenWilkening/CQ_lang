; control_phase_switch_reject_merge_phi.ll — DECLINE. A register-free phase
; switch whose merge block carries a φ.
;
; P5 requires the merge to have NO φ. A phase-only region produces no value, so a
; φ there belongs to somebody else, and a φ left standing in a block
; `flattenSwitchRegion` splices away is a BROKEN MODULE at `opt` exit 0 — not a
; decline. This is also the marker that separates the two switch classes: the
; VALUE and DATA-MUX switches DO have a merge φ and are still owned by the
; G0-G11 ladder, which this pre-peel falls through to.
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
    i32 1, label %a1
  ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %k = phi i32 [ 7, %entry ], [ 8, %a0 ], [ 9, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %q)
  %t = add i32 %m, %k
  ret i32 %t
}

; CHECK: cq controlled lowering: control flow under quantum control
