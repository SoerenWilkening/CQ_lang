; control_swap_reject_ctrl_cond_unlowerable_fcmp.ll — DECLINE probe
; (test_C_libtooling-jvun, flat control-condition facet): a phase-arm diamond
; whose CONTROL condition is an OUT-OF-SCOPE fcmp predicate must decline in
; DETECTION (Rule 9), not by minting a non-existent flag template.
;
; The control flag is minted FROM the branch condition's predicate. `fcmp false`
; (the degenerate always-0) is outside the fcmp surface, so it has NO template.
; Before jvun, `SwapRouteEmit` minted a non-existent `cq_template_fcmp_false_f64_hl`
; flag (exit 0, link-fail at Stage 3). jvun gates the control-condition predicate
; in `classifyArms` (detection) via `comparePredLowerable`, declining loudly
; BEFORE any route/flatten. (The flat mint is emit step 1 so no mutation occurs
; either way, but declining in detection is the uniform Rule-9 posture and gives
; a precise reason.) After 8rvn (Phase 7.1 iw81.4 §4.4) admitted the full
; ordered/unordered comparison family, `true`/`false` are the only out-of-set
; fcmp predicates left — so `false` is the standing residual for this call site.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control condition has no template under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cq_template_fcmp_false
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %a) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c  = fcmp false double %q, 5.0       ; OUT-OF-SCOPE control predicate (`false`)
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call double @cq_measure_f64(double %q)
  ret double %m
}
