; control_swap_reject_diamond_aliased_cond.ll — DECLINE (bd 7q3s), the `br`-path
; twin. Same aliased-operand compare, but as a CFG DIAMOND condition rather than a
; select condition, so it is proven by `ArmClassify`/`comparePredLowerable` and
; never passes through `collectCondTree` at all.
;
; WHICH FENCE ACTUALLY OWNS THIS DECLINE (corrected 2026-07-31 — an adversarial
; Rule-13 reviewer measured that the original header here was WRONG, and the
; correction is kept because a fixture that misattributes its own coverage is
; worse than no fixture): this input is NOT declined by the `comparePredLowerable`
; fence its first draft named. Measured with CQ_PREDMUX_DBG=1, it leaves at
; `gate=E6-condtree` — i.e. the decline is owned by the PredMux leaf fence
; (`isSupportedCompareLeaf`) plus the specialization path, and deleting the
; ArmClassify fence leaves this fixture's output BYTE-IDENTICAL. What it genuinely
; pins is that the aliased condition does not survive ANY route to a mint on this
; shape; it does not isolate one fence.
;
; A caveat that applies to all four SSA-form fixtures, measured in the same round:
; each fence deletion individually is a SEMANTIC NO-OP over the whole known input
; space (the routes overlap), so no single fixture can isolate one fence. They are
; kept as defense in depth and for POSTURE — the PredMux one moves the decline to
; claim time (detect-before-mutate, Rule 9) rather than after a flatten.
;
; The ArmClassify fence sits INSIDE `comparePredLowerable` rather than at its five
; call sites (classifyArms, classifyClassicalCallArm, recoverRegionTree,
; classifyAbortPark, GuardedStoreArmEmit) so that a new caller cannot forget it.
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
; CHECK: error{{.*}}under quantum
; CHECK-NOT: cq_template_fcmp_uno_f64
; CHECK-NOT: cqrt_cswap
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
