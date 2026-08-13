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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCASEB < %t.cqd0.ll
;
; CASE A, pinned — aliased READ slots, FRESH out rail:
; CHECK: %h_cast = call i32 @cq_template_sitofp_i32_to_f64(i32 %{{[a-z0-9]+}})
; CHECK: %h_cmp = call i32 @cq_template_fcmp_uno_f64(i32 %h_cast, i32 %h_cast)
; CHECK: call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %{{[a-z0-9.]+}}, i32 %cqq.sel)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_cast, i32 %cqq.sel)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; The LIFO strip of the aliased flag, then its free at a proven |0> (Rule 6):
; CHECK: call void @cq_template_fcmp_uno_f64_unc(i32 %h_cmp, i32 %h_cast, i32 %h_cast)
; CHECK: call void @cqrt_free(i32 %h_cmp)
;
; CASE B must never appear — an input aliasing the rail the gate WRITES. Under a
; *-NOT-only prefix so they scan the WHOLE input (a trailing plain CHECK-NOT scans
; only from the last CHECK match to EOF and was DEAD over the body — measured
; 2026-07-31 by injection).
; NOCASEB-NOT: @cq_template_fcmp_uno_f64_unc(i32 %h_cast, i32 %h_cast
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %cqq.sel, i32 %cqq.sel)
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
