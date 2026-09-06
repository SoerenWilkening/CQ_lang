# progress — fix_r2 (Rule-13 round-2 FIX agent, bd test_C_libtooling-3qlq.2 Inc 1)
Worktree `$SP/wt/fix-r1`, branch `3qlq-inc1-fix-r1`, base `c4bd888` (merged round-1 fix + Inc 1b).
SUBJECT-BEFORE = main checkout `/Users/sorenwilkening/Desktop/CQ_lang` @ c4bd888 — READ ONLY (lens R2 is running there).
ROUND-1 SUBJECT = `$SP/wt/r1-subject` (fa96336). ORACLE = `$SP/wt/pre-3qlq` (52d7764).

## 2026-09-05 — step 0: setup
- Read BRIEF_common, BRIEF_fix_r2, BRIEF_fix_r1, progress/fix_r1.md, progress/review_r2_R1.md IN FULL.
- Worktree at c4bd888, clean. Build VERIFIED CURRENT: `find ir-pass/src ir-pass/include -newer build/ir-pass/cq-opt`
  returns EMPTY, and both `build/ir-pass/cq-opt` and `libCQPass.so` are dated 16:45.
- Work dir `$SP/progress/fix_r2_work/{p,out}`.

## 2026-09-05 — step 1: F-R1-1 REPRODUCED on my own base binary, and the population is WIDER than R1 measured
Harness `$SP/progress/fix_r2_work/{run.sh,multi.sh}` (4 binaries: subj=$SP/wt/fix-r1, main, r1s, orac).
* `multi.sh main p/o_onward_inloop.c p/j1_lib.c` → rc 0, 34 lines, `and_i32_hl` 3 / `and_i32_hl_unc` **0**;
  the hand-unrolled twin 40 lines, 3/3. `diff` = exactly 3 inserted `_unc`+`free` pairs. CONFIRMED.
* NEW (mine, not in R1's report): the SAME leak fires at **ROUND 1** for two more merge-out-rail
  emitters, so this is NOT only a stage-order finding:
  | probe | rolled and_hl/and_unc/free | unrolled |
  |---|---|---|
  | `p/s1_selectmerge_inloop.c` (4.4 tainted-cond SELECT `%out`) | 3 / **0** / 4 | 1/1/3 |
  | `p/s2_switchmux_inloop.c` (4.5 switch DATA-MUX `%out`) | 3 / **0** / 5 | 2/2/6 |
  | `p/o_onward_inloop.c` (6.5 classical-call arm `%out`, round 2) | 3 / **0** / 4 | 3/3/7 |
  (the two unrolled twins fold some bits away — `y` is a 2-value set at `-O1` — so they are not
  byte-twins; the load-bearing number is `and_unc == 0` in the ROLLED form.)
  ⇒ the ROOT CAUSE has TWO independent halves: (A) `invariantRegisterRoots` clause (ii) admits only a
  `cq_theta` ROOT MINT, so a control-owned merge out-rail (`cqrt_alloc_<W>` `%out`) is refused as a
  loop-invariant register at BOTH rounds; (B) the stage runs ONCE, before `repropagateControlMerges`,
  so the ONWARD region is claimed after it. Fixing only (B) leaves s1/s2; fixing only (A) leaves the
  onward case. BOTH ship.

## 2026-09-05 — step 2: F-R1-1 FIX implemented (both halves), building
* `LoopLowering.cpp` `invariantRegisterRoots` — clause **(ii-b)**: a CONTROL-OWNED MERGE
  OUT-RAIL (`taint.ControlOwnedRails` membership AND a structural `cqrt_alloc_`-prefixed
  producer) is admitted as a Root beside the `cq_theta` root mint, on clause (ii)'s OWN
  proof (`ChainWalk`'s (I1) needs `isTemplateProducer` + a `cq_template_` callee; a
  `cqrt_alloc_<W>` fails both, so no `At` can ever be placed for it). New clause **(iii-b)**:
  such a root may only be READ inside `L` (a VOID `cqrt_*` user inside the loop refuses).
* `LoopPlan.h` / `LoopLowering.cpp` — `collapseFlattenedLoopRails` gains an optional
  `AlreadyProcessed` snapshot; the ONWARD pass processes only loops the ROUND-2 flatten opened.
* `TaintPropagation.cpp` `repropagateControlMerges` — snapshot `InLoopFlattenedPreds` at
  entry, call `collapseFlattenedLoopRails(M, taint, &Round1FlattenedPreds)` at the END (after
  the yn71 fixpoint + the re-run escape/stale nets, before `deleteGlobalPhases`). Wired INSIDE
  `repropagateControlMerges` (not at the two `CQLoweringPass` call sites) so BOTH entry points
  get it; the `runOnFunction` shim's absence of the ROUND-1 call is PRE-EXISTING (8h7d.5) and
  recorded, not repaired.
* Read `$SP/progress/review_r2_R2.md` in full (orchestrator message) — F-R2-1..11 queued after
  F-R1-1/F-R1-2.

## 2026-09-05 — step 3: BOTH fixes MEASURED (subj = `$SP/wt/fix-r1` @ 20:45 build; before = main @ c4bd888)
### F-R1-1
| probe | main (before) | subj (after) |
|---|---|---|
| `p/o_onward_inloop.c` (+`j1_lib.c`) vs `_unrolled` | 34 vs 40 lines, `and_unc` **0** vs 3 | **BYTE-IDENTICAL, 40 lines each**, 3/3 |
| `p/s1_selectmerge_inloop.c` (4.4 select merge, ROUND 1) | 3 / **0** / 4 | 3 / **3** / 7 |
| `p/s2_switchmux_inloop.c` (4.5 switch data-mux, ROUND 1) | 3 / **0** / 5 | 3 / **3** / 8 |
| `p/o_onward_inloop_ctrl.c` (R1's discriminating control — the loop reads the ROOT `q`) | 3 unc | 3 unc, unchanged |
| `p/o_onward_inloop_interf.c` (R1's interference witness) | 0 unc, records live at the `cqrt_ry` | **3 unc**, 41 lines |
| `p/q1_hoisted_temp.c` ⭐ **THE DISCRIMINATING CONTROL** (Q-R1-1's hoisted `cq_template_mul` rail) | 3 / **0** | **3 / 0 — STILL REFUSED**, byte-identical to main |
STRICT stage 2b PASS on every one (`0 violation(s), 0 unproven`).
### F-R1-2
| probe | main (before) | subj (after) |
|---|---|---|
| `p/g_abort_uncond_phase.c` (UNCONDITIONAL phase after an abort park) | **rc 1** `phase-class value escaping` | **rc 0, 8 lines, BYTE-IDENTICAL to `g_abort_nophase`** — D2 deletes it |
| `p/g_classguard_abort.c` (CLASSICALLY-guarded phase after the park) | **rc 1**, same string | **rc 0**, BYTE-IDENTICAL to `g_abort_nophase` |
| `p/g_abort_phase_before.c` | rc 0 | rc 0, unchanged |
| `p/ga_branchphase_gt.c` ⭐ **THE DISCRIMINATOR I had to construct** — `if (q>7) cq_phi(.75); if (q==5) abort();`, a GENUINE branch phase reaching the park | rc 1 | **rc 1, STILL DECLINES** `phase-class value escaping under quantum control` |
| `g_classguard` / `g_classloop` / `g_uncond_after` (R1 CLEAR item 6) | rc 0, 7 lines | unchanged |
⚠ R1's own `p/g_abort_branchphase.c` is NOT a usable discriminator: `clang -O1` folds
`if(q==7)…; if(q==5) abort();` into ONE `switch` with an abort case, so it declines earlier at
`control flow under quantum control` and never reaches the carrier. `ga_branchphase_gt.c` uses
`q>7` (unfoldable) and does reach it — measured on both binaries.
`p/g_abort_uncond_phase.c` on subj is also BYTE-IDENTICAL to the ROUND-1 SUBJECT's trace.

## 2026-09-05 — step 4: commit 7cfd88c (F-R1-1 + F-R1-2), then the R2 fixture/doc batch
* MUTATION-VALIDATED the two halves of F-R1-1 SEPARATELY (3 build+lit cycles,
  `$SP/progress/fix_r2_mutate.log`): (B) onward call deleted → `..._onward_inloop.ll` FAILS,
  `..._inloop_merge_rail.ll` PASSES; (A) clause (ii-b) disabled → BOTH FAIL; restored → all PASS.
  `..._inloop_reject_hoisted_temp.ll` and `..._inloop_derived_cond.ll` green in ALL THREE.
* lit on my binary after the code fixes: **1665 discovered / 396 FAILED**; the red set is
  ENTIRELY inside the 493-file retired-`@cq_phi_<sfx>` set (`comm -23` empty), i.e. **0 new
  reds** vs the 396 R2 measured at c4bd888.
* Read `$SP/progress/review_r2_R2.md` in full and applied F-R2-1..8 + the orchestrator's F-B2-2.

## 2026-09-05 — step 5: the R2 fixture/doc batch + the orchestrator's F-B2-2
* **F-R2-1** (systemic). MECHANICAL repair over EVERY accept of the branch
  (`$SP/progress/fix_r2_work/repair.py`, counts derived from each fixture's OWN pass output):
  the complement Rz negative in 18 files that enumerated six of eight widths (or one),
  `cqrt_x` assertions in 21 (blanket negative where the stream has none, `XCNT-COUNT-n` where
  it does), `cqrt_free` assertions in ~21, a `cqrt_cswap` negative where missing.
* **F-R2-2 / F-R1-3** SIX emission sites, enumerated per site with its pinning fixture, in
  `ChainWalk.h` and in the notes. MEASURED: 6 `markBranchPhaseGate` calls / 6 `CreateCall(Rz`
  expressions / 4 files / 5 emitters.
* **F-R1-4** `preservesBorrowedParent` clause (1) row added to the closure table + a note at
  the site (`Uncomputation.cpp:591`) saying the verdict is SOUND and must not be narrowed.
* **F-R1-5 / F-R2-5** metadata reason (3) restated as a property; 19-in-6 → **22 in 7**
  (my measurement; R2 said 21/7 — the residue is one adjacent pair of calls, stated).
* **F-R2-3** two fixture headers' "BROKEN MODULE at `opt` exit 0" → exit 134 (SIGABRT).
* **F-R2-4** four e2e citations marked "on branch `3qlq-inc1-slices` (prep-b)"; the
  63-of-66-slices-fail-stage-1 measurement is now stated where the claim is made.
* **F-R2-6** `control_phase_switch_reject_default_body.ll` → `..._default_edge.ll` (git mv),
  retitled to the cause it actually discriminates, with the mutation recorded.
* **F-R2-7** `MDCNT`/`MDTAG` + the `, !cq.branchphase` suffix on the two flagship P2 accepts
  (and the third), so the `AngleSelectEmit` stem is pinned by 3 files, not 1.
* **F-R2-8** `control_phase_kickback_onward_merge.ll` gains the full negative set AND an
  ordered `CHECK` chain for the ROUND-1 6.5 region that shares its function.
* **F-R2-9** 19 prose lines in 18 files that parse as directives under a naive scanner
  (`; MEASURED:`, `; DROPPED:` …) rewritten to `; MEASURED —` etc.
* **F-B2-2** (orchestrator hand-off) an explicit Q+Q-condition decline in the CONTROL layer:
  `kQQCondReason` = `quantum-quantum compare condition`, asked per LEAF before any emission
  in `classifyPhaseKickback` AND in P4's nest ladder; P5 exempt STRUCTURALLY (its flags are
  `scrutinee == <ConstantInt>`). Replaces three spellings across two layers. Fixtures
  `..._reject_qq_compare.ll` / `..._reject_tree_qq_leaf.ll` re-pointed (+ `CHECK-NOT: no
  template for opcode`), new `control_phase_nest_reject_qq_leaf.ll`. All three red on main.

### INJECTION MATRIX (R2's own harness, repointed at my worktree; 40 accepts × 16 mutations)
| mutation | MISSED before the repair (R2 @ c4bd888) | MISSED after (mine) |
|---|---|---|
| `clean` (Control A) | 0 dirty | **0 dirty, 40/40 pass** |
| `knownbad` (Control B, delete the forward gate) | caught 33/33 applicable | **0 MISSED** |
| `cqrt_rz_f80` / `f16` | 18 / 18 | **0 / 0** |
| `cqrt_rz_i16` | 3 | **0** |
| extra `cqrt_free` | 20 | **0** |
| unpaired `cqrt_x` | 21 | **0** |
| extra `cqrt_cswap` | 2 | **0** |
| drop `!cq.branchphase` | 22 of 35 | **0** (20 accepts gained `MDCNT`/`MDTAG`) |
| `cqrt_rz_<W>_controlled` after the region | 3 | **0** (a `@cqrt_rz_{{[a-z0-9]+}}_controlled(` negative in the 3 files that legitimately emit `cqrt_copy_*_controlled`) |
| an extra `cqrt_rz_i1` after the last free | 1 | **0** (an `ACNT` count on the hoisted-temp control) |
| a surviving `call void @cq_phi(` | 1 | **0** (a `SWEPT-NOT` on the decl-only family fixture) |

# ============================ HAND-BACK (fix_r2) ============================

## 1. What shipped
Branch `3qlq-inc1-fix-r1` in `$SP/wt/fix-r1`, **4 commits** on top of `c4bd888`:
```
7cfd88c F-R1-1 (both halves) + F-R1-2 + the F-R1-3/4/5 doc truth
87eec37 the ROUND-2 fixture/doc batch (F-R2-1..9, F-R1-3/4/5) and F-B2-2
3efc40a docs: RETIRE_SWAP_ROUTE_INC1_NOTES.md §2 + the injection table + the stage table
6a3a125 docs: the onward loop-rail pass can DECLINE too
```
**60 files changed, +2746 / −202** (`git diff --stat c4bd888..HEAD`).
**Source/headers (7):** `ChainWalk.h`, `LoopPlan.h`, `TaintPropagation.{h,cpp}`,
`ArmClassify.cpp`, `LoopLowering.cpp`, `Uncomputation.cpp`.
**Fixtures: +5 ADDED, 1 RENAMED, ~48 MODIFIED.**
Added: `control_phase_kickback_onward_inloop.ll`, `control_phase_kickback_inloop_merge_rail.ll`,
`control_phase_kickback_abort_global_phase.ll`,
`control_phase_kickback_reject_abort_branch_phase.ll`, `control_phase_nest_reject_qq_leaf.ll`.
Renamed: `control_phase_switch_reject_default_body.ll` → `..._default_edge.ll`.
**Docs:** `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 (394 new lines: one section per finding, the
injection-matrix table, the **"what else runs once before round 2"** stage table, 3 owner questions).

## 2. What I ran (only what I ran)
* `lit ir-pass/test` from `$SP/wt/fix-r1/build`, FINAL: **1666 discovered · 396 FAILED**
  (`$SP/progress/fix_r2_lit_Z.log`). The red set is the SAME 396 FILES as before my fixture
  batch and **all 396 are inside the 493-file retired-`@cq_phi_<sfx>` set** — 0 new reds,
  0 newly green vs the 396 R2 measured at `c4bd888`.
* `ctest -R 'frontend-lit|runtime|cq-opt-equivalence' -j6` → **9/9 passed**, 23.4 s.
* **The injection matrix** (`$SP/progress/fix_r2_work/inj.py` = R2's own harness repointed at
  my worktree, + 6 injections of mine), **40 accepts × 16 mutations**:
  **0 MISSED, 0 DIRTY, clean 40/40.** Before/after table in `$SP/progress/fix_r2_work/`
  (`inj_after.tsv` = the intermediate state, `inj_final.tsv` = final).
* **STRICT stage 2b** (no `--allow-unproven`) on every accepting subject output:
  **53 outputs, 0 violation(s)**.
* **3 build+lit MUTATION cycles** validating the two halves of F-R1-1 separately.
* ~95 plain-C / hand-IR reproducers through the full pipeline on the subject and on main
  (`$SP/progress/fix_r2_work/{run.sh,multi.sh}`).
* R1's CLEAR item 10 re-run: `k2`/`k4`/`k2r`/`kg` rolled == unrolled IDENTICAL; `k32` differs
  only by the frontend canonicalization R1 recorded; **every rolled trace byte-identical to
  main's** — the clause-(ii-b) widening changed nothing that already worked.
* **NOT run**: the full `ctest` (Rule 19 — the orchestrator's gate), `e2e-loop-twin-matrix`
  (I changed no matrix file), any e2e slice (63 of 66 `cq_phi` slices do not compile on this
  branch — F-R2-4).

## 3. Per-finding status
| finding | grade | status | pinned by |
|---|---|---|---|
| F-R1-1 | CONFIRMED rolled≠unrolled | **FIXED, both halves** (clause (ii-b) + the onward pass) | `..._onward_inloop.ll` (round-2 half) + `..._inloop_merge_rail.ll` (round-1 half), mutation-validated separately; control `..._inloop_reject_hoisted_temp.ll` still refuses |
| F-R1-2 | OVER-DECLINE (plain C) + false "LATENT" claim | **FIXED** (`controlDependentOnTaintedBranch`, returning-paths post-dominance) | `..._abort_global_phase.ll` (accept) + `..._reject_abort_branch_phase.ll` (decline) |
| F-R1-3 / F-R2-2 | doc (THREE vs SIX emission sites) | **FIXED**, enumerated per site with its pinning fixture | the 6 MDTAG/CHECK-suffix fixtures |
| F-R1-4 | doc (the closure table's missing row) | **FIXED** (row + a note at `Uncomputation.cpp:591`) | — |
| F-R1-5 | doc (metadata reason (3) unreachable) | **FIXED** (restated as a property) | — |
| F-R1-6 | OVER-DECLINE, pre-existing | recorded → **OWNER QUESTION Q-R2-2** | — |
| F-R2-1 | SYSTEMIC fixture truth | **FIXED** mechanically over all 40 accepts, injection-validated | the matrix (0 MISSED) |
| F-R2-3 | doc (exit 0 vs 134) | **FIXED** (2 headers) | — |
| F-R2-4 | doc (absent e2e witnesses) | **FIXED** (4 citations + the notes) | — |
| F-R2-5 | doc (19-in-6) | **FIXED** → 22 in 7, measured | — |
| F-R2-6 | fixture truth (name ≠ cause) | **FIXED** (renamed `..._default_edge.ll`, mutation recorded) | itself |
| F-R2-7 | fixture truth (one file pinned a whole stem) | **FIXED** (3 P2 accepts, + 20 more) | MDCNT/MDTAG in 23 files |
| F-R2-8 | fixture truth (weakest accept) | **FIXED** (full negatives + the round-1 region's CHECK chain) | itself |
| F-R2-9 | informational (prose parses as directives) | **FIXED** (19 lines, 18 files) | — |
| F-R2-10 / F-R2-11 | informational | not changed (R2 grades both inert / true-but-imprecise); F-R2-11's precise reading is now in the MD banner text | — |
| F-B2-2 | Rule-1 third path (opcode-layer decline) | **FIXED** (`kQQCondReason` in the control layer, P1 + P4; P5 exempt structurally) | `..._reject_qq_compare.ll`, `..._reject_tree_qq_leaf.ll`, `control_phase_nest_reject_qq_leaf.ll` |

## 4. OWNER QUESTIONS (full text in the notes §2)
* **Q-R2-1** the round-1 marking is never re-verified under round-2 taint (`markIfRailLocal`
  only GRANTS; neither call unmarks). Bounded by construction, no measured customer; making
  it exact needs an UNMARK scoped to the blocks this stage marked, because
  `IterationLocalBlocks` is shared with the Case-B owner.
* **Q-R2-2** at ROUND 1 `detectSpecializations` pre-empts D2 entirely (R1's F-R1-6):
  a global phase inside a specialization candidate is REFUSED where D2 says DELETE. Not a
  regression (matches `fa96336` and the oracle).
* **Q-R2-3** two stages before the round-2 fixpoint are not re-run and both OVER-DECLINE,
  MEASURED: `lowerControlledIOSinks` (`p/z1_onward_io.c` → `control flow under quantum
  control`; the round-1 twin `p/z3_io_flat.c` ACCEPTS) and `lowerLoops`
  (`p/z2_onward_loopexit.c` → `nested control flow under quantum control`). Owed the same
  treatment `collapseFlattenedLoopRails` just got, or ruled exotic?

## 5. What is left
1. The **34 → 396 red fixtures** are prep-a's migration set, unchanged by this round.
2. **No e2e witness exists on this branch** for anything Inc 1 lowers (F-R2-4): 63 of 66
   `cq_phi` slices fail stage 1 against the register-free `CQ.h`. prep-b's
   `3qlq-inc1-slices` must land before the epic's commit, and the moment it does, stage 2b
   should be re-run over the kickback slices — R2 measured that it DOES catch the
   dropped-strip / extra-free / unpaired-`cqrt_x` classes on the nest and switch shapes.
3. **Point round 3 at the "what else runs once before round 2" table.** Two rounds have now
   each found one instance of that class (F-L3-1, F-R1-1) and the 1666-fixture suite found
   neither. The three residuals in that table are all in the DECLINE direction and are
   Q-R2-3.
