; control_swap_reject_select_aliased_leaf.ll — DECLINE (bd 7q3s). A TOP-LEVEL 4.4
; tainted-condition select whose condition compare has the SAME SSA value in both
; operands (`fcmp uno double %q, %q` — the hand-written NaN test).
;
; THE HAZARD: with %q tainted this is a Q+Q leaf, so the mint would be a
; TWO-REGISTER reversible comparator with ONE rail in both operand slots
; (`cq_template_fcmp_uno_f64(i32 %h, i32 %h)` plus its `_unc`). That is
; value-correct in trace semantics yet an ILL-FORMED PHYSICAL GATE no backend can
; realize — and it lowers at exit 0, so it would be frozen into a golden. It is
; exactly the hazard `collectCondTree`'s NODE fence already declines for
; `or/and i1 %c, %c`; the LEAF axis simply never got the same fence.
;
; WHY DECLINING IS THE FIX AND NOT A PUNT (Rule 17): the shape is NON-CANONICAL.
; MEASURED 2026-07-30 — 0 aliased compares across all 934 ir-pass fixtures, and
; tests/e2e/slice_libm_real_modff.c:56, which literally contains the `x != x`
; isnan idiom, compiles at -O1 to `fcmp uno float %1, 0.0` (InstCombine
; canonicalizes a self-compare into a Q+C form). No -O1 C program reaches THIS
; SPELLING of the hazard — but see the scope note below: the RAIL-aliased spelling
; very much is reachable, which is why the fence does not test SSA identity. A
; 1-register aliased-compare predicate would be a separate feature, not this fence.
;
; The fence lives in `collectCondTree` (SelectClassify.cpp), the SHARED walk, so
; this one predicate covers the top-level select detect+emit AND the Phase-6 clone
; select — they cannot drift apart (Rule 14).
;
;
; SCOPE OF THIS FIXTURE (corrected 2026-07-31 by a Rule-13 finding): it pins the
; SSA-IDENTICAL form only. The claim an earlier draft carried — "no -O1 C program
; reaches this" — is TRUE of this form and FALSE of the hazard in general: a
; cq_phi (Rz) result RAUWs to its argument's rail, so SSA-DISTINCT operands can
; still be ONE RAIL, and that IS reachable from four lines of plain C. The fence
; therefore tests RAIL identity via `operandsAlias`, and the rail form is pinned
; separately by control_swap_reject_select_rail_alias_cond.ll. Do not re-derive
; the zero-blast-radius argument from a corpus scan: a scan for the SSA form
; cannot see the rail form.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cq_template_fcmp_uno_f64
; CHECK-NOT: cqrt_copy_f64_controlled
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp uno double %q, %q          ; ALIASED operands — one rail, two slots
  %a = select i1 %c, double 0.000000e+00, double %q
  %m = call double @cq_measure_f64(double %a)
  ret double %m
}
