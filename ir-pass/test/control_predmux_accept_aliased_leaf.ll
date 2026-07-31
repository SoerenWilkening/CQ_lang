; control_predmux_accept_aliased_leaf.ll — ACCEPT (bd big5, 2026-07-31), the
; PREDMUX route. Pinned separately because PredMux has its OWN condition walk
; (`isSupportedCondTree` / `isBooleanCondTree` → `isSupportedCompareLeaf`,
; PredMuxFlatten.cpp), which does not go through `collectCondTree` or
; `comparePredLowerable` at CLAIM time.
;
; MEASURED FENCE COVERAGE (one fence re-added at a time, isolated plugin builds):
; this is the ONLY fixture of the five broken by ALL THREE fences individually, so
; it is the strongest single pin on the revert — but for that same reason it does
; NOT isolate the PredMux site, and an earlier draft's claim that "a fence added to
; the other two sites would leave this one uncovered, and vice versa" is FALSE.
; Full matrix in control_swap_accept_select_rail_alias_cond.ll. (Its pre-revert
; decline was ArmClassify's `control condition has no template`, NOT the PredMux
; leaf fence its first header named — a diagnostic string does not identify which
; fence owns a decline.)
;
; SHAPE: the W7 const-fallthrough integer sole-phi diamond (a `br`-rooted flat
; region whose merge holds exactly one 2-incoming muxable integer phi with a
; ConstantInt on the entry edge) — with an ALIASED condition compare.
;
; It was a DECLINE fixture for one day (bd 7q3s / dd2c103). See
; control_swap_accept_select_rail_alias_cond.ll for the full CASE A / CASE B
; argument. DO NOT RE-ADD THE FENCE — `isSupportedCompareLeaf` carries a
; DO-NOT-RE-ADD comment for exactly this reason.
;
; ONE MEASUREMENT TRAP THIS FIXTURE RECORDS: THE EMITTED PREDICATE IS `ne`, NOT
; THE SOURCE `eq`, so a probe that greps for the SOURCE predicate misses this
; entirely (the first probe written for it did). ATTRIBUTE IT CORRECTLY, though —
; the pre-revert header blamed clang -O1, and THIS FIXTURE IS HAND-WRITTEN .ll RUN
; STRAIGHT THROUGH `opt`, so clang never executes on it. The inversion is PredMux's
; own edge-predicate algebra: the entry→merge edge predicate is the NEGATION of the
; branch condition, and the phi's entry incoming (0) is the value copied under it.
; The Rule-9 branch-polarity warning is real too, but it is a separate fact about
; the `.c` ship floor; do not conflate the two stages.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=NOCASEB
;
; CASE A, pinned — note the inverted predicate:
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK: %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 7)
; CHECK: %h_cmp = call i32 @cq_template_icmp_ne_i32(i32 %h, i32 %h)
; CHECK: %out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %{{[a-z0-9]+}}, i32 %out)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cq_template_icmp_ne_i32_unc(i32 %h_cmp, i32 %h, i32 %h)
; CHECK: call void @cqrt_free(i32 %h_cmp)
;
; CASE B must never appear — an input aliasing the rail the gate WRITES. Under a
; *-NOT-only prefix so they scan the WHOLE input (as trailing plain CHECK-NOTs
; they were DEAD over the function body — measured 2026-07-31 by injection).
; NOCASEB-NOT: @cq_template_icmp_ne_i32_unc(i32 %h, i32 %h
; NOCASEB-NOT: @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_cmp
; NOCASEB-NOT: @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %out, i32 %out)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, %q                 ; ALIASED operands — one rail, two slots
  br i1 %c, label %arm, label %merge
arm:
  %z = add i32 %q, 7
  br label %merge
merge:
  %p = phi i32 [ 0, %entry ], [ %z, %arm ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret void
}
