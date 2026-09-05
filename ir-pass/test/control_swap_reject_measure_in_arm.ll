; control_swap_reject_measure_in_arm.ll — DECLINE probe: a phase-arm diamond
; whose arm block holds a STRAY op beyond the phase spine — here a user
; `cq_measure` of a DIFFERENT tainted handle (swap-route 4.1 §8 adversarial review).
;
; The merge-feeding spine is the pure phase chain q -> %q1 -> %q2, which a naive
; arm classifier would accept. But the arm block ALSO measures %p (an unrelated
; quantum handle) under quantum control. The swap-route emitter neither replays
; nor scrubs that measure; RegionFlatten erases the whole arm block, which would
; (a) SILENTLY DROP the user's measurement of %p (Rule 5 — never drop/insert a
; measurement) and (b) leave its taint.MeasureCalls pointer dangling → a
; use-after-free in lowerMeasures. The arm must be EXACTLY the linear phase spine;
; a stray op trips the `impure phase arm` decline (over-decline is safe; Prime
; Directive). Detection is pure SSA-value analysis before any mutation.
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: impure phase arm under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  call void @cq_phi(double %b)
  %mp = call i32 @cq_measure_si32(i32 %p)   ; STRAY: a measurement under quantum control
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
