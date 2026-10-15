; control_swap_accept_select_aliased_leaf.ll — ACCEPT (bd big5, 2026-07-31). The
; SSA-IDENTICAL spelling of the aliased condition compare: a TOP-LEVEL 4.4
; tainted-condition select whose condition has the SAME SSA value in both operands
; (`fcmp uno double %q, %q` — the hand-written NaN test). The RAIL-aliased
; spelling, which is the one reachable from real C, is
; control_swap_accept_select_rail_alias_cond.ll — read that fixture's header for
; the full CASE A / CASE B argument; this one is its degenerate twin.
;
; It was a DECLINE fixture for one day (bd 7q3s / dd2c103) on the premise that
; `cq_template_fcmp_uno_f64(i32 %h, i32 %h)` is "an ill-formed physical gate no
; backend can realize". THE PREMISE IS FALSE (owner ruling 2026-07-31). Aliasing
; the INPUTS of an out-of-place gate whose OUTPUT is a fresh |0> rail simply makes
; it a UNARY function of the shared operand — and here that function is a
; perfectly ordinary one: `fcmp uno(a,a)` IS `isnan(a)`. There is nothing to
; realize beyond a 1-register isnan predicate, which is strictly CHEAPER than the
; 2-register comparator, not impossible. DO NOT RE-ADD THE FENCE.
;
; This fixture is kept (rather than deleted with the fence) because it pins the
; SHARED walk: `collectCondTree` (SelectClassify.cpp) serves BOTH the top-level 4.4
; select detect+emit AND the Phase-6 clone select. Its clone twin is
; spec_accept_select_aliased_leaf.ll; if one path ever re-grows a fence the other
; will not, and these two fixtures are what catches that drift (Rule 14).
;
; MEASURED FENCE COVERAGE (one fence re-added at a time, isolated plugin builds):
; this fixture is broken by the ArmClassify fence and by the SelectClassify fence,
; but NOT by the PredMux one. The full matrix is in
; control_swap_accept_select_rail_alias_cond.ll — do not infer coverage from the
; diagnostic string, which named the wrong owner in the pre-revert drafts.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCASEB < %t.cqd0.ll
;
; CASE A, pinned verbatim — the aliasing is confined to the READ slots of a gate
; whose OUT rail (%h_cmp) is freshly minted by `lowerCompareToFlag`. Arm polarity
; is pinned by the CONSTANT on the true arm (0.0) and the rail on the false arm:
; CHECK: %h = call i32 @cqrt_alloc_f64(double %u0)
; CHECK: call void @cqrt_ry_f64(i32 %h, double 5.000000e-01)
; CHECK: %h_cmp = call i32 @cq_template_fcmp_uno_f64(i32 %h, i32 %h)
; CHECK: %out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h, i32 %out)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cq_template_fcmp_uno_f64_unc(i32 %h_cmp, i32 %h, i32 %h)
; CHECK: call void @cqrt_free(i32 %h_cmp)
;
; CASE B must never appear — an input aliasing the rail the gate WRITES. Under a
; *-NOT-only prefix so they scan the WHOLE input: a trailing plain CHECK-NOT scans
; only from the last CHECK match to EOF and was DEAD over the function body
; (measured by injection, 2026-07-31).
; NOCASEB-NOT: @cq_template_fcmp_uno_f64_unc(i32 %h, i32 %h
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %out, i32 %out)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp uno double %q, %q          ; ALIASED operands — one rail, two slots
  %a = select i1 %c, double 0.000000e+00, double %q
  %m = call double @cq_measure_f64(double %a)
  ret double %m
}
