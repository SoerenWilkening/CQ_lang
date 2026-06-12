; control_swap_reject_nested_inner_clobber.ll — DECLINE: inner VALUE-write whose
; chain rewrites the register the inner condition read (the §3c clobber).
;
; `if (q>5) { q = rz(q,b); if (q<9) { q = q*7; q = q+3; } }` — the inner arm
; value-rewrites q, which the inner condition `q<9` read. The §12.5 union-§3c
; provenance is BUILT but VACUOUS in 4.3: a value-write IS a value arm, so the
; tree-homogeneity gate (a phase Mid beside a value inner arm) fires FIRST,
; `mixed phase/value arm` — NOT `arm rewrites a condition operand`, which is
; dead-in-4.3 (homogeneity precedes §3c; IMPLEMENTATION-4.3 §12.5). Same -O1
; shape as control_swap_reject_nested_value_mixed.ll; pinned separately as the
; clobber-specific contract that the §3c string does NOT leak through.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %g, 9
  br i1 %c2, label %arm, label %merge
arm:
  %t  = mul nsw i32 %g, 7
  %h  = add nsw i32 %t, 3
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}mixed phase/value arm under quantum control
