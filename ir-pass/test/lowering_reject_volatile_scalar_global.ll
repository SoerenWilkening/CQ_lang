; lowering_reject_volatile_scalar_global.ll — DECLINE PIN (bd zco4): the volatile
; scalar-local SSA promotion is scoped to entry-block ALLOCAS (stack locals). A
; volatile store to a GLOBAL (or a heap pointer) is never a promotion candidate —
; the scan never visits it — so the tainted store to `@g` rides the existing loud
; decline untouched. `@g` is mutably stored, so the volatile-const global-load
; fold (bd 3c6m.14 Inc 3) does not touch it either. If any path silently laundered
; this store the module would compile and this test would fail.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@g = internal global double 0.000000e+00, align 8
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  store volatile double %q, ptr @g, align 8
  %v = load volatile double, ptr @g, align 8
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
