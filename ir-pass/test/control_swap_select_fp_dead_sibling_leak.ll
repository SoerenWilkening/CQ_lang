; control_swap_select_fp_dead_sibling_leak.ll — ACCEPT + the §6 uncompute-spine
; NotClosed pin (kjd1 Rule-13 implementation clearance, uncompute-lens minor):
; the initially-shipped leak pins were TRIVIALLY green (no dead terminal
; existed, so terminal selection never ran and the closure scan — where
; ChainWalk::isCopyOutSink's `_controlled` exclusion is load-bearing against
; the NEW fp symbol names — was never exercised). Here `%w = fmul(%t, 2.0)` is
; a DEAD sibling terminal off the copied source chain: the spine DOES select
; it and recover its DAG, the DAG's `cqrt_copy_f64_controlled` user marks it
; NotClosed (DagTraversal), and the WHOLE chain is deliberately LEAKED — no
; `_unc` twin fires and the ONLY free is the flag's. If a future name-pattern
; change made isCopyOutSink match the fp `_controlled` names, this fixture is
; the tripwire (the copy would be mis-classed a reversible copy-out sink and
; the chain wrongly uncomputed under a live entangled copy).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=UNC %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t   = fadd double %q, 1.000000e+00              ; copied source chain
  %w   = fmul double %t, 2.000000e+00              ; DEAD sibling terminal
  %c   = fcmp ogt double %q, 5.000000e-01
  %sel = select i1 %c, double %t, double 2.500000e-01
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}

; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(
; (bd dm7f.81: the constant 0.25 arm is a literal of the controlled xor; the
; quantum `%t` arm is still the controlled copy that keeps the DAG NotClosed.)
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call void @cqrt_xorc_f64_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double 2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call double @cqrt_measure_f64(
; the NotClosed leak: nothing after the measure — no _unc, no further free.
; bd `8txa`: the flag STRIP is itself a `_unc` now, so the pre-8txa blanket
; `CHECK-NOT: _unc` cannot be restored verbatim. Pin the exact population
; instead — EXACTLY ONE `_unc` call in the module, and it is the compare
; strip. Strictly stronger than the blanket form for the double-strip case
; (a second strip on an already-freed rail is a UAF + wrong unitary), and
; it still forbids any DATA uncompute (that would be a second `_unc` call).
; UNC-COUNT-1: call void @cq_template_{{[if]}}cmp_{{[a-zA-Z0-9_]+}}_unc(
; UNC-NOT:     call {{.*}}_unc(
; CHECK-NOT: call void @cqrt_free
