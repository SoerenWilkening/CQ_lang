; control_swap_eqfold_diamond.ll — ACCEPT spec, equality-folded `br` diamond
; (4.5 WI-5; additive `tryEqFoldArm` D1–D7 clause).
;
; `if (q == 7) { rz(q, a); rz(q, b); }`. `clang -O1` KNOWS `q == 7` inside the
; arm, so it CONST-FOLDS the gate's arg-0 handle to the literal: the arm gate is
; `cq_phi(i32 7, θ)`, not `cq_phi(i32 %q, θ)`. `classifyArms`'s phase spine then
; bottoms at the `ConstantInt 7` instead of the routed handle, so the old
; classifier declined `control flow`. `tryEqFoldArm` re-recognizes it as a pure
; PHASE arm over the icmp's tainted operand (D1 equality predicate · D2 folded
; const base · D3 the icmp's non-const operand IS the routed handle · D4 literal
; == folded const · D5 routed operand tainted · D6 pure spine · D7 classical
; angles) and re-anchors the routed handle, so the diamond lowers through
; `emitRegion` VERBATIM (§4D): flag from the tainted `icmp eq`, CSWAP q into a
; |0> rail, the arm Rz gates VERBATIM/UNCONTROLLED on the rail (re-anchor BY
; PHYSICS — only arg-1/the angle is read, the folded arg-0 const is discarded),
; CSWAP back, free the |0> rail, strip the boolean with `icmp_eq_inv(q)` — ZERO
; controlled gates, NO surviving folded `cq_phi`, NO `phi i32`.
;
; ⚠ THE STEM ASYMMETRY — DO NOT "TIDY UP" THE Ry SIDE TO MATCH (bd
; test_C_libtooling-drbq Inc 4, PRD §14.2d). Since Inc 4 the SAME IR construct is
; read TWO WAYS by the two stems: `cq_phi_si32(i32 k, θ)` in an `if (q == k)` arm
; ACCEPTS here and re-anchors onto q's own rail, while `cq_theta_si32(i32 k, θ)`
; in that position DECLINES.
;
; ⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L7 finding F-L7-3). This
; block used to call `control_inplace_ry_reject_stateprep_eqfold_coincidence.ll`
; "this file with the stem changed" and to name F2 as the Ry side's fence. NEITHER
; IS TRUE, and both halves were MEASURED on HEAD:
;
;   * THIS FILE with `cq_phi` → `cq_theta` (and the second gate dropped, since its
;     arg-0 is the first gate's result) declines
;     `state prep merged with a quantum register` — i.e. at **F1**, not F2,
;     because THIS file's merge pred incoming is the live register `%q`.
;   * `..._eqfold_coincidence.ll` is a DIFFERENT module: its pred incoming is the
;     CONSTANT `5`, which is what lets it reach F2 at all.
;   * And the constant-incoming spelling has NO pair on this side: the Rz version
;     of `..._eqfold_coincidence.ll` (pred incoming `5`, arm `cq_phi(5, θ)`)
;     DECLINES `control flow` — `tryEqFoldArm` re-anchors `Routed` onto `%q` and
;     the constant pred incoming then does not match it. So "the same file with
;     the stem changed" describes no pair anywhere in the family.
;
; The honest pair is THIS file vs its own Ry twin, and the fences are F1 (Ry) vs
; `tryEqFoldArm`'s accept (Rz). The physics argument below is unaffected — it was
; always about the RE-ANCHOR, and the re-anchor is what differs.
;
; That is SOUND, and the reason is the stem's PHYSICS rather than a preference.
; The re-anchor puts a gate on the CONDITION'S OWN REGISTER. `cqrt_rz_<W>` is
; DIAGONAL, so the strip recomputes the predicate over a basis the arm did not
; move (§3 permits it explicitly; it is why S8 accepts). The same re-anchor for
; Ry would put a BASIS-RELABELLING gate there, which R4 forbids — the strip would
; be computed over a register the arm moved and the flag would not return to |0>.
; There is no correct re-anchor for that stem, so its only options were "accept as
; a fresh rail" (WRONG whenever the source meant `q`) or "decline".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan: two cqrt_free (work rail + flag), no third.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 7,   double %a)   ; arg-0 CONST-FOLDED to 7
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; br: mint the flag from the EQUALITY compare
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 7)
; arm body: one controlled Rz per gate, IN PLACE on q (§6a peephole, drbq Inc 2a).
;
; ⚠ AND THIS FIXTURE IS THE §5 RE-ANCHOR'S PIN, WHICH THE COLLAPSE PROMOTED FROM
; DECORATION TO LOAD-BEARING. `clang -O1` proved `q == 7` inside the arm and
; value-propagated it, so both `cq_phi` calls bottom at a folded `ConstantInt 7`
; at arg 0. The ROUTE read only arg 1 (the angle) and put the rotation on its own
; work rail, so it never noticed. Hoist-and-defer reads ARG 0: without
; `emitRegion`'s re-anchor of the first spine gate to the region's proven routed
; base, `lowerRotations` would see an UNTAINTED operand, emit NOTHING, and RAUW
; the gate to the constant — the arm's Rz silently DROPPED. That the two lines
; below name `%[[Q]]` and not a constant IS that fence firing.
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; strip the boolean: q==q0, so icmp_eq_inv(q) returns the flag to |0>; reclaim it
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; q (not the phi) is measured — RAUW merge-phi -> q
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free: the flag free is the LAST free — no second after it
; CHECK-NOT: call void @cqrt_free
; re-anchor: NO surviving const-folded cq_phi (it would RAUW to the const at
; RotationLowering -> a dropped rotation); zero copies / data mux
; CHECK-NOT: cq_phi
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag; there is no work rail any more), no second.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No swap route survives: no |0> work rail, no CSWAP — window is `define` -> EOF.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
