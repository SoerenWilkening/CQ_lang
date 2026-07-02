; control_swap_reject_select_fp_coherent_call_derived.ll — DECLINE (kjd1
; Rule-13 implementation clearance, angle-fence-lens MAJOR; probe p9): the
; select operand %q feeds a CURATED libm call (`cbrt`) whose result gets a
; downstream cq_phi (Rz) on its wire — the channel-B dephasing family through a
; CALL-shaped producer. The pre-fix forward coherence walk `continue`d on every
; non-sink, non-rotation CallInst user WITHOUT walking its result (the "a
; surviving tainted call user is benign here" rationale, stale since the 7.1/
; libm curated carves let call producers survive the escape guard), so this
; accepted and lowered verify-clean while the instruction twin (fmul instead of
; cbrt) declined. The fixed walk pushes a surviving call's tainted result — a
; curated producer continues the coherence lineage exactly like an arithmetic
; instruction. Natural in the PRD's own motivating branchless-libm workload.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)
declare double @cbrt(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c   = fcmp ogt double %q, 5.000000e-01
  %sel = select i1 %c, double %q, double 1.000000e+00
  %d   = call double @cbrt(double %q)                            ; curated call producer
  %qd  = call double @cq_phi_f64(double %d, double 3.000000e-01) ; Rz ON the derived wire
  %m   = call double @cq_measure_f64(double %sel)
  %m2  = call double @cq_measure_f64(double %qd)
  ret double %m
}
