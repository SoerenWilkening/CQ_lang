# prep_a2 — Inc 1 prep (a2): re-derive the migrated fixtures' CHECKs on the Inc-1 binary
Worktree $SP/wt/prep-a, branch `3qlq-inc1-migration` (rebased onto c4bd888).
SUBJECT = $SP/wt/prep-a/build/ir-pass/cq-opt   ORACLE = $SP/wt/pre-3qlq/build/ir-pass/cq-opt

## 2026-09-05 step 0 — resumed after the rate-limit kill; BUILD IS FRESH, no rebuild needed
    tail $SP/progress/prep_a2_build.log            -> "[100%] Built target cq-opt" / "EXIT=0"
    ls -la build/ir-pass/cq-opt                    -> 16:56  (sources newest 16:51) => NOT stale
    ls -la build/ir-pass/libCQPass.so              -> 16:54
    git log --oneline -1                           -> 85ec83a wip(3qlq): --limits no longer requires a mode flag
    git status --short                             -> clean
  Read: BRIEF_common, BRIEF_prep_a2_rederive (incl. "Added after round 1"), BRIEF_prep_a_migration,
  prep_a.md, MIGRATION_REPORT.md (354 lines), OWNER_QUESTIONS.md (OQ-6/9/10).
Next: step 1 — lit over the whole corpus with the SUBJECT, partition the reds.

## 2026-09-05 step 1 — lit on the SUBJECT, RED PARTITION: **(iii) OTHER IS EMPTY**
    cd $SP/wt/prep-a/build && lit -q ir-pass/test        (log prep_a2_lit1.log, exit 1)
    -> "Total Discovered Tests: 1661",  "Failed: 201 (12.10%)"
  Partition computed as a SET DIFFERENCE (not by eye), sets in $SP/progress/prep_a2_work/:
    red.txt                            201
    set_migrated.txt  (git diff --name-only 7f1d834~2 7f1d834 -- ir-pass/test)   413
    set_retired_live.txt (sed 's/;.*//' | grep -qE '@cq_phi_[a-z0-9]+')           79
    comm -23 red (set_migrated ∪ set_retired)                                      **0**
  => **NO IMPLEMENTER REGRESSION.** Every red is inside the migration population.
  Refined:
    reds in the LIVE-retired-family (hand-decision) set        76      (of 79)
    reds in the MIGRATED set                                  125
    overlap                                                     0
    migrated reds OUTSIDE A/S/MIX (i.e. class U or D)           0      <- U+D are GREEN on the subject
  The 3 GREEN live-retired files are the IMPLEMENTER's OWN new fixtures that pin the
  reserved-name decline and MUST keep the old spelling:
    lowering_legacy_phi_decl_prototype_family.ll
    lowering_reject_legacy_phi_register_form{,_eqfold}.ll
  Two more files matched the retired family only INSIDE A `;` COMMENT (both green, both
  correct): control_predmux_reject_selectform_rotation_hop_chained.ll (prep_a BUG 8) and
  lowering_reject_decl_prototype_phi.ll (rewritten by impl_inc1a).
  => my hand-decision set is **76**, not 77: prep_a's 77th
  (`lowering_reject_decl_prototype_phi.ll`) was already rewritten by the implementer.

  Authoritative class table re-measured by running the tool on the REBASED pre-migration
  tree (git archive c9a9811~1 -> $W/orig, `--report`):
    {'A':198,'D':95,'H':24,'M':121,'MIX':26,'S':13,'U':136,'X':6}   (X = 6 NEW implementer
    fixtures the textual parser cannot parse; all 6 are green and not mine)
    A/S/MIX = 237, minus `lowering_reject_legacy_phi_register_form_eqfold.ll` (a NEW
    implementer fixture, class A) = **236**, exactly prep_a's figure.
    Of those 236: **212 were migrated** (carry a live `call void @cq_phi(`) and **24 are the
    undissolvable-merge-phi hand decisions** (inside the 76).
  A/S/MIX migrated 212 = **125 red + 87 GREEN**. The 87 greens are prep_a's F4 class
  (GREEN IS NOT EVIDENCE — the CHECKs were never re-derived) and are re-derived too.
  WORK POPULATION = 212 (A/S/MIX re-derive) + 76 (hand decisions) = **288 files**.
Next: step 2 — sweep the SUBJECT over all 288 to get exit code + diagnostic per file.

## 2026-09-05 step 2 — SUBJECT sweep over the 288-file work population (MEASURED)
    $W/sweep.py (one cq-opt run per file, exit code + first `error` line + `RUN: not` presence)
    -> done 288
  A/S/MIX (212):
      pins ACCEPT  & subject ACCEPTS   104   (96 red + 8 green)  -> RE-DERIVE the stream
      pins DECLINE & subject DECLINES   95   (16 red + 79 green) -> RE-SPELL the diagnostic
      pins DECLINE & subject ACCEPTS    13   -> **DISPOSITION FLIP toward ACCEPT** (stay RED)
  HAND (76):
      pins DECLINE & subject DECLINES   75
      pins ACCEPT  & subject DECLINES    1
      ALL 76 decline with ONE string, and it is the round-1 F-L6-1 reserved-name rule:
        56 `cq rotation lowering: retired register-form cq_phi_si32; use the register-free void cq_phi(double)`
        20 ... `cq_phi_f64` ...
      i.e. the hand set is red for the SAME reason in every file — the old spelling is
      now a hard decline — so each of the 76 needs a real disposition, not a re-spell.
Next: step 3 — the re-derive tool + the 104 accepts.

## 2026-09-05 step 3 — `tools/migrate_phi_fixtures_rederive.py` (companion to prep_a's tool)
  Design (each rule is a recorded defect, not a style choice):
   * handle names DERIVED: every SSA name defined in the output is BOUND as a FileCheck
     variable at its definition and REFERENCED after, so the chain asserts operand
     IDENTITY (the strip/free name the same flag the mint produced, bd 8txa). Function
     ARGUMENTS keep their literal spelling. bd drbq Inc 4: 9 of 20 accepts named a `%h1`
     the pass never emits.
   * `CHECK-NEXT` ONLY where the two lines are literally consecutive in the output
     (a blank line between blocks breaks the chain into a fresh `CHECK`) — otherwise the
     chain asserts adjacency the output does not have.
   * NOROUTE is WHOLE-FILE and PURE-NEGATIVE (Inc-3 F-L6-1 / Inc-4 recurrence).
   * every count in its OWN prefix, `-COUNT-n` then `-NOT` of the SAME pattern.
   * `!cq.branchphase` is STRIPPED from the ordered stream (its NUMBER is LLVM's) and its
     count asserted in MDCNT against the `cqrt_rz_i1` count — round-1 F-L7-1's invariant.
   * ⚠ A CANDIDATE NEGATIVE SHIPS ONLY AFTER FileCheck ITSELF MEASURES that it does not
     fire on the clean output; one that would fire is DROPPED **and printed in the file**.
     Same for every ORIGINAL `-NOT` in the fixture: re-measured whole-file, kept or
     recorded. A `-NOT` that used to sit after a positive of its prefix was WINDOWED; the
     whole-file re-ask is strictly stronger, and where the pattern is counted the
     `-COUNT-n`+`-NOT` pair pins `exactly n`.
   * the STDERR half of a fixture (21 of the 104 assert a WARNING via `2> %t.err` or
     `2>&1 | %filecheck`) is CARRIED ACROSS VERBATIM with its RUN lines and directives —
     regenerating the RUN block wholesale would have destroyed it. A generated prefix that
     would collide with a preserved one aborts the file (`PREFIX-CLASH`).
   * FileCheck metacharacters (`{{`, `[[`) in a derived line RAISE rather than silently
     becoming a regex.
   * the prose INTERLEAVED with the old CHECK block is dropped (it narrates the pre-Inc-1
     stream line by line and is now false); the count of dropped lines is printed in the file.
  Trial on `control_swap_diamond.ll` + `control_swap_accept_post_region_theta_derived_cond.ll`
  (the stderr shape): both lit-GREEN on the subject.
Next: apply to all 104.

## 2026-09-05 step 4 — the 104 ACCEPTS re-derived (commit 21bcece).  lit 201 -> 105 reds
    python3 tools/migrate_phi_fixtures_rederive.py --files w_rederive.txt --rederive
    -> verdicts: {'REDERIVED': 104}
    lit -q ir-pass/test  ->  Failed: 105 (was 201).  comm(red2, w_rederive) = **0** — every
    one of the 104 is green, and 105 = 16 red respells + 13 flips + 76 hand, exactly.

## 2026-09-05 step 5 — the 95 DECLINES re-spelled (commit a8dbf51).  lit 105 -> 92 reds
    -> {'RESPELLED-WIDENED': 44, 'RESPELLED-CLAUSE-MOVED': 16, 'ALREADY': 35}
  ⚠ THE FIRST DRAFT PUT A FALSE SENTENCE IN 44 HEADERS AND I CAUGHT IT ON THE DIFF, NOT
  THE TEST. It wrote "the CLAUSE that refuses it moved" for every edit — but 44 of the 60
  were the SAME clause with the assertion WIDENED from a suffix to the whole DS_Error text
  (`nested control flow …` -> `cq controlled lowering: nested control flow …`), and only 16
  were a real disposition change. The tool now splits on `newdiag.endswith(old)` and emits
  two different notes; the verdict names them apart. A green suite would never have seen it.
  The CLAUSE-MOVED 16 are EXACTLY the 16 that were RED (`diff` of the two sets: IDENTICAL),
  which is the cross-check that the split is the real one.

## 2026-09-05 step 5b — ⚠ FINDING: THREE FIXTURES LOST THEIR SUBJECT, and a mechanical
## re-spell would have made them GREEN while pinning nothing they claim
  Three of the 16 moved to `cq_measure_<sfx> operand not recognized; expected a tainted i32
  handle` — a MODULE WELL-FORMEDNESS error, not a control decline:
    control_swap_reject_eqfold_wrong_edge_ifelse.ll   measures `i32 7`
    control_inplace_ry_reject_stateprep_rz_prep.ll    measures `i32 0`
    control_tainted_diag.ll                           measures `i32 %y0` (a plain argument)
  CAUSE (measured): all three are built on `cq_phi_<sfx>(i32 <CLASSICAL>, θ)` — a phase gate
  whose arg-0 is a CONSTANT or an untainted argument. That call was the only thing making
  the merged value quantum. prep_a's class-A rewrite dissolved the merge φ to the pred
  incoming EXACTLY as the rule says, and the pred incoming is that classical value, so the
  migrated module now feeds a constant to `cq_measure`. The migration is CORRECT; the
  fixture's program is no longer a well-formed CQ program.
  POPULATION MEASURED (pre-migration tree): **40 files** carry a classical-literal arg-0
  `cq_phi`, **32 of them migrated**; only these 3 reach a quantum SINK with it (the sweep
  over all 288 found that string exactly 3 times). The other 29 dissolve to a constant that
  nothing measures, or decline earlier.
  ⚠ prep_a's oracle check could not see this: for class A the oracle degrades to
  `opt -passes=verify`, and an ill-formed CQ PROGRAM is a perfectly well-formed LLVM MODULE.
  These 3 are REVERTED out of the respell batch and go to the hand-decision batch.
Next: step 6 — the 76 hand decisions.

## 2026-09-05 step 6 — the 76 HAND DECISIONS, group by group
Groups (from prep_a's report, re-derived on the rebased pre-migration tree):
  HOLD 26 · class-H tainted angle 24 · undissolvable merge phi (class A) 24 · structural 2

### 6a — class H (tainted angle), 24 files: MIGRATED, not deleted (commit 702bd8f)
  An H site is BY CONSTRUCTION of the classifier's own branch an UNCONTROLLED site
  (`blk not in under`) whose ANGLE is tainted, so the naive D2 reading DELETES it and takes
  the fixture's subject with it. MEASURED instead ($W/probe/hs_flat.ll, subject binary):
    uncontrolled `call void @cq_phi(double %tainted)`  -> exit 1
      `cq rotation lowering: unsupported quantum-derived rotation angle`
    the same call INSIDE a tainted arm                 -> exit 1
      `cq controlled lowering: rotation angle under quantum control`
  i.e. the pass refuses the call BEFORE it decides whether it is a global phase, so the
  tainted-angle rule survives D2 verbatim and the right rewrite is the VOID CALL.
  New `--migrate-tainted-angle` flag on prep_a's tool (the measurement is written at the
  site). 22 of 24 migrate; 20 of the 22 keep a tainted-angle decline; 3 have the clause
  PRE-EMPTED by an earlier guard and say so in their header
  (switch_angle_arith/_sitofp -> `condition data use neither escaped nor measured`;
  tainted_angle_opaque -> `taint escape`); 2 hold with the undissolvable-phi group.
  lit 92 -> 70.

### 6b — HOLD / THETA-OK, 16 files: swapped to `cq_theta` (commit ...). lit 70 -> 54
  Re-measured on the SUBJECT (prep_a measured the same 16 on the ORACLE): swapping every
  `cq_phi_<sfx>` for `cq_theta_<sfx>` (with the duplicate `declare` deduped — the naive
  sed gives `invalid redefinition` and reads as THETA-MOVED, which is what made my first
  probe say 26/26 MOVED) reproduces each fixture's ORIGINAL diagnostic
  character-for-character. CHECK lines UNCHANGED. Counts agree with prep_a exactly:
  **16 THETA-OK / 10 THETA-NO**.

### 6c — HOLD / THETA-NO, 10 files: 7 RE-SPELLED + 3 RETIRED (commit f4960ad). lit 54 -> 44
  ⚠ **THE STRUCTURAL FINDING OF THIS STEP.** `diagonalAliasHit` (ArmClassify.cpp:275) hops
  only through `isPhiCall`, and `isPhiCall(V) == isCallToPrefix(V, "cq_phi_")` — the
  RETIRED family. Since round-1 F-L6-1 that name is RESERVED and any module declaring it
  declines before analysis, so **no module that reaches `diagonalAliasHit` can contain
  one: its hop loop is STRUCTURALLY UNREACHABLE at HEAD, and so is `walkPhaseSpine`'s**
  (same prefix test), and so is `SwitchArmProve`'s `Hit != P` branch. That is prep_a's
  OQ-9/F1 prediction confirmed by reading + measurement. Left in place per PRD P6
  ("vacuous, not deleted"); listed for the owner as freeze-time dead code.
  * **G7 `control_swap_reject_switch_value_clobber.ll` KEEPS ITS FIXTURE** (the brief's
    hard requirement). Re-spelled with an ARITHMETIC-derived scrutinee (`add i32 %p, 1`),
    which reaches the SAME function's ZERO-HOP arm (`Prov.count(V)`) and renders the same
    PERMANENT string. MUTATION-VALIDATED BOTH WAYS: with the clobber (also the `xor`/`mul`
    variants) exit 1 `arm rewrites a condition operand`; with the arms rewriting a
    disjoint register ($W/g7/f_control.ll) exit 0 ACCEPTS; and the committed
    `control_swap_switch_value.ll` IS that accepting twin, so the discriminator lives in
    the tree. Recorded third variant: scrutinee == `%p` itself hits the C2 mis-anchor
    (`value-arm swap-route`) first, so the DERIVED scrutinee is load-bearing.
  * **`phase-class value escaping` IS REACHABLE** from the register-free surface — a
    kickback arm that also escapes the register it phased ($W/pv/{pret,abort}.ll). fix_r1
    shipped F-L5-6's widening as "LATENT — unreachable at HEAD, pinned by: none
    reachable"; these two fixtures correct that by measurement. Both discriminate: the
    same module minus the one `cq_phi` line declines on a DIFFERENT clause
    (`non-reconverging value exit` / `nested control flow`).
  * gate-5 channel B (the operand's WIRE is rotated elsewhere) is stem-independent ->
    2 files re-spelled with `cq_theta`. ⚠ The condition had to move to its OWN register:
    the naive in-place swap makes the compare read a register a NON-DIAGONAL gate later
    rewrites, so `condition predates a non-diagonal gate` pre-empts gate 5. Rz was
    diagonal, Ry is not — the one substantive stem difference, and it lands here.
    Discriminator measured: with the downstream rotation exit 1, without it exit 0.
  * the alias-REBASE evasion is about SSA ANCHORING, not diagonality -> 2 files re-spelled.
  * RETIRED 3: `select_phase_operand` + `select_fp_phase_operand` (channel A, "the operand
    CARRIES a phase" — MEASURED: an operand that is merely a rotation OUTPUT now ACCEPTS,
    so channel A has no spelling at all) and `value_alias_cond` (pinned the `Hit != P`
    branch, which needs the dead hop; its surviving half is covered by 20+ diamond
    clobber fixtures).
Next: the 24 undissolvable-merge-phi files + 2 H leftovers + 2 structural + 3 lost-subject.

### 6d — the 26 undissolvable merge phis + 2 H leftovers: new `--keep-merge-phi` (b3f2ea6)
  prep_a's tool refused these because the phi's incomings carry DIFFERENT registers.
  DISSOLVING WAS NEVER THE RIGHT MOVE FOR THIS SHAPE: they are the MIXED-arm /
  CROSS-HANDLE / DISTINCT-BASE decline fixtures, where the phi IS a genuine data mux and
  IS the thing being refused. Under the register-free surface the phase arm stops
  producing a value, so the only edit needed is the RAUW of the call's result to its base
  — the phi survives with one incoming now naming the base.
    26/26 migrated · 26/26 `opt -passes=verify` clean · 26/26 still DECLINE.  lit 44 -> 18.
  Of the 26 respells: 10 CLAUSE-MOVED, 14 WIDENED, 2 ALREADY.
  `lowering_reject_break_phase_answer.ll` (the brief's named file) now fires
  `cq loop lowering: early break preserves a phase answer` — the F-L5-6 break B3 fence,
  reached because the loop BODY is control-dependent on a tainted exit condition, which
  is exactly `functionCarriesBranchPhase`'s question.

### 6e — the last 5 (7653786).  lit 18 -> 12
  * `control_angle_select_reject_runtime_arms_rz.ll` -> **ACCEPT** (the brief's explicit
    instruction; owner Q3). GROUND: not a relaxed tolerance — under kickback there IS no
    subtraction. Each run-time arm's angle reaches its OWN `cqrt_rz_i1` verbatim under its
    own polarity bracket, so 2b's `fl(A−B)` residual has no object. MEASURED stream:
    `x(f); rz_i1(f,%y); x(f); rz_i1(f,%x)`. Kept as the STEM SEPARATOR — its Ry twin
    `control_angle_select_reject_runtime_arms.ll` STILL declines `rotation angle` on the
    same binary — and pins `NOROUTE-NOT: fsub`, the instruction whose absence is the whole
    argument. ⚠ Its name still says `reject`; the header says why that is deliberate
    (renaming breaks the pairing the Ry file's header sends a reader to). Not a red-green
    against the ORACLE: the oracle declines this module `tainted value consumed by an
    unknown callee` (the void prototype does not exist there), NOT the old `rotation angle`.
  * `lowering_reject_intrinsic_invoke_phi.ll` — hand-migrated (the tool refuses `invoke`
    by design). Guard unchanged; only the reserved NAME moves, `cq_phi_si32` -> `cq_phi`.
  * `control_tainted_diag.ll` — re-spelled with `cq_theta` on the classical base, and its
    STATED GROUND corrected: it no longer fails "accept-criterion 3 (quantum base)"; drbq
    Inc 4's F1 (`state prep seed does not match the merge incoming`) fires first. Its
    assertion is the LOOSE tail `under quantum control`, so the assertion is unchanged.
  * RETIRED 2 more: `control_swap_reject_eqfold_wrong_edge_ifelse.ll` and
    `control_inplace_ry_reject_stateprep_rz_prep.ll` — both need a `cq_phi` ARG-0 (to
    re-anchor / to state-prep) and register-free `cq_phi` has none; both had become
    ill-formed CQ programs measuring a classical value.
  * RETIRED `lowering_intrinsic_funnel_fshl_sibling_alias_phi.ll` — pins the POST-RAUW
    alias; D1 leaves `fshl(%a,%a,5)`, already covered by
    `lowering_intrinsic_fshl_rotation_i32.ll` (prep_a's bug-7 semantic conclusion, confirmed).
  **REMAINING 12 REDS == EXACTLY THE 12 LISTED FLIPS** (`diff` of the two sets: IDENTICAL).

## 2026-09-05 step 7 — FIXTURE-INTEGRITY INJECTION, and it FOUND A BLIND SPOT (551eb7d)
  `tools/migrate_phi_fixtures_inject.py`, all **104** re-derived accepts (brief asked >=40).
  ⚠ **THE FIRST VERSION OF THE HARNESS WAS WORTHLESS AND SCORED 104/104 ON EVERYTHING.**
  It appended inside the function body — in the middle of the derived `CHECK-NEXT` chain —
  so ANY extra line broke adjacency and every injection reported "caught". That measures
  the chain and says NOTHING about the NOROUTE negatives. The line now goes AFTER the last
  closing brace, past the chain, where only a whole-file negative can see it; and a
  HARMLESS CONTROL runs at the same site and must NOT be caught.
  At the honest site: **4 of 104 were BLIND to an injected `cqrt_rz_i32_controlled`** —
  the pre-Inc-1 TENSORED gate this increment exists to remove. Cause: those 4 legitimately
  emit `cqrt_ry_i32_controlled` / `cqrt_copy_i32_controlled`, so the tool had correctly
  measured the blanket `_controlled` negative as inapplicable and DROPPED it, and that
  took the only catch for a controlled Rz with it. The width complement cannot cover it
  either (it needs `(` right after the width; `cqrt_rz_i32_controlled(` has `_controlled`
  in between). FIXED by a NARROW twin, `call void @cqrt_rz_{{[a-z0-9]+}}_controlled(`.
  FINAL (after the fix, all measured):
      CLEAN pass            104/104
      (a) cqrt_cswap        caught 104/104   BLIND 0
      (b) cqrt_rz_i32_controlled  caught 104/104   BLIND 0   (was 100/104 before the fix)
      (c) surviving call void @cq_phi  caught 104/104   BLIND 0
      (d) DROPPED flag cqrt_free  caught 101/101   BLIND 0   (3 n/a — no free emitted)
      HARMLESS CONTROL      caught **0**/104  <- the row that makes the others mean something
  The re-derive tool is now IDEMPOTENT (strips a prior prep_a2 block), so this is a clean
  re-run, not a stack of notes (verified: 1 note per file).
Next: step 8 — `--verify-oracle` in SUBJECT-vs-ORACLE mode, then the report.

## 2026-09-05 step 8 — SUBJECT-vs-ORACLE KICKBACK WITNESS (0989857) — §10 item 4 discharged
  `tools/migrate_phi_fixtures_kickback.py`. prep_a's `--verify-oracle` could not look at the
  GATE STREAM for A/S/MIX (the oracle cannot lower `void @cq_phi(double)` at all), so this
  compares DIFFERENT INPUTS on purpose — ORACLE on the PRE-migration module, SUBJECT on the
  POST-migration one — after applying PRD §10.2 diff class (a) to the oracle's output
  (`cqrt_rz_<W>_controlled(%f,%h,θ)` -> `cqrt_rz_i1(%f,θ)`; uncontrolled `cqrt_rz_<W>`
  deleted per D2), modulo SSA renumbering.
    **83 MATCH · 21 MISMATCH, all 21 in a NAMED class, 0 in "OTHER — inspect":**
      10  ROUTE -> KICKBACK (oracle used cqrt_cswap; P4 nest / P5 switch, emitter DELETED in 1b)
       7  BY-DIFFERENCE -> TWO VERBATIM GATES (2b angle select; no fsub, one cqrt_x bracket)
       4  class (a) + EXTRA `_unc`/`free` THE ORACLE LEAKED  <- recorded, NOT blessed
  The last class: the substitution IS present and the subject additionally discharges a rail
  the pre-3qlq binary left allocated (`control_swap_cond_datause_measured` gains
  `cq_template_zext_i1_to_i32_unc` + `cqrt_free` for the cast rail). A paired `_unc`+`free`
  is the correct Rule-6 discharge, so it reads as an improvement — but it is a capability
  difference PRD §10.2 does not list, so it is recorded for the reviewers.

## 2026-09-05 step 9 — report + FINAL STATE (949c57d)
  MIGRATION_REPORT.md gains **PART II** (§11–§18, 354 -> 717 lines).
  FINAL lit on the SUBJECT (`$SP/progress/prep_a2_lit_FINAL.log`):
      Total Discovered Tests: 1655     Failed: 12 (0.73%)
  and `diff` of the red set against the 12 listed FLIPS: **IDENTICAL**.
  Corpus: 1661 -> 1655 (6 retired). LIVE `@cq_phi_<sfx>` references: **3**, and all three
  are the IMPLEMENTER's own reserved-name fixtures which must keep the old spelling.
  prep_a's invariant "the declare count of `@cq_phi_*` must be 0" is REACHED.
  SCOPE: `git diff --name-only 85ec83a..HEAD` outside
  {ir-pass/test, tools/migrate_phi_fixtures*, the report} is **EMPTY**.
  9 commits (21bcece..949c57d) + the report commit.

# ============================ HAND-BACK ============================
See the final message.

## 2026-09-05 step 10 — EXECUTED THE Rule-13 FLIPS-LENS VERDICTS (e75bc80, 2a4cc2b)
  Lens: $SP/progress/review_flips.md — 12 flips graded, **0 over-accepts**.
  **(1) 7 REWRITTEN AS ACCEPTS + renamed out of `reject_`**, CHECKs derived from the
  subject's output, whole-file pure-negative NOROUTE (cswap · the 8-width Rz complement ·
  the narrow `cqrt_rz_{{[a-z0-9]+}}_controlled(` · a surviving `@cq_phi` · and two NEW
  measured candidates `fsub double`/`fadd double`), counts in ACNT/FCNT/XCNT, MDCNT
  asserting rz_i1 == !cq.branchphase, and a header naming the old fixture, the old string,
  what the decline PROTECTED and why the property is gone:
    #1  -> control_angle_select_rz_loop_rail_exit_block
    #2  -> control_angle_select_rz_rounding_one_1e300      (does NOT depend on §12 Q3)
    #6  -> control_swap_diamond_n3_runtime_angles
    #8  -> control_swap_nested_phase_multireg
    #9  -> control_swap_nested_phase_crossreg_n2
    #10 -> control_swap_seq_ifelse_second
    #11 -> control_swap_switch_datamux_angle_runtime       (⚠ CONTINGENT on §12 Q3)
  **(2) 4 RETIRED**: diamond_derived_crosshandle, eqfold_wrong_edge_{eq,ne},
  ifelse_derived_mixed.
  **(3) #12 RE-SPELLED**: stray `add i32 %u0, 7` (classical, dead, non-foldable) asserting
  `control flow` (the string MOVED off `impure phase arm` for switch AND diamond — said in
  the header); pins SwitchClassify.cpp:262-284. Discriminator MEASURED: delete the stray
  and the module accepts.
  **(4) Lens F1**: the 4 `control_swap_eqfold_*` headers rewritten to what they now pin
  (each measured); §13.3a added to the report for tryEqFoldArm D1–D8 /
  `straightThroughConstFoldHandle` / the §5 re-anchor as freeze-time dead code.
  **(5) §13.3 wording CORRECTED**: `diagonalAliasHit`/`operandsAlias` are DECLINE tests, so
  their vacuity is a **WIDENING**, safe only because the population cannot exist — not a
  narrowing. `walkPhaseSpine` is neutral; `Hit != P` is a message narrowing.
  ⚠ **ONE OF MY OWN HEADERS QUOTED A DIRECTIVE TOKEN IN PROSE** and FileCheck reads a
  directive ANYWHERE on a line, so it minted a real (passing, invisible) `NOROUTE-NOT`.
  Found by a corpus-wide scan for armed-prefix tokens outside a directive position; fixed.
  The scan found **26 OTHER files** with the same pattern, all PRE-EXISTING — recorded in
  the report §14.4, not fixed.
  INJECTION re-run over ALL 111 accepts (104 + the 7 new): CLEAN 111/111 · cswap 111/111 ·
  ctl_rz 111/111 · live @cq_phi 111/111 · dropped free 108/108 (3 n/a) · HARMLESS CONTROL
  caught **0**/111.
  **FINAL lit on my binary: 1651 discovered · 1650 PASSED · 1 EXPECTEDLY FAILED · 0 FAILED.**
