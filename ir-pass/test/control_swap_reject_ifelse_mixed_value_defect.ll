; control_swap_reject_ifelse_mixed_value_defect.ll — DECLINE (MD2 regression): a
; FLAT if/else whose phase arm sits beside a value arm that is ALSO impure (a
; fan-out chain link). The heterogeneous-mixture guard fires `mixed phase/value
; arm` BEFORE the value arm's own `impure value arm` / QQ-defer checks — the
; live string for an arm-2-also-defective if/else. Pins that the §12.5
; tree-homogeneity split (4.3) left the FLAT classifyArms order bit-identical
; (the flat path is NOT re-hosted — MD2). Not a nested region; exercises the
; unchanged 4.2 path.
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: mixed phase/value arm under quantum control
; NEW: cq controlled lowering: impure phase arm under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)
  br label %merge
else:
  %t  = add nsw i32 %q, 3
  %qe = mul nsw i32 %t, %t
  br label %merge
merge:
  %qm = phi i32 [ %q, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}cq controlled lowering: impure phase arm under quantum control
