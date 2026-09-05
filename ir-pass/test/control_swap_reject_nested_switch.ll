; control_swap_reject_nested_switch.ll — DECLINE: an inner switch under an outer
; tainted branch.
;
; `if (q>5) { q = rz(q,b); switch(q){...} }` — the Mid arm ends in a tainted
; `switch`, so the outer arm has no unconditional fall-through: recoverRegion
; classifies the outer branch OffPattern → `control flow` (fired on the OUTER
; branch, before the inner switch scan could emit the 4.5-unbuilt `switch`
; string). Over-declining is safe (Prime Directive); pinned to the string that
; actually fires on real -O1.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: lowering: control flow under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  switch i32 %q, label %merge [
    i32 1, label %a1
    i32 2, label %a2
  ]
a1:
  call void @cq_phi(double %a)
  br label %merge
a2:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
