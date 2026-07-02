; control_swap_reject_select_fp_theta_fork.ll — DECLINE (kjd1 Rule-13
; implementation clearance, coherence-lens; the INTERFERENCE half of the
; wire-anchoring fix): an OFF-ANCESTRY sibling cq_theta on the select operand's
; wire, hanging off an OLD ALIAS. The operand %q1 = theta(%q0) is a rebased SSA
; name for %q0's physical handle; the later `theta(%q0, 0.9)` is an Ry applied
; to the SAME wire after the copy — downstream interference that observes the
; copied operand's coherence (channel B, decline-matrix item 4) — yet it is a
; user of the SIBLING alias %q0, invisible to the pre-fix forward walk that
; started at %q1 alone (a fork directly off the OPERAND was already caught;
; the ancestor-alias spelling was not — the same SSA-vs-wire blindness as the
; sibling-phase fixture). The condition reads a SEPARATE register %r so the
; stale-condition guard (position-free over the CONDITION's wire) does not
; fire first — this pins gate 5's off-ancestry-rotation flag specifically.
; On-ancestry thetas (the operand's own producer chain — here %q1 itself)
; remain exempt: a chained prep `select(c, theta(theta(q)), x)` still accepts.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1, double %x) {
entry:
  %q0  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %q1  = call double @cq_theta_f64(double %q0, double 3.000000e-01) ; rebase: Op's ancestry {q1,q0}
  %r   = call double @cq_theta_f64(double %u1, double 5.000000e-01) ; separate condition register
  %c   = fcmp ogt double %r, 5.000000e-01
  %sel = select i1 %c, double %q1, double %x
  %q2  = call double @cq_theta_f64(double %q0, double 9.000000e-01) ; OFF-ancestry Ry, old alias, post-select
  %m   = call double @cq_measure_f64(double %sel)
  %m2  = call double @cq_measure_f64(double %q2)
  ret double %m
}
