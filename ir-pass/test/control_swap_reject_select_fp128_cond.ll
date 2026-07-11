; control_swap_reject_select_fp128_cond.ll — DECLINE (kjd1 Rule-13
; implementation clearance, fcmp-lens minor p6; RE-PINNED by 3c6m.12 exactly
; as this fixture's own comment anticipated): an UNSUPPORTED fcmp CONDITION
; width (fp128 compare) over otherwise-accepted f64 data. The L4 per-leaf
; width fence (`compareFlagMintable`, SelectClassify gate 2) now declines the
; shape at DETECTION in the control dialect — required since the compound
; widening made the emitter's mint non-atomic (an emit-time bail would leave
; sibling leaf flags dangling; the ziov.4 detect-before-mutate discipline) —
; replacing the pre-L4 emit-time `no template for opcode 'fcmp i1'` data-path
; brand (the FP_SELECT_CLEARANCE.md known-minor, now resolved).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cq_template_fcmp
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
