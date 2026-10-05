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
; The diamond is flattened and the aliased leaf mints CASE A — aliased READ slots,
; FRESH out rail (%h_cmp):
; CHECK: %h_cast = call i32 @cq_template_sitofp_i32_to_f64(i32 %{{[a-z0-9]+}})
; CHECK: %h_cmp = call i32 @cq_template_fcmp_uno_f64(i32 %h_cast, i32 %h_cast)
; CHECK: call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %{{[a-z0-9.]+}}, i32 %cqq.sel)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_cast, i32 %cqq.sel)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cq_template_fcmp_uno_f64_unc(i32 %h_cmp, i32 %h_cast, i32 %h_cast)
; CHECK: call void @cqrt_free(i32 %h_cmp)
;
; CASE B must never appear — an input aliasing the rail the gate WRITES (a
; controlled copy or cswap whose control is also a written rail cannot be
; realized); this path emits no cswap at all. Under a *-NOT-only prefix so they
; scan the WHOLE input (as trailing plain CHECK-NOTs they were DEAD over the
; function body — measured 2026-07-31 by injection).
; NOCASEB-NOT: @cq_template_fcmp_uno_f64_unc(i32 %h_cast, i32 %h_cast
; NOCASEB-NOT: @cqrt_cswap(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_f64_controlled(i32 %h_cmp, i32 %cqq.sel, i32 %cqq.sel)
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
