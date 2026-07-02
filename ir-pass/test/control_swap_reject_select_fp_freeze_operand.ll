; control_swap_reject_select_fp_freeze_operand.ll — DECLINE (kjd1 POST-FIX
; refute-default round, E2 major; FP_SELECT_CLEARANCE.md addendum): a TAINTED
; fp FreezeInst as a select operand. Pre-fix this passed every gate and then
; CRASHED (SIGABRT 134, 'Broken module found'): rotation lowering RAUWs the
; theta result to the i32 handle, which leaves `freeze double %h` ILL-TYPED —
; an fp freeze survives to the emitter because declineTaintEscapes SKIPS
; fp-typed tainted freezes (7.1 Inc B) and, unlike the integer case, nothing
; folds it before lowering. A crash on valid input violates the
; decline-loudly-or-lower contract (Rule 1) — newly fp-reachable through the
; kjd1 gate-4 accept (pre-kjd1, gate 4 declined every fp select loudly).
; Fixed: the select classifier declines any select whose tainted operand
; LINEAGE (or condition provenance) contains a FreezeInst.
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
  %f   = freeze double %q                          ; tainted fp freeze — un-launderable
  %c   = fcmp ogt double %q, 5.000000e-01
  %sel = select i1 %c, double %f, double %x
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}
