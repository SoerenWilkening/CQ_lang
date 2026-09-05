; control_swap_reject_value_mixed.ll — mixed cq_phi + value links in ONE chain
; decline (4.2 WI-3; PRD Part II §8.3 row "mixed"; fixture pair partner:
; control_swap_reject_value_mixed_spine.ll, the opposite stacking order).
;
; `if (q > 5) { rz(p, a); p = p + 3; }` — the merge contribution is a value op
; stacked on an IN-ARM rotation (`add(cq_phi(p,a), 3)`). The answer then
; carries BOTH a phase and a changed basis: the method-B CNOT copy-out copies
; only the basis label (dephasing the Rz answer — P0 0.585->0.500, Rule 7), and
; the phase-arm icmp_inv flag-strip is invalid over a changed basis. There is
; no copy-safe, strip-valid lowering for a mixed chain — §6a control-in-place
; territory; declined loudly with its own string.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}mixed phase/value arm under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)  ; in-arm Rz...
  %p1 = add i32 %p, 3                             ; ...under a value link: MIXED
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
