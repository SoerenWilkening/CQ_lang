; control_predmux_accept_fp_arm_select.ll — ACCEPT (bd vyqi, W5; FORMERLY the
; kjd1 scope-lens DECLINE pin control_swap_reject_select_fp_in_routed_arm.ll):
; an fp select INSIDE a tainted-`br` triangle arm. Pre-W5 this declined
; `value-arm swap-route` because the region went to ArmClassify, whose arm
; vocabulary has no select member — that tripwire is PRESERVED, type-agnostic,
; by control_swap_reject_select_in_routed_arm_intmerge.ll (an INTEGER merge W5
; never claims, so ArmClassify still owns it and still declines). Post-W5 the
; fp sole-phi merge is a claim witness, so the region never reaches the arm
; route: PredMux speculates the arm (fcmp + select are E4 dataflow) and
; converts the merge phi to a second select — `y = c ? (c2 ? p : 2.0) : p` —
; and BOTH selects lower independently through the kjd1 six-gate ladder into
; controlled-copy merges (nested select cascades are the Inc-1-probed
; substrate envelope). The fp un-staging still cannot leak through the ARM
; dialect — ArmClassify is untouched; the shape simply has a sound owner now.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi double' --implicit-check-not='cqrt_cswap' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %p = call double @cq_theta_f64(double %u1, double 2.500000e-01)
  %c = fcmp ogt double %q, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %c2 = fcmp ogt double %p, 1.000000e+00
  %s  = select i1 %c2, double %p, double 2.000000e+00   ; fp select inside the arm
  br label %merge
merge:
  %y = phi double [ %s, %arm ], [ %p, %entry ]
  %m = call double @cq_measure_f64(double %y)
  ret double %m
}

; Two chained controlled-copy merges (inner c2-select, outer c-select), no
; route, no CFG left.
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call void @cqrt_x(
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call double @cqrt_measure_f64(
