; control_swap_select_fpdata.ll — ACCEPT (RE-PINNED from the staged-out decline,
; a deliberate Rule-12 baseline action): the fp-DATA select over TWO TAINTED f64
; operands (fp-data-select-PRD §5; parent PRD §17 "re-pinned to accept once fp
; is cleared" — the clearance is the §2 three-legged angle fence + the §6
; Rule-13 record). Formerly control_swap_reject_select_fpdata.ll, which pinned
; the §16.4 staging ("an FP merge under tainted control is categorically an
; angle"); that categorical belief is retired FOR SELECT ONLY — every other
; consumer (Switch G4, ArmClassify value arms, ClassicalCallArm via the
; untouched copyControlledFn null, IOSink, AbortPark, Qram) keeps declining fp.
;
; Both operands are tainted (`%q` theta-derived, `%qb = fadd %q, 1.0` a fresh
; out-of-place template result), so NEITHER copy source is materialized — both
; are already handles; gate 6 accepts (disjoint diagonal-alias closures) and
; gate 5 accepts (theta lineage is a REAL-amplitude basis superposition; no
; cq_phi anywhere). The result is MEASURED (data sink), so gate 3 passes.
;
; This fixture is ALSO the §6 uncompute-spine lit pin: the copied source chain
; (`%qb`'s fadd template) is DEAD after the merge, but its `_controlled` user
; marks the DAG NotClosed (DagTraversal), so the theta-derived source lineage is
; deliberately LEAKED — no `_unc` twin fires, and the ONLY free is the flag's
; (the out-rail and both sources stay allocated; Rules 6/8). The tail CHECK-NOTs
; cover the post-merge region AND the module-appended minted declarations.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck --check-prefix=UNC %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qb  = fadd double %q, 1.000000e+00              ; a distinct tainted f64 data value
  %c   = fcmp ogt double %q, 5.000000e+00          ; tainted condition (ogt in scope)
  %sel = select i1 %c, double %q, double %qb       ; f64 DATA mux, both operands tainted
  %m   = call double @cq_measure_f64(double %sel)  ; data sink (NOT an angle)
  ret double %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     %[[QB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[Q]], double 1.000000e+00)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 5.000000e+00)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[QB]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F]], i32 %[[Q]], double 5.000000e+00)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
; the leak assertion (§6): nothing after the measure — no source free, no _unc
; call, and no _unc / integer-copy declaration among the module-appended mints.
; bd `8txa`: the flag STRIP is itself a `_unc` now, so the pre-8txa blanket
; `CHECK-NOT: _unc` cannot be restored verbatim. Pin the exact population
; instead — EXACTLY ONE `_unc` call in the module, and it is the compare
; strip. Strictly stronger than the blanket form for the double-strip case
; (a second strip on an already-freed rail is a UAF + wrong unitary), and
; it still forbids any DATA uncompute (that would be a second `_unc` call).
; UNC-COUNT-1: call void @cq_template_{{[if]}}cmp_{{[a-zA-Z0-9_]+}}_unc(
; UNC-NOT:     call {{.*}}_unc(
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy_i
