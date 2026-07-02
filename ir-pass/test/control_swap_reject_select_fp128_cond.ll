; control_swap_reject_select_fp128_cond.ll — DECLINE (kjd1 Rule-13
; implementation clearance, fcmp-lens minor p6): an UNSUPPORTED fcmp CONDITION
; width (fp128 compare) over otherwise-accepted f64 data. GATE 2's
; comparePredLowerable is predicate-only and GATE 4 checks the RESULT type, so
; the shape reaches the emitter, whose step-1 flag mint bails on the empty
; fp128 ABI width via diagnoseNoTemplate — LOUD (opt exits non-zero) and
; PRE-mutation (the mint precedes the out-rail and copies, so nothing is
; emitted), but branded in the data-path dialect rather than the control one.
; This fixture pins the loud decline; the branding is a recorded known-minor
; (FP_SELECT_CLEARANCE.md) — re-pin here if a detection-time condition-width
; gate ever sharpens the string.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}no template for opcode 'fcmp i1' in tainted context
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qe  = fpext double %q to fp128                     ; tainted fp128 (whitelisted cast)
  %c   = fcmp ogt fp128 %qe, 0xL00000000000000004001400000000000
  %sel = select i1 %c, double %q, double %x           ; f64 DATA (gate 4 accepts)
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}
