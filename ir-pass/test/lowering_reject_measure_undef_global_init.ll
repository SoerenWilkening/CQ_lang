; lowering_reject_measure_undef_global_init.ll — DECLINE: the RESIDUAL that the
; bd test_C_libtooling-fve8 retirement does NOT cover.
; bd test_C_libtooling-fve8, owner ruling 2026-09-15 (`DECISIONS.md` E2).
;
; ── WHY THIS FIXTURE EXISTS ──────────────────────────────────────────────────
; E2 retires clause 4 for a WHOLE-VALUE `undef`/`poison` operand: that spelling
; now measures the type's concrete zero
; (`lowering_accept_measure_undef_zero.ll`,
; `lowering_reject_measure_undef_operand.ll`). It was written down beforehand
; that the decline string would lose its last customer. IT DOES NOT, and this
; module is the customer — so the string is not left live with nothing to test
; (CLAUDE.md's fixture-hygiene defect (c): a decline fixture that goes green
; because its subject no longer exists pins NOTHING; the mirror of it is a
; STRING left in the source with no fixture at all).
;
; ── THE MECHANISM, IN ONE SENTENCE ───────────────────────────────────────────
; `valueCarriesUndef` is `carriesUndefImpl(C, Seen, /*SkipGlobals=*/false)`
; (`LiteralIntegrity.cpp`), so it walks INTO a referenced global's INITIALIZER.
; The operand here is a FULLY DEFINED value — the address of `@g`, truncated —
; and is NOT `isa<UndefValue>`; only `@g`'s SECOND FIELD, which this operand
; never reads, is `undef`. Rewriting it to zero would be a VALUE CHANGE, not a
; refinement, which is precisely why the retirement carries bd `z9t1`'s
; `isa<UndefValue>` conjunct verbatim in shape: the predicate gates a DECLINE
; everywhere else and a REWRITE only for the whole-value case.
;
; ⚠ ONE FUNCTION, DELIBERATELY. `LLVMContext::diagnose` EXITS on the first
; `DS_Error` (bd `br4a`), so a second function in this file would never be
; reported and would pin nothing (Rule 12 (c)). The in-tree "report and skip"
; comments are wrong.
;
; ── MUTATION VALIDATION (Rule 12: validate by MUTATION, not by re-reading the
; prefixes) ───────────────────────────────────────────────────────────────────
; Flip the initializer to `{ i32 1, i32 2 }` — nothing else — and this module
; ACCEPTS (`opt` exit 0, `ret i32 ptrtoint (ptr @g to i32)`). Measured on the
; session ORACLE as probe `e2l_global_initializer_defined.ll` and again on the
; subject; the two differ ONLY in a field the measured operand never reads, and
; that pair is what makes this fixture non-vacuous.
;
; ⚠ THE DECLINE IS FAITHFUL TO THE RULING, NOT NECESSARILY TO THE CIRCUIT. The
; operand is defined, so a classical measure of it is well-defined and this may
; itself be an OVER-DECLINE in the sense of the owner's 2026-09-11 ruling (an
; over-decline is a defect to remove, not a free safety margin). Removing it is
; a SEPARATE change — it would swap `valueCarriesUndef` for `slotCarriesUndef`
; at this site — and it was NOT taken here.
;
; ⚠ WHY NOT — RE-GROUNDED 2026-09-15 BY THE Rule-13 FIX ROUND (review item 3),
; WHICH AGREED WITH KEEPING THE DECLINE AND DISAGREED WITH THE REASON. The
; reason written here first was HYGIENIC ("the swap would leave the string with
; no customer at all"), and HYGIENE IS NOT A GROUND FOR KEEPING AN
; OVER-DECLINE: the correct response to "no customer" is to DELETE the string,
; which is what the trigger below already requires. The ground that survives is
; SEMANTIC: `slotCarriesUndef`'s `SkipGlobals=true` exists for EMITTED GATE
; SLOTS and its argument is about LITERAL INTEGRITY AT THE `-O0` STAGE-3 LINK
; (the same token must denote the same value at every slot the lowering copies
; it to), while a MEASUREMENT asks a different question — what value does this
; read report? — and nobody has ruled whether an initializer's `undef` field is
; reachable from it. Making the swap would be ADDING A CALLER TO A SHARED
; PREDICATE WITHOUT ASKING WHETHER THE CALLEE'S ARGUMENT REACHES IT (CLAUDE.md's
; mirror of L3, the P1 filing of 2026-09-14). So the swap needs an OWNER RULING
; on that semantics question, not developer discretion.
;
; RETIREMENT TRIGGER: if that swap is ever made, this fixture becomes an ACCEPT
; and `kMsgUndefOperand` must be deleted in the same change. Re-derive it then;
; do not delete it now.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=NOACCEPT
@g = global { i32, i32 } { i32 1, i32 undef }

declare i32 @cq_measure_si32(i32)

define i32 @gi() {
entry:
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr @g to i32))
  ret i32 %m
}

; CHECK: error{{.*}}cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value

; ⚠ Rule 12 (b): a `DS_Error` decline writes 0 bytes to stdout, so the property
; below is pinned by the `not` inversion on the RUN line, not by this text — the
; NOT lines exist so a binary that turns this into an ACCEPT fails on the `not`
; AND names what went wrong.
; NOACCEPT-NOT: cqrt_alloc
; NOACCEPT-NOT: cqrt_measure_
; NOACCEPT-NOT: ret i32 0
