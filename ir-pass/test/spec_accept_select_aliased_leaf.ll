; spec_accept_select_aliased_leaf.ll — ACCEPT (bd big5, 2026-07-31), the PHASE-6
; CLONE twin of control_swap_accept_select_aliased_leaf.ll. Same aliased-operand
; compare (`fcmp uno double %x, %x`), but inside a classical callee the specializer
; LIFTS, so it reaches `Specialization.cpp`'s `lowerCloneSelect`/`mintCondNetwork`
; rather than the top-level 4.4 emitter.
;
; It was a DECLINE fixture for one day (bd 7q3s / dd2c103); the fence rested on a
; false realizability premise and was reverted. See
; control_swap_accept_select_rail_alias_cond.ll for the full CASE A / CASE B
; argument. DO NOT RE-ADD THE FENCE.
;
; THIS FIXTURE'S JOB IS THE SHARED-WALK PROOF, and it survives the direction flip
; unchanged: the two paths mint through DIFFERENT code (`mintCondNetwork` does not
; call `compareFlagMintable`) but SHARE `collectCondTree`. Before, that meant one
; fence covered both; now it means one ACCEPT covers both. Either way, a future
; refactor that changes only the top-level path and leaves the clone path behind is
; exactly what this fixture plus its top-level twin catch (Rule 14).
;
; NOTE THE FULL LIFT HAPPENS: the callee is specialized and its body lowered
; (`sitofp` → `fcmp uno` → the controlled-copy merge → `fptosi`), with the aliased
; leaf riding through as an ordinary Case-A mint. A clone body is rotation-free
; (`scanBody` rejects `cq_phi`), so here the alias is the SSA-identical kind and
; `%h_cast` reaches both compare slots as one rail.
;
; MEASURED FENCE COVERAGE (one fence re-added at a time): broken by the
; ArmClassify fence and by the SelectClassify fence, NOT by the PredMux one. Full
; matrix in control_swap_accept_select_rail_alias_cond.ll.
;
; bd p3kd.7.8: `lowerCloneSelect`/`mintCondNetwork` are gone; the clone's select
; is lowered by MAIN's 4.4 path, so the clone and its top-level twin now run the
; SAME detection and emission code, not merely the same `collectCondTree` walk.
; This fixture now pins that the LIFTED route reaches that accept (the clone is
; built and its body lowered, CASE A aliasing intact). The 0.0 arm is
; materialized as its own `cqrt_alloc_f64(0.0)` rail (no one-copy fast path), and
; main's inline strip is elided by the Bennett wrap, whose reverse is the EXACT
; mirror. Trace on |n>: x = (double)n; f = isnan(x)∨isnan(x) (both slots read the
; one rail x); out gets 0.0 under f, then (f flipped) x under ¬f; r = fptosi(out).
; The mirror zeroes r, un-copies x, re-flips f, un-copies 0.0 (out -> |0>), then
; the fcmp/sitofp `_unc`s zero f and x. The 0.0 rail is only read, so it is |0>
; and freed with x, f, out and r. The NOCASEB patterns are now generic (FileCheck
; back-references) instead of naming `%h_cast`/`%h_cmp`/`%cqq.sel`; the old third
; pattern named the retired `%cqq.sel` rail and had become vacuous.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCASEB < %t.cqd0.ll
;
; CASE A, pinned — aliased READ slots, FRESH out rail. The CHECK-NEXT chain covers
; the whole clone body.
; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_uno_f64(i32 %[[X]], i32 %[[X]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[Z]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[OUT]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[OUT]])
; The Bennett copy-out and the exact mirror:
; CHECK-NEXT: %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[RES]])
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[R]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[Z]], i32 %[[OUT]])
; The LIFO strip of the aliased flag, then its free at a proven |0> (Rule 6):
; CHECK-NEXT: call void @cq_template_fcmp_uno_f64_unc(i32 %[[F]], i32 %[[X]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[X]], i32 %n)
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[Z]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[RES]]
; CHECK-NEXT: }
;
; CASE B must never appear — an input aliasing the rail the gate WRITES (or, for
; the copy, its control). Under a *-NOT-only prefix so they scan the WHOLE input
; (a trailing plain CHECK-NOT scans only from the last CHECK match to EOF and was
; DEAD over the body — measured 2026-07-31 by injection). Each pattern binds its
; own back-reference, so it matches any SSA name.
; NOCASEB-NOT: @cq_template_fcmp_uno_f64_unc(i32 %[[NB1:[a-zA-Z0-9_.]+]], i32 %[[NB1]],
; NOCASEB-NOT: @cq_template_fcmp_uno_f64_unc(i32 %[[NB2:[a-zA-Z0-9_.]+]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[NB2]])
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %[[NB3:[a-zA-Z0-9_.]+]], i32 %[[NB3]],
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %[[NB4:[a-zA-Z0-9_.]+]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[NB4]])
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[NB5:[a-zA-Z0-9_.]+]], i32 %[[NB5]])
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x = sitofp i32 %n to double
  %c = fcmp uno double %x, %x          ; ALIASED operands — one rail, two slots
  %a = select i1 %c, double 0.000000e+00, double %x
  %r = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
