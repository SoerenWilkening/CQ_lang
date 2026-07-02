; control_swap_reject_select_fp_qqcond.ll — DECLINE (fp-data-select-PRD §5
; matrix 8): a Q+Q **fcmp** select condition — BOTH compare operands tainted.
; `lowerCompareToFlag` is HL-only (handle + literal); there is no Q+Q flag-mint
; template for fcmp any more than for icmp, so gate 2b declines in the CONTROL
; dialect before any type gate runs. The fcmp twin of
; control_swap_reject_select_qqcond.ll, new with the first accepted fcmp-minted
; merge (the fp un-staging must not widen the CONDITION surface).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: no template
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %y   = call double @cq_theta_f64(double %u1, double 5.000000e-01)
  %c   = fcmp ogt double %q, %y                  ; Q+Q fcmp condition (both tainted)
  %sel = select i1 %c, double %q, double %x
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}
