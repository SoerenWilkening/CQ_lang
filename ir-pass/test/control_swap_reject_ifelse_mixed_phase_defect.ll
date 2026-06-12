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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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
  %pe = call i32 @cq_phi_si32(i32 %p, double %a)
  %jn = call i32 @cq_phi_si32(i32 %p, double %b)
  br label %merge
merge:
  %pm = phi i32 [ %pt, %then ], [ %pe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
; CHECK: error{{.*}}mixed phase/value arm under quantum control
