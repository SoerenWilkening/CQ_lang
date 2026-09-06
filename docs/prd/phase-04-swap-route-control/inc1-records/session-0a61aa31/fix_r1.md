# progress — fix_r1 (Rule-13 round-1 FIX agent, bd test_C_libtooling-3qlq.2 Inc 1 part A)
Worktree `$SP/wt/fix-r1`, branch `3qlq-inc1-fix-r1`, base `fa96336`.
SUBJECT-BEFORE = main checkout `/Users/sorenwilkening/Desktop/CQ_lang` (branch `3qlq-inc1`, fa96336) — READ ONLY.
ORACLE = `$SP/wt/pre-3qlq` (52d7764).

## 2026-09-05 — step 0: setup
- Read BRIEF_common, BRIEF_fix_r1, BRIEF_impl_inc1a, progress/impl_inc1a.md, progress/review_r1_L7.md.
- Started background configure+build of `$SP/wt/fix-r1/build` (both CQPass and cq-opt) →
  `$SP/progress/fix_r1_build.log`.
- Re-read the orchestrator's F-L7-2 measurements in `$SP/progress/orch_perbit/`:
  MEASURED (their traces, re-read by me):
  * `perbit_new.trace`   (ROLLED, new surface): 4 `and_i32_hl`, **0** `and_i32_hl_unc`, 4 `cqrt_free` (flags only),
    diag = 2× `warning: cq rotation lowering: non-diagonal gate over a live derived record`.
  * `perbit_new_flat.trace` (FLAT K=2, new surface): 2 `and_i32_hl`, **2** `and_i32_hl_unc`, 4 frees, no diag.
  * `perbit_old.trace`   (ROLLED, OLD surface, oracle): 4 `and_i32_hl`, **4** `and_i32_hl_unc`, 8 frees, no diag.
  * `perbit_old_flat.trace` (FLAT K=2, old surface): 2/2, 4 frees, no diag.
  ⇒ the discharge is present on 3 of the 4 corners and absent exactly at (ROLLED × kickback).

## 2026-09-05 — F-L7-1 / F-L1-1 / F-L2-1 (CONFIRMED MISCOMPILE) — FIXED, commit 315cadf
REPRODUCED first on my own binary at base fa96336 (`$SP/progress/fix_r1_work/run.sh`,
3-binary harness: subj=$SP/wt/fix-r1, main=/Users/.../CQ_lang, orac=$SP/wt/pre-3qlq):
`j3_sharecond_measure_only.c` emitted `rz_i1(h1,+.25) … zext … rz_i1(h1,-.25)`.

FIX (differs from the L7 plan in ONE respect — see below): a per-instruction MEMBERSHIP
record, `ChainWalk::markBranchPhaseGate` / `isBranchPhaseGate`, spelled as the instruction
metadata `!cq.branchphase`. Stamped at all THREE emission sites (`SwapRouteEmit::emitArm`,
its merge-tail loop, `AngleSelectEmit`'s Rz stem). Refused FIRST by
`ChainWalk::isInPlaceGateOn`, `ChainWalk::preservesBasisUnderRecord` and
`EmitInverse::isInverseEmittable`.

⚠ DEVIATION FROM THE ENDORSED PLAN, deliberate, reported for the orchestrator to judge:
the plan said `taint.BranchPhaseGates` (a `TaintSet` pointer set). I used instruction
metadata instead. THE QUESTION ASKED IS THE SAME (membership of the emitted instruction,
never a name); only the storage differs. Three reasons, each measurable in this tree:
 (1) the three predicates are PURE per-gate functions with no `TaintSet` parameter, asked
     from 19 call sites in 6 files, three of which (`railOf`,
     `railCarriesControlledRotation`, `ArithLowering::priorUseIsSettled`) have no
     `TaintSet` in scope at all — threading one through is a cross-cutting signature
     change to the Rule-13 core in service of a fix to the Rule-13 core;
 (2) a `Value*` set keyed at emission and read many stages later is the bd `drbq` Inc-1
     round-1 defect verbatim (the set dangled when a later stage RAUW'd/erased the key);
     metadata dies with its instruction and cannot dangle;
 (3) metadata survives `CloneFunctionInto` (Phase-6 specialization); a pointer set does
     not — a cloned kickback gate would silently fall OUT of the set.
There is exactly ONE spelling of the question either way (Rule 14). The record is also
VISIBLE in the lowered `.ll`, which is the artifact fixtures and `free_pairing_check.py`
read.

MEASURED (all with the 3-binary harness):
| probe | main (before) | subj (after) |
|---|---|---|
| `j3_sharecond_measure_only.c` | `rz_i1(+θ)`, `rz_i1(−θ)`, strip, free | `rz_i1(+θ)` only; flag LEFT ALLOCATED |
| `i1_sharecond_negated.c` (`!=`) | cancelled too | phase intact |
| `u4_datause_new.c` (= prep-b's `slice_control_cond_datause.c`) | `+.25,+.75,−.75,−.25` | `+.25,+.75` only |
| `u7_datause_one.c` | cancelled | fixed |
| `u9_share_measureflag.c` | cancelled | fixed |
| `u6_datause_negshare.c` (negated, already correct) | — | BYTE-IDENTICAL to main |
| `u8_share_tail.c` (tail φ, bracketed) | — | BYTE-IDENTICAL to main |
| `j3_nophi.c` (control, no `cq_phi`) | — | BYTE-IDENTICAL to main AND to the oracle |

THE WITNESS, and it is stronger than the "differ by exactly one line" the brief asked for:
`diff -u out/j3_old.orac.trace out/j3_sharecond_measure_only.subj.trace` is EXACTLY
`-cqrt_rz_i32_controlled(h1, h0, 0x1p-2)` / `+cqrt_rz_i1(h1, 0x1p-2)` and nothing else —
PRD §10.2 diff class (a). ⚠ CORRECTION TO THE BRIEF/L7: the pair
`slice_..._sharecond` vs `..._nophi` CANNOT "differ by exactly one `cqrt_rz_i1` line" —
adding the kickback legitimately also removes the strip+free (the spine can no longer
close a rail carrying an opaque gate), which is precisely what the ORACLE does on the
same pair. The correct witness is SUBJECT-with-phase vs ORACLE-with-phase, above.

STRICT stage 2b: PASS on all 8 probes (`2 rail mint(s) … 0 violation(s), 0 unproven`).

REGRESSION MEASUREMENT (the honest before/after): full `lit ir-pass/test`
 * MAIN's binary over MY worktree's fixtures: 1239 passed / 1 XFAIL / **362 FAILED**
   (`$SP/progress/fix_r1_lit_MAIN.log`, 95.7 s)
 * MY binary, same corpus: 1239 / 1 / **362** (`$SP/progress/fix_r1_lit_A.log`)
 * `comm` of the two red sets: **0 new reds, 0 newly green** — the fix changes no
   fixture's disposition. All 362 are the pending prep-a migration set.

FIXTURES (Rule 12, red-green MEASURED on both binaries):
 * `control_phase_kickback_share_flag.ll` — ACCEPT; the `-O1` IR of `u9` verbatim.
   Whole-file PURE-NEGATIVE `NOROUTE` (incl. `double -` and `fneg`), the count in its own
   `ACNT` prefix, the zero-free assertion in `FCNT`. FAILS on main's binary, PASSES on mine.
 * `control_phase_kickback_share_flag_negated.ll` — ACCEPT; the `u6` twin, the polarity that
   was ALREADY green by accident. FAILS on main's binary on the `!cq.branchphase`
   assertion ALONE (line 43 — measured, every other directive passes there), which is the
   honest statement of what it pins on this half: THE RECORD.

ALSO SHIPPED IN THIS COMMIT (doc truth): F-L7-5 — the `ShareCondFlag` paragraph's
"byte-for-byte the rule `emitRegion` follows" claim rewritten (it is FALSE, and its
falseness is where the miscompile lived: `emitRegion`'s gate is
`cqrt_rz_<W>_controlled`, which `isInPlaceGateOn` REFUSES; this one was a plain
`cqrt_rz_i1`, which it ADMITTED — two emitters, one sentence, opposite consequences), and
the note now says the protection is the MEMBERSHIP on BOTH paths rather than the
non-share path's own `cqrt_free`. F-L1-3 — "ONE BRACKET PAIR PER ARM" was being read as
per REGION and is false for the merge-tail spelling (4 `cqrt_x` from plain C), and its
citation of `SwapRouteEmit.cpp:1063`'s `-2 cqrt_x` audit arithmetic was a FALSE
DEPENDENCY (that note is the Inc-2a collapse arithmetic; the kickback path feeds neither
it nor `golden_multiset_audit.py`). Both corrected in place.

## 2026-09-05 — F-L3-1..7 (2nd CONFIRMED MISCOMPILE + 6 items) — FIXED, commit 6eded46
See the commit message for the full record. Headline: `deleteGlobalPhases` moved from
"immediately after `lowerControlRegions`" to AFTER `repropagateControlMerges` in BOTH entry
points; the crossed stages were re-asked in writing (`declineTaintEscapes`' PhaseCalls carve,
round-2 `detectSpecializations`, `collapseFlattenedLoopRails`).
MEASURED on L3's own reproducer modules, my binary:
 * `repro_t1_onward_angle_select.ll`: was rc=0 with **0** `cqrt_rz` and **5**
   `cqrt_copy_f64_controlled` (an ANGLE on a quantum f64 rail); now rc=0 with **4**
   `cqrt_rz_i1` and **0** `cqrt_copy_f64_controlled`, STRICT 2b PASS, and the emitted
   stream is character-for-character L3's stated correct circuit.
 * `repro_n1_onward_phase_valuearm.ll`: was rc=0 (over-accept); now rc=1
   `cq controlled lowering: impure value arm under quantum control`.
 * `repro_j1_onward_kickback.ll` (F-L3-2's over-decline): now rc=0, 2 `cqrt_rz_i1`.
lit after this batch: 1246 passed / 1 XFAIL / 362 FAILED (1609 total, +7 fixtures);
`comm` vs main's 362: **0 new, 0 newly green**.

## 2026-09-05 — F-L7-2 / F-L5-1 / F-L2-1b (the rolled in-loop leak) — CAPABILITY FIX (a)
The orchestrator offered (a) the capability fix or (b) a loud decline. **(a) SHIPPED**, in the
bounded form below, because it was measurable and it is narrow.

ROOT CAUSE (L5 located it; I re-derived and re-measured it): `markIfRailLocal` is called ONLY
when `collapseRailPhisIn` returns `Collapsed`. Under the register surface `q = cq_phi(q,θ)` in
the arm made `q` LOOP-CARRIED, so there was a rail phi to collapse, `Roots` was non-empty and
the body was marked — which is why the ORACLE discharges. Under the register-FREE surface a
kickback body gates NOTHING, so `q` is loop-INVARIANT, the header has no tainted phi,
`collapseRailPhisIn` returns `NotClaimed`, `markIfRailLocal` is never called, and
`Uncomputation.cpp`'s `if (canRepeat(&BB) && !IterationLocalBlocks.count(&BB)) continue;`
SILENTLY skips every interior candidate in the body.

THE FIX: a new `invariantRegisterRoots` (`LoopLowering.cpp`, ~90 lines of which ~60 are the
argument) supplies `markIfRailLocal` — **UNCHANGED** — with the `Roots` a loop-carried rail
would have supplied, for a loop whose registers are loop-INVARIANT. It admits ONLY a ROOT MINT
(a classical-arg-0 `cq_theta`, PEELED through in-place gates with the identical
`peelInPlaceBase(..., AsLowered=true)` call `markIfRailLocal::onRail` makes — Rule 14), and
only when the header carries NO tainted phi at all.

WHY THAT RESTRICTION IS THE PROOF, and it is aimed at the hazard `markIfRailLocal`'s own
comment names ("a recovered gate in the PREHEADER … with `At` in a body marked here … would
emit K adjoints against ONE forward gate … Widening it — even 'just' to admit a hoisted
loop-invariant temp — makes it reachable, and no shipped test would go red"): a root mint
lowers to `cqrt_alloc_<W>` and `ChainWalk::isInteriorTerminalHandle`'s clause (I1) excludes an
alloc-minted rail from the M-B interior partition OUTRIGHT, so no `At` can ever be placed for
it. The hoisted-TEMPLATE-rail case the comment warns about is REFUSED by construction, and I
built the discriminating control for it rather than asserting it.

MEASURED (my binary vs main's, full pipeline, STRICT 2b on every one):
| probe | main (before) | subj (after) |
|---|---|---|
| `j_perbit4_rolled` vs `_unrolled` | 4 `and` mints / **0** `and_unc` / 4 frees vs 4/4/8 → DIVERGE | **BYTE-IDENTICAL**, 39 lines, 4/4/8 both |
| `j2_perbit32` (K=32) | 32 mints, **0** unc | 32 mints, **32** unc, 64 frees |
| `zz_perbit_diffusion` (orchestrator's F-L7-2 repro) | 2× `warning: non-diagonal gate over a live derived record`, rolled≠unrolled | **no warning**, rolled == unrolled BYTE-IDENTICAL |
| `zz_perbit_dead` (register DEAD after the loop) | leaks | rolled == unrolled; the diff vs main is EXACTLY the K discharge pairs and nothing else; the alloc root `h0` still left allocated (I1) — no `cqrt_ry(h0,−θ)`, i.e. the multiplicity hazard did NOT materialise |
| `z_preheader_rail8` ⭐ THE DISCRIMINATING CONTROL — a hoisted loop-invariant TEMPLATE rail (`int p = q*3;`) read by the body's condition, K=8, loop genuinely rolled | 8 `and` mints / 0 unc | **UNCHANGED, 0 unc** — refused, exactly the case the comment warns about |
| `zz_chained_root` (`q=cq_theta(u,.3); q=cq_theta(q,.1);` then the per-bit loop) | leaks | the un-peeled first draft left it DIVERGING; with the peel it is **IDENTICAL** to its twin |
| `zz_two_invariant_regs` (TWO invariant root mints, two regions per trip) | — | rolled == unrolled, 78 lines |
| the NINE L5 clean pairs (`a_kick`, `b_k1`, `c_mixed_ry`, `d_leading`, `e_two_regs`, `h_n_gates`, `k_derived`, `l_perbit_ry`, `v_seq_inloop`) | identical | still identical, and **byte-identical to main's output** — the change touches nothing that was already working |

## 2026-09-05 — F-L6-1 (3rd CONFIRMED defect) + F-L4-1 + F-L5-6 + coverage + notes
Commits f1ca58c, f7ecab4, 0afa08e, 449d69b, bfcfd53, bb78020. See the commit messages and
`docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC1_NOTES.md` §1 for the full record.

⚠ **F-L6-1'S BLAST RADIUS — 34 fixtures go RED, and the orchestrator asked to be told
exactly which so the merge can be sequenced.** Every one of them CALLS the retired
`@cq_phi_<sfx>` family (verified by grep; ZERO outside prep-a's migration set). Full list in
`$SP/progress/fix_r1_new_reds.txt`. The four that matter for sequencing:
  * `control_swap_switch_phase.ll`, `control_swap_switch_phase_passthrough.ll`,
    `control_swap_switch_scrutinee_measured.ll` — part B's P5 rows, accept → decline, exactly
    as the orchestrator predicted.
  * `lowering_reject_live_record_routed_base_anc.ll` — the ONE green fixture that was blind
    to a surviving retired call (F-L6-1's reproducer B).
The other 30 are DECLINE fixtures whose string is now pre-empted by the earlier
reserved-name decline; each still declines, on a different (earlier, and more accurate)
ground.

# ============================ HAND-BACK ============================

## 1. What shipped
Branch `3qlq-inc1-fix-r1` in `$SP/wt/fix-r1`, **9 commits** on top of `fa96336`:
```
315cadf F-L7-1/F-L1-1/F-L2-1  the spine no longer adjoints the kickback gate
6eded46 F-L3-1..7             P7 moved after the round-2 control fixpoint + 4 fixtures
b97ced4 F-L7-2/F-L5-1/F-L2-1b the rolled in-loop derived-condition rail discharges
f1ca58c F-L6-1/3/4/7 + F-L8-1/2  retired register form is a reserved name; postcondition asserted
f7ecab4 F-L4-1 + F-L5-6       undef arm reaches a gate slot; the phase-carrier widening
0afa08e F-L5-3/F-L5-4/F-L1-2/F-L1-3  fixture coverage
449d69b docs                  RETIRE_SWAP_ROUTE_INC1_NOTES.md §1
bfcfd53 F-L4-3               4 decline fixtures for the phase angle-select accept class
bb78020 docs                  F-L8-3/F-L8-4/F-L8-5/F-L6-2 + the prep-a hand-off
```
**Source + header files touched (16, MEASURED `git diff --name-only fa96336..HEAD -- ir-pass/src ir-pass/include`):** `ChainWalk.{h,cpp}`, `EmitInverse.cpp`, `SwapRouteEmit.cpp`,
`AngleSelectEmit.cpp`, `CQLoweringPass.cpp`, `TaintPropagation.{h,cpp}`, `ArmClassify.cpp`,
`LoopLowering.cpp`, `ControlDetect.cpp`, `AbortParkEmit.cpp`, `SpecializeReject.cpp`,
`SpecializeDetect.cpp`, `WidthDispatch.h`, `ArmAnalysis.h`.
**Fixtures (MEASURED): +24 ADDED, 14 MODIFIED** (11 of those are the NOROUTE-width
rewrite, the rest are header corrections and the two string updates), **1 frontend test
fixed**, **56 files changed in total**.
**Docs: 1 new file** (`docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC1_NOTES.md`).

## 2. What I ran (only what I ran)
* `lit ir-pass/test` from `$SP/wt/fix-r1/build`, FINAL: **1229 passed · 1 expectedly failed ·
  396 FAILED · 1626 discovered** (`$SP/progress/fix_r1_lit_Z.log`).
* The SAME corpus through **main's binary** (`CQ_OPT=/Users/.../CQ_lang/build/ir-pass/cq-opt`):
  **1239 / 1 / 362** (`$SP/progress/fix_r1_lit_MAIN.log`, 95.7 s). `comm` of the two red sets:
  **34 new reds, 0 newly green**; all 34 call the retired family.
* `ctest -R 'frontend-lit|runtime' -j6` → **8/8 passed**. `ctest -R cq-opt-equivalence` → **passed**.
* **STRICT stage 2b** (`free_pairing_check.py`, no `--allow-unproven`) on every accepting
  plain-C reproducer in `$SP/progress/fix_r1_work/p/`: **47 accepting, 0 violations**.
* ~60 plain-C / hand-IR reproducers through the FULL pipeline on THREE binaries
  (subj = `$SP/wt/fix-r1`, main = `/Users/sorenwilkening/Desktop/CQ_lang`,
  orac = `$SP/wt/pre-3qlq`), harness `$SP/progress/fix_r1_work/run.sh`.
* **NOT run:** the full `ctest` (Rule 19 — the orchestrator owns that gate), `e2e-loop-twin-matrix`
  (prep-d2's, and I changed no `loop_twin_matrix` file).

## 3. Per-finding status
| finding | grade | status | pinned by |
|---|---|---|---|
| F-L7-1 / F-L1-1 / F-L2-1 | CONFIRMED MISCOMPILE | **FIXED** (membership, 3 emission sites, 3 predicates) | `control_phase_kickback_share_flag{,_negated}.ll` |
| F-L3-1 | CONFIRMED MISCOMPILE | **FIXED** (P7 after the round-2 fixpoint, both entry points) | `control_phase_kickback_onward_merge.ll`, `..._reject_onward_mixed_arm.ll` |
| F-L3-2 | OVER-DECLINE (same root) | **FIXED** | same |
| F-L7-2 / F-L5-1 / F-L2-1b | CONFIRMED MISCOMPILE | **FIXED** (capability fix (a), root-mint-only) | `control_phase_kickback_inloop_derived_cond.ll` + the mutation-validated control `..._reject_hoisted_temp.ll` |
| F-L6-1 | CONFIRMED Rule-1 third path | **FIXED** (reserved-name decline + postcondition assert) | `lowering_reject_legacy_phi_register_form_eqfold.ll` |
| F-L3-4 | OVER-ACCEPT (loud at ld) | **FIXED** | `lowering_reject_phi_address_taken.ll` |
| F-L3-3 | latent recognizer gap | **FIXED** | `lowering_reject_spec_branch_phase.ll` |
| F-L4-1 | undef arm in a gate slot | **FIXED** | `control_angle_select_phase_reject_{undef,poison}_arm.ll` + accept control `..._nonfinite_arm.ll` |
| F-L5-6 | latent WIDENING | **FIXED** (coarse, over-declining; LATENT — unreachable at HEAD) | none reachable; stated in the notes |
| F-L3-7 / F-L5-5 | message truth | **FIXED** (split by shape) | `control_phase_kickback_reject_compound_cond.ll` |
| F-L3-5 | doc truth (exit 134, not 0) | **FIXED** (re-measured myself) | the two corrected comments |
| F-L3-6 | doc/latent | **FIXED** (AXIS-F note) | — |
| F-L5-3 | fixture truth + over-decline | **FIXED** | `..._inloop_body_gate.ll` (accept) + `..._reject_inloop_invariant_cond_hoisted.ll` (decline) |
| F-L5-4 | OVER-DECLINE of a §6.2 shape | **PINNED, not fixed** → OWNER QUESTION | `control_angle_select_phase_reject_in_loop.ll` |
| F-L1-2 | zero coverage, 4 branches | **FIXED** | `..._{ifelse,ifelse_tail_armfalse,negated_tail_phi,share_flag,share_flag_negated}.ll` |
| F-L1-3 | doc truth (bracket count) | **FIXED** | `XCNT-COUNT-4` in two files |
| F-L1-4 | informational over-decline | recorded → OWNER QUESTION | notes |
| F-L1-5 | message truth, hand-IR | recorded only | notes |
| F-L6-3 | windowed `CHECK-NOT` | **FIXED**, injection-validated | `tests/frontend/cq_phi_smoke.c` |
| F-L6-4 / F-L8-1 / F-L4-2 | 2 of 8 Rz widths unguarded | **FIXED**, injection-validated both ways | 11 NOROUTE blocks |
| F-L8-2 | missing `cqrt_x` negative | **FIXED** | 3 fixtures |
| F-L6-7 | dead `phiFn` | **FIXED** (annotated; it now has one caller) | — |
| F-L6-6 | OWNER (defined `@cq_phi`; int-as-angle) | recorded → OWNER QUESTIONS Q-R1-3/4 | notes |
| F-L6-5 | docs still on the old surface | **NOT MINE** (orchestrator: Inc-0 + a docs pass) | — |
| F-L8-3 / F-L8-4 / F-L6-2 | write-up claims that do not reproduce | **FIXED** (headers + notes) | 3 fixture headers |
| F-L8-5 | hand-off | recorded for prep-a | notes |
| F-L5-2 / F-L5-7 | twin matrix | **NOT MINE** (prep-d2); I changed no matrix file | — |
| F-L7-3 / F-L7-4 / L1's 33-case polarity matrix / L2's 1–11 / L3's CLEAR table | CLEAR | no action | — |
| F-L7-6 | inherited latent unconditional free | recorded in the notes; NOT a code change (unreachable — both legs go through one `lowerCompareImpl` classification) | — |

## 4. OWNER QUESTIONS (full text in the notes file)
* **Q-R1-1** the hoisted loop-invariant TEMPLATE-rail leak that `invariantRegisterRoots`
  refuses (rolled ≠ unrolled; widening was measured NOT to produce the multiplicity defect,
  but the shipped comment says that defect is reachable and untested).
* **Q-R1-2** P2 (angle select) inside a loop declines although PRD §6.2 P6 declares it an
  accept shape.
* **Q-R1-3** should a DEFINED `void @cq_phi(double)` in the module be a loud decline
  (reserved-name rule) rather than a silent P7 capture?
* **Q-R1-4** a classical INT argument is silently a radian angle (the one-argument surface no
  longer separates register from angle in the type system).
* **Q-R1-5** is "N `cq_phi` per arm" a property of the CONSTRUCT or of the DIAMOND spelling?
  (Both if/else spellings decline, loudly and safely.)

## 5. What is left
1. **The 34 red fixtures** are prep-a's migration set. `$SP/progress/fix_r1_new_reds.txt`.
2. **The e2e slice pair for F-L7-1 was NOT added**, deliberately: `tests/e2e/` and its
   `CMakeLists.txt` are prep-b's, and the witness the brief asked for (two goldens differing
   by exactly one `cqrt_rz_i1`) is not achievable — see the correction in the notes. The
   STRONGER witness already exists on a slice prep-b has rewritten:
   `slice_control_cond_datause.c` on this binary is byte-identical to its committed
   old-surface golden except the two intended `cqrt_rz_i32_controlled` → `cqrt_rz_i1` lines.
   Before the fix that same slice emitted two extra NEGATED angles.
3. **Round 2 should be pointed at the sets this round NARROWED** — the branch-phase
   membership and the invariant-register roots — because "a set was narrowed and a consumer
   was not re-asked" is the failure mode two of this round's three CONFIRMED defects share.

# ======================= MERGE OF Inc 1b (2026-09-05) =======================
Merged `3qlq-inc1b` (71d4cce, 8 commits, same base fa96336) into
`3qlq-inc1-fix-r1`. **MERGED TIP: `c4bd888`** (parents `bb78020` + `71d4cce`).
Working tree clean; MAIN untouched throughout.

## The one conflict, resolved keeping BOTH behaviours
`ir-pass/src/ArmClassify.cpp`, `classifyPhaseKickback` step 5 — exactly the file
`git merge-tree` predicted, and the only one. Part B admits a condition TREE
(`collectCondTree(..., AllowLogicalSelect=true)`); my F-L3-7/F-L5-5 fix split the
REFUSAL message by shape. Part B NARROWS what reaches the refusal (the
`&&`/`||`/folded-nest spellings now ACCEPT) but does NOT close the hole:
`collectCondTree` still refuses the two NOT complements, a constant child and an
over-deep/cross-block tree, and every one is still a TREE and still not a bare i1.
So the resolved clause has part B's tree admission AND part A's refusal split,
with the whole argument written at the site.
My other round-1 edits to that file (the F-L4-1 undef fork, the in-loop clauses)
auto-merged cleanly and were verified present after the resolution.

## ⚠ WHAT THE MERGE EXPOSED — two UNMARKED emission sites (the real finding)
F-L7-1's fix requires that EVERY `cqrt_rz_i1` the pass emits carry
`!cq.branchphase`, or the whole-DAG spine reads it as an in-place rotation on a
reclaimable rail and emits `cqrt_rz_i1(f, −θ)`, cancelling the user's phase
EXACTLY. Inc 1b added TWO new minters that pre-date the fix and did not call it:
  * `SwapRouteEmit::emitPhaseKickbackNestRegion` (P4) — the OUTER root flag AND
    the `cqrt_toffoli` conjunction ancilla;
  * `SwitchRouteEmit::emitSwitchPhaseRegion` (P5) — the per-case eq-flag gates.
Both now call `markBranchPhaseGate`. **P3 needed nothing** — it reuses part A's
own `emitArm` loop with the tree ROOT as the flag, so it was already covered;
that is a consequence of the Rule-14 reuse, not luck, and the fixture proves it.
This is the emitter's own warning coming true one increment later: *"a fourth
emitter that mints a kickback gate and forgets this call re-opens F-L7-1 with no
diagnostic anywhere."* It was two, and the merge was the moment to catch them.

**MEASURED — `cqrt_rz_i1` count == `!cq.branchphase` count, every probe:**
`p3_and` 2/2 · `p3_or` 2/2 · `p3_foldnest` 2/2 · `p4_nest` 4/4 · `p5_hand` 4/4 ·
prep-b's `slice_control_phase_andcond` 2/2 · `slice_control_phase_nest` 2/2.

**PINNED and MUTATION-VALIDATED both ways.** New `MDCNT`/`MDTAG` prefixes on
`control_phase_kickback_and2.ll` (P3, 1 gate), `control_phase_nest_kickback.ll`
(P4, 2) and `control_phase_switch_kickback.ll` (P5, 3) assert the two counts
SEPARATELY and require agreement. Deleting `markBranchPhaseGate` at the NEST site
reddens the nest fixture, at the SWITCH site the switch one, at the FLAT site the
`and2` one — each and only each (three separate build+lit cycles, measured).

## One Inc 1b fixture string CORRECTED (disposition unchanged)
`control_phase_kickback_reject_tree_notform.ll` asserted the bare-i1 message for
`select i1 %ca, i1 false, i1 %cb`, which **IS** a condition tree (the NOT
complement of one the grammar admits). It now asserts `control flow` — the string
the pre-3qlq oracle used and the one the split gives. Header records that only
the string moved. It was the ONLY red outside the retired-family set after the
merge, and fixing it is what makes the partition clean.

## Verification on the merged binary
| gate | result |
|---|---|
| `lit ir-pass/test` | **1264 passed · 1 XFAIL · 396 FAILED (1661 discovered)** (`fix_r1_lit_MERGED2.log`) |
| red partition | the red set is the **SAME 396 files** as my pre-merge tip — Inc 1b's 35 new fixtures are all green and no red changed — and **ALL 396 are inside the 493-file retired-`@cq_phi_<sfx>` set**, verified per file by grep. **ZERO reds outside it.** |
| `frontend-lit` + `runtime` + `cq-opt-equivalence` | **9/9 passed** |
| STRICT stage 2b | **54 accepting plain-C reproducers, 0 violations** |
| Inc 1b's TWIN GATE (`slice_control_phase_andcond` vs `slice_control_phase_nest`) | **BYTE-IDENTICAL**, 17 lines; 2b `6 verified, 0 violations` |
| every round-1 ShareCondFlag reproducer (6) | **0 negative-angle `rz_i1`** on all six |
| every round-1 rolled/unrolled pair (14) | **all IDENTICAL** |
| the two narrow-fix CONTROLS (`z_preheader_rail8`, `zz_hoisted_temp`) | still **0** discharges — the restriction still holds |
| `j2_perbit32` | still **32/32** discharged |

## ShareCondFlag opacity + F-L5-1 marking, probed against compound / nest / switch
Six probes (each construct × {in a loop, shared condition}). **ALL SIX DECLINE
LOUDLY — no adjoint, no leak**, which is the acceptable outcome the brief names:
```
P3 in-loop      control flow under quantum control
P4 in-loop      condition predates a non-diagonal gate under quantum control
P5 in-loop      control flow inside a loop body under quantum control
P3 shared-cond  condition used outside the branch under quantum control
P4 shared-cond  condition used outside the branch under quantum control
P5 shared-scrut condition data use neither escaped nor measured under quantum control
```
Sources: `$SP/progress/fix_r1_work/p/mg_p{3,4}_{inloop,sharecond}.c`,
`/tmp/p5_{inloop,sharecond}.ll`.

## ⚠ One disposition changed FOR THE BETTER, named so it is not mistaken later
Round-1 probe `h4_nest_true` (`if (q==5) { if (p==7) cq_phi(.4); }`) went
DECLINE → **ACCEPT**. That is Inc 1b's P3 capability on the folded nest, not a
regression — the two `@slice` bodies of `&&` and the folded nest are
byte-identical after `-O1`. My F-L3-7 fixture uses the CLASSICAL-guard spelling
(`t_classguard_flat`), which still declines `control flow`, so the fixture is
unaffected and still a discriminator.
