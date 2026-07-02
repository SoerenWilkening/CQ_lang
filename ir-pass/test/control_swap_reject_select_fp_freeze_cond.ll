; control_swap_reject_select_fp_freeze_cond.ll — DECLINE (kjd1 POST-FIX
; refute-default round, E2 major, condition-side spelling): a TAINTED fp
; FreezeInst in the select CONDITION's provenance. Pre-fix: accepted, then the
; theta RAUW left `freeze double %h` ill-typed inside the minted compare's
; feed — SIGABRT 134 instead of a loud decline. Same fence as the operand
; spelling: any FreezeInst in the condition's tainted provenance declines
; `control flow` at detection, before any mutation.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: Broken module
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %f   = freeze double %q                          ; tainted fp freeze on the condition wire
  %c   = fcmp ogt double %f, 5.000000e-01
  %sel = select i1 %c, double %q, double %x
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}
