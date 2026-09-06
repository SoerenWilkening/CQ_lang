; control_swap_reject_ifelse_mixed_phase_defect.ll — DECLINE (MD2 regression):
; the converse of control_swap_reject_ifelse_mixed_value_defect.ll — a FLAT
; if/else whose VALUE arm (first) sits beside a PHASE arm that is ALSO impure (a
; fan-out sibling cq_phi). The mixture guard fires `mixed phase/value arm` at the
; SawValueArm-then-phase check BEFORE the phase arm's own `impure phase arm`
; check. Pins the arm-2-defect-beside-opposite-class order for the value-first
; direction, proving the §12.5 split (4.3) left the FLAT classifyArms path
; bit-identical (MD2). Condition on %q, arms on %p (so the value arm does not
; read the condition operand — the existing _valuefirst idiom). Not nested.
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
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %pt = mul nsw i32 %p, 7
  br label %merge
else:
  call void @cq_phi(double %a)
  call void @cq_phi(double %b)
  br label %merge
merge:
  %pm = phi i32 [ %pt, %then ], [ %p, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
; CHECK: error{{.*}}cq controlled lowering: mixed phase/value arm under quantum control
