; control_swap_reject_nested_value_mixed.ll — DECLINE: depth-2 nest mixing a
; PHASE outer arm with a VALUE inner arm.
;
; `if (q>5) { q = rz(q,b); if (q<9) { q = q*7; q = q+3; } }` (real clang -O1 —
; the 2-op inner chain resists -O1 if-conversion, so the nest survives as a
; branch). The tree is non-homogeneous: the Mid gate is a diagonal Rz (phase),
; the inner arm a value chain. A phase arm keeps its answer in place + strips
; the flag with icmp_inv; a value arm needs copy-out + reverse-play — no single
; method covers both (the CNOT copy dephases the Rz, Rule 7). The tree-homogeneity
; gate (criterion 6) declines `mixed phase/value arm` BEFORE criterion 4
; RAUW-collapse (a value-op merge incoming does not collapse through the cq_phi
; closure; the reverse order would mis-fire `control flow`).
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
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  %t  = mul nsw i32 %q, 7
  %h  = add nsw i32 %t, 3
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %q, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}cq controlled lowering: mixed phase/value arm under quantum control
