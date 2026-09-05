; control_swap_reject_value_mixed_ifelse_valuefirst.ll — heterogeneous if/else
; with the VALUE arm FIRST (then) and the phase arm second (else) — the
; converse arm order of control_swap_reject_value_mixed_ifelse.ll (4.2 WI-3;
; Rule-12 pin for the SawValueArm-then-phase guard; classification is by
; merge-phi incoming identity, never edge order).
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: mixed phase/value arm under quantum control
; NEW: cq controlled lowering: mixed phase/value arm under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: mixed phase/value arm under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %pt = mul i32 %p, 7                              ; VALUE arm over %p (first)
  br label %merge
else:
  call void @cq_phi(double %a)  ; PHASE arm over %p (second)
  br label %merge
merge:
  %pm = phi i32 [ %pt, %then ], [ %p, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
