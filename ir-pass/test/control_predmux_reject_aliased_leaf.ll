; control_predmux_reject_aliased_leaf.ll — DECLINE (bd 7q3s), the PREDMUX route.
; The FOURTH distinct path to the aliased-compare hazard, and the one an
; adversarial self-check found AFTER the first three were fenced — it is pinned
; separately because PredMux has its OWN condition walk
; (`isSupportedCondTree` / `isBooleanCondTree`, PredMuxFlatten.cpp), which does
; not go through `collectCondTree` or `comparePredLowerable` at claim time.
;
; SHAPE: the W7 const-fallthrough integer sole-phi diamond (a br-rooted flat
; region whose merge holds exactly one 2-incoming muxable integer phi with a
; ConstantInt on the entry edge) — but with an ALIASED condition compare.
;
; WHAT IT WOULD HAVE EMITTED. Measured on the pre-fence plugin, which lowered this
; at EXIT 0:
;     %h_cmp = call i32 @cq_template_icmp_ne_i32(i32 %h, i32 %h)
;     call void @cq_template_icmp_ne_i32_unc(i32 %h_cmp, i32 %h, i32 %h)
; one rail in BOTH operand slots of a two-register reversible comparator, frozen
; into a golden. NOTE THE PREDICATE IS `ne`, NOT the source `eq` — clang -O1
; branch-polarity inversion (Rule 9). A probe that greps for the SOURCE predicate
; misses this entirely; the first probe written for it did.
;
; POSTURE, which is why the fence is in `isSupportedCompareLeaf` rather than left
; to the downstream select: without a claim-time fence PredMux would CLAIM the
; region and FLATTEN it, and only the resulting select would decline at
; `collectCondTree` — a claim-then-decline (Rule 9 detect-before-mutate; the bd
; tzfg class). With the fence the region is declined at the E6 condition-tree gate
; before any mutation, which `CQ_PREDMUX_DBG` reports as
; `leave ... gate=E6-condtree`.
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
; CHECK: error{{.*}}under quantum control
; The hazard is the point: NO two-register comparator with one rail in both slots.
; CHECK-NOT: cq_template_icmp_{{[a-z]+}}_i32(i32 %h, i32 %h)
; CHECK-NOT: cqrt_copy_i32_controlled
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
