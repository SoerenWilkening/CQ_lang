; control_swap_reject_abort_fp_cond.ll — DECLINE (kjd1 Rule-13 clearance,
; completeness-critic gap: the §5.9c AbortPark leg had no fp fixture): a
; controlled `abort()` under an fp (fcmp) tainted condition. The abort-park
; lowering's width fence (`widthHasReversibleCopy`, AbortParkEmit.cpp — one of
; the 7 untouched call sites the fp select un-staging must NOT move) has no
; reversible copy for an fp condition register, so the park declines loudly.
; fp is structurally reachable here (the condition dispatch is dyn_cast<CmpInst>,
; which accepts FCmpInst) — this fixture is the fp tripwire pinning that the
; select-local fp accept did not leak into the abort-park path.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_tape_write
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare void @abort() noreturn

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp ogt double %q, 5.000000e-01
  br i1 %c, label %die, label %cont
die:
  call void @abort()
  unreachable
cont:
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}
