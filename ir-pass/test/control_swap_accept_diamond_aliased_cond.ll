; control_swap_accept_diamond_aliased_cond.ll — ACCEPT (bd big5, 2026-07-31). The
; same aliased-operand compare as control_swap_accept_select_aliased_leaf.ll, but
; written as a CFG DIAMOND condition inside a liftable callee rather than as a
; select condition, so it enters through `ArmClassify`/`comparePredLowerable` and
; the PredMux condition walk rather than through `collectCondTree` directly.
;
; It was a DECLINE fixture for one day (bd 7q3s / dd2c103). See
; control_swap_accept_select_rail_alias_cond.ll for the full CASE A / CASE B
; argument and why the fence was reverted. DO NOT RE-ADD IT — at ANY of the three
; sites the fence occupied (`collectCondTree` leaf, `comparePredLowerable`,
; `isSupportedCompareLeaf`), each of which now carries a DO-NOT-RE-ADD comment.
;
; WHAT THIS FIXTURE IS FOR, and it is why it survived the direction flip: it is
; the only one that exercises the aliased compare through the `br` DIAMOND route
; end-to-end — PredMux flattens the diamond into a select, which is then merged.
;
; MEASURED FENCE COVERAGE (one fence re-added at a time, isolated plugin builds —
; the earlier draft of this header GUESSED and got it wrong twice, so measure):
; this fixture is broken by the PredMux fence and by the SelectClassify fence, but
; it still PASSES with only the ArmClassify fence re-added. So it crosses TWO of
; the three sites, not three: `flattenPredMuxRegions` runs at
; CQLoweringPass.cpp:178, BEFORE `detectControlRegions` at :275, so once the
; PredMux fence is gone the diamond is already flattened and
; `comparePredLowerable` is never reached on this input at all. Full matrix in
; control_swap_accept_select_rail_alias_cond.ll. Note also that this input's
; pre-revert decline was the SPECIALIZATION diagnostic, not a control one — a
; diagnostic string does NOT identify which fence owns a decline.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCASEB < %t.cqd0.ll
;
; bd p3kd.7.8: the clone is now lowered by MAIN's stage list, so the flattened
; select goes through main's 4.4 path (SelectMergeEmit), not the removed
; `lowerCloneSelect`: the merge rail is `%out` (was `%cqq.sel`), the constant 0.0
; arm is materialized as a |0> rail, the forward's trailing `cqrt_x` strip is elided
; by the Bennett wrap, and the reverse is the exact mirror. The aliased-slot
; property is unchanged: `fcmp uno` reads %h_cast in BOTH slots and writes the
; FRESH %h_cmp (CASE A), and %h_cmp is only ever a control, never a written rail.
; Hand trace, |n>: h_cast=(double)n, h_cmp=c=isnan; copy_c(c,0.0) then
; copy_c(!c,h_cast) leaves out = c ? 0.0 : x, the phi; fptosi to the result,
; copy-out; the mirror undoes fptosi, both copies (flag back to c), the fcmp and
; the sitofp, so every freed rail is |0> (the 0.0 rail is all-zero bits).
;
; The diamond is flattened and the aliased leaf mints CASE A — aliased READ slots,
; FRESH out rail (%h_cmp). The rail names are pinned literally (not FileCheck
; variables) because the NOCASEB prefix below is *-NOT-only and cannot bind a
; variable: the literal positives keep those NOTs anchored to real names.
; CHECK-LABEL: define void @example(
; CHECK:       call i32 @__cq_q_mhelper_1(i32 %
; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %h_cast = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; CHECK-NEXT:  %h_cmp = call i32 @cq_template_fcmp_uno_f64(i32 %h_cast, i32 %h_cast)
; CHECK-NEXT:  %out = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; (bd dm7f.81: the constant +0.0 arm emits no write; the clone's former %K0
; source rail and its free are gone.)
; CHECK-NEXT:  call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_cast, i32 %out)
; CHECK-NEXT:  %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %out)
; CHECK-NEXT:  %[[CO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[R]], i32 %[[CO]])
; CHECK-NEXT:  call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[R]], i32 %out)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_cast, i32 %out)
; CHECK-NEXT:  call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT:  call void @cq_template_fcmp_uno_f64_unc(i32 %h_cmp, i32 %h_cast, i32 %h_cast)
; CHECK-NEXT:  call void @cq_template_sitofp_i32_to_f64_unc(i32 %h_cast, i32 %n)
; CHECK-NEXT:  call void @cqrt_free(i32 %h_cast)
; CHECK-NEXT:  call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT:  call void @cqrt_free(i32 %out)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT:  ret i32 %[[CO]]
; CHECK-NEXT:  }
;
; CASE B must never appear — an input aliasing the rail the gate WRITES (a
; controlled copy or cswap whose control is also a written rail cannot be
; realized); this path emits no cswap at all. Under a *-NOT-only prefix so they
; scan the WHOLE input (as trailing plain CHECK-NOTs they were DEAD over the
; function body — measured 2026-07-31 by injection).
; NOCASEB-NOT: @cq_template_fcmp_uno_f64_unc(i32 %h_cast, i32 %h_cast
; NOCASEB-NOT: @cqrt_cswap(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %{{[a-zA-Z0-9_.]+}}, i32 %h_cmp)
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %out, i32 %out)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
entry:
  %x = sitofp i32 %n to double
  %c = fcmp uno double %x, %x          ; ALIASED operands — one rail, two slots
  br i1 %c, label %nan, label %merge
nan:
  br label %merge
merge:
  %a = phi double [ 0.000000e+00, %nan ], [ %x, %entry ]
  %r = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
