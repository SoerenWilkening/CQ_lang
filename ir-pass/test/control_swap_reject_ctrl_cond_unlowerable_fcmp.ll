; control_swap_reject_ctrl_cond_unlowerable_fcmp.ll — DECLINE probe
; (test_C_libtooling-jvun, flat control-condition facet): a phase-arm diamond
; whose CONTROL condition is an OUT-OF-SCOPE fcmp predicate must decline in
; DETECTION (Rule 9), not by minting a non-existent flag template.
;
; The control flag is minted FROM the branch condition's predicate. `fcmp one`
; (ordered-not-equal) is outside the 6-predicate fcmp surface ({oeq,une,olt,ogt,
; ole,oge}), so it has NO template. Before jvun, `SwapRouteEmit` minted a
; non-existent `cq_template_fcmp_one_f64_hl` flag (exit 0, link-fail at Stage 3).
; jvun gates the control-condition predicate in `classifyArms` (detection) via
; `comparePredLowerable`, declining loudly BEFORE any route/flatten. (The flat
; mint is emit step 1 so no mutation occurs either way, but declining in
; detection is the uniform Rule-9 posture and gives a precise reason.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control condition has no template under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cq_template_fcmp_one
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %a) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qd = call double @cq_phi_f64(double %q, double 9.000000e-01)
  %c  = fcmp one double %qd, 5.0         ; OUT-OF-SCOPE control predicate (`one`)
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call double @cq_phi_f64(double %qd, double %a)
  br label %merge
merge:
  %qm = phi double [ %q1, %arm ], [ %qd, %entry ]
  %m  = call double @cq_measure_f64(double %qm)
  ret double %m
}
