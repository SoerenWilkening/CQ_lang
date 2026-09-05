; control_swap_reject_nested_inner_cond_unlowerable_fcmp.ll — DECLINE probe
; (test_C_libtooling-jvun, nested INNER control-condition facet — the genuine
; mutate-then-decline this gate prevents).
;
; A depth-2 phase nest whose OUTER condition is in scope (`fcmp ogt`) but whose
; INNER condition is an OUT-OF-SCOPE fcmp predicate (`fcmp false`, no template).
; In NestedRouteEmit the OUTER flag mint is step 1 (null-bails clean), but the
; INNER flag mint (F2) happens AFTER the outer rail alloc + route-in + Mid replay
; (lines NestedRouteEmit.cpp §1–2). So WITHOUT a detection gate, F2's null bail
; would fire only AFTER the outer diamond was already routed — a mutate-then-
; decline (Rule 9 violation). jvun gates BOTH conditions' predicates in
; `recoverRegionTree` (detection), so the out-of-scope inner condition declines
; BEFORE any emit. Over-declining is always safe (Prime Directive). After 8rvn
; (Phase 7.1 iw81.4 §4.4) broadened the fcmp set to the full ordered/unordered
; comparison family, `true`/`false` are the only out-of-set fcmp predicates left
; — so `false` is the standing residual for the inner condition here.
;
; ADVERSARIAL POSTCONDITION: loud decline AND no route (`cqrt_cswap`) nor bogus
; symbol emitted — proving the decline is pre-mutation.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control condition has no template under quantum control
; NEW: cq controlled lowering: control condition has no template under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control condition has no template under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cq_template_fcmp_false
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %a, double %b) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c1 = fcmp ogt double %q, 5.000000e+00   ; OUTER: in scope
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = fcmp false double %q, 9.000000e+00 ; INNER: OUT-OF-SCOPE (`false`, no template)
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call double @cq_measure_f64(double %q)
  ret double %m
}
