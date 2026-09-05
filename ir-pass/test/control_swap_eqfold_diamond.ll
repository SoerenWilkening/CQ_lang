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
;
; 3qlq(prep_a2): the FileCheck assertions below were RE-DERIVED from this
; fixture's own output under the Inc-1 (register-free `void @cq_phi(double)`)
; binary.  The pre-Inc-1 pin — a `cqrt_rz_<W>` or `cqrt_rz_<W>_controlled` on
; the user's REGISTER — asserted the gate PRD §1 shows is the identity on the
; marked branch (`cqrt_rz_<W>` is TENSORED, so a routed W-bit Rz applies
; `(-1)^popcount(target)` and can never mark |0..0>).  The stream now pinned is
; the KICKBACK: the flag is minted into a |0> ancilla, the phase lands on the
; FLAG with an UNCONTROLLED `cqrt_rz_i1`, the ordinary compare `_unc` returns
; the flag to |0> on every branch, and the flag is freed.  The fixture's
; PURPOSE (its header above) is unchanged.
;
; ORIGINAL negatives REMOVED.  Each was MEASURED to fire on this fixture's
; own Inc-1 output, so keeping it would assert something false.  A `-NOT`
; that used to sit AFTER a positive of its prefix was WINDOWED to the text
; past that positive; re-measuring it whole-file is a strictly stronger
; question, and where the pattern is one of the counted ones the
; `-COUNT-n` + `-NOT` pair below pins `exactly n` — stronger than the
; window it replaces, not weaker.
;   * call void @cqrt_free   [superseded by the FCNT count]
;   * call void @cqrt_free(   [superseded by the FCNT count]
;
; 20 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)  ; arg-0 CONST-FOLDED to 7
  call void @cq_phi(double %b)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; ===========================================================================
; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output
; (prep_a2, bd test_C_libtooling-3qlq Inc 1).  Every `%name` below is bound at
; its DEFINITION and referenced afterwards, so the chain asserts operand
; IDENTITY — the strip and the free name the SAME flag the mint produced
; (bd 8txa: the golden itself must witness the pairing).  Handle names are
; DERIVED, never typed (bd drbq Inc 4: 9 of 20 accepts named a %h1 the pass
; never emits).  Trailing `!cq.branchphase` metadata is stripped here because
; its NUMBER is LLVM's, not ours; its presence and count are MDCNT's job.
; CHECK: define i32 @example(i32 %u0, double %a, double %b) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %a)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %b)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M1]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
; NOROUTE-NOT: cqrt_copy
;   ^ method-B copy on a phase arm dephases the answer (Rule 7)
; NOROUTE-NOT: _controlled
;   ^ the kickback gate is UNCONTROLLED, on the flag ancilla
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
