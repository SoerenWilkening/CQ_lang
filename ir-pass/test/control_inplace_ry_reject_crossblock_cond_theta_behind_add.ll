; control_inplace_ry_reject_crossblock_cond_theta_behind_add.ll — DECLINE, and it is
; the ONE fixture that individually pins `crossBlockCompareMintable`'s GAP SCAN (bd
; `test_C_libtooling-drbq.12`, self-adversarial round 1, 2026-09-17). Everything else
; the round could construct turned out to be caught by some OTHER owner, and that
; measurement is recorded here because it is the interesting part.
;
; THE SHAPE. Two sequential regions over ONE CSE'd compare `%3 = icmp eq i32 %1, 5`
; in the entry block — the acyclic customer of this bead — plus:
;
;     %d    = add nsw i32 %1, 3                       ; an M-C in-place CANDIDATE
;     %post = cq_theta(%d, 0.1)   in the SHARED MERGE ; a chained Ry, in region 2's gap
;
; ⚠ WHY NOTHING ELSE SEES IT. `WireWalk`'s forward walk DELIBERATELY does not cross
; an in-place self-update (`WireWalk.cpp`, a measured decision), so from the seed
; `%1` it never reaches `%d` and therefore never reaches `%post`:
; `wireGainsNonDiagonalGate` returns nothing. And `%post` executes AT MOST ONCE (no
; back edge), so the bd `3d8q` stale-reader fence has no subject either. The only
; reach that sees `%post` is `railWireClosure`, which DOES cross `add`/`sub`/`xor` —
; and `condRailMembers` is its only caller on this path.
;
; ⚠ VALIDATED BY BINARY MUTATION, NOT BY RE-READING THE PREFIXES (Rule 12(c)).
; MEASURED on three binaries:
;   ORACLE `9bd01598…`                     DECLINE (P4's unconditional cross-block bail)
;   SUBJECT `5ee9d144…`                    DECLINE (this fixture's string)
;   SUBJECT with the gap scan DELETED      **ACCEPT, exit 0**
; The third row is what makes the pin real. Its three siblings —
; `trackD2/probes/{r1a_alias,r1b_behind_add}.ll` and the in-gap wire-gate negative —
; all still DECLINE under that same mutant, caught by the wire walk or by `3d8q`.
;
; ⚠ AND THE DECLINE IS CONSERVATIVE, NOT EXACT — SAY IT PLAINLY. Under the mutant the
; emitted add is `cq_template_add_i32_hl`, i.e. OUT of place on a FRESH rail, so
; `%post` does not in fact relabel `%1` and the accept would have been sound. This
; file therefore records a genuine over-decline of the R4 SPECIES:
; `railWireClosure`'s own header calls the `add`/`sub`/`xor` hop "the reason the
; closure is CONSERVATIVE rather than exact … Both roots are therefore admitted",
; because `lowerOps` decides in-place-vs-out long after detection.
;
; ⚠ THE ASYMMETRY WITH THE dtzb DECISION IS DELIBERATE AND IS THE POINT. This bead
; REFUSED to treat a bare `add` as EVIDENCE (measured pure over-decline; see
; `control_inplace_ry_crossblock_cond_outofplace_add_in_gap.ll` and
; `railRelabellingGateOn`'s header) while KEEPING the add hop in the MEMBERS closure.
; Those are two different questions — "does this instruction relabel?" versus "may
; this name denote the condition's rail?" — and the conservative answer to each is a
; different direction. Refusing the gate would decline programs whose add provably
; cannot be in place; refusing to assume the add is NOT an alias costs this one file.
;
; RESIDUAL, FILED NOT HIDDEN: removing this over-decline needs M-C's answer at
; DETECTION time, and `classifyInPlaceReassignment` cannot be asked there (its verdict
; is taken at FINAL taint over a FINAL CFG, so a `false` at round 1 could become
; `true` later — a decline traded for an OVER-ACCEPT). bd text is in
; `trackD2/IMPL_D2b.md` §bd.
;
; RETIREMENT TRIGGER (L8): if `condRailMembers` ever stops crossing the
; `add`/`sub`/`xor` hop — or if M-C becomes answerable at detection — this file's
; verdict flips and the header above is the re-derivation to redo.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so IR-text negatives here would be
; VACUOUS (Rule 12(b)): the property is pinned by the `not` inversion on the RUN line
; and by the string above. None is written, deliberately.

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %d = add nsw i32 %1, 3
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %post = tail call i32 @cq_theta_si32(i32 noundef %d, double noundef 1.000000e-01) #2
  br i1 %3, label %8, label %10

8:                                                ; preds = %6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %6
  %11 = phi i32 [ %9, %8 ], [ %7, %6 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %post) #2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }
