# MERGE — `main` 7203d1c (Track A.1) into `merge-phi-peel` (bd `test_C_libtooling-b6ap`)

Merge-and-gate record. Worktree `/Users/sorenwilkening/Desktop/CQ_b6ap`, branch
`merge-phi-peel`. First parent `25984cc` (the b6ap round-2 PRE-LANDING
checkpoint), second parent `7203d1c` (the landed Track A.1). Common base for both
branches: `main` `0c7380c`. **Merge commit `cc77815`. NOT PUSHED; `main` untouched.**

Landing order is `LANDING_PLAN.md`'s: A.1 first (it is the fence everything else
builds on), then this branch merged with it, rebuilt and re-gated before its squash.

---

## §1 — Conflicts

**ZERO textual conflicts.** `git merge main` reported
`Auto-merging` on three files and `Automatic merge went well`;
`git diff --name-only --diff-filter=U` was empty.

Auto-merge is not proof, so each of the three was read on both sides and verified
by hand. The two branches touch **exactly three files in common**:

| file | A.1's change | b6ap's change | overlap? | resolution |
|---|---|---|---|---|
| `ir-pass/src/CQLoweringPass.cpp` | `reverifyCmpCondReads` after `reverifyRailCondReads`, both entry points (orig. lines ~429 / ~850) | the peel + `adjudicateTaintDelta` immediately before `detectControlRegions`, both entry points (orig. ~373 / ~837), plus the `foldIdentityBitcasts` `Scrub` argument (~156 / ~712) | **no** — disjoint slots, >7 lines apart in the base | both kept, ORDER verified below |
| `ir-pass/include/TaintPropagation.h` | `TaintSet::CmpCondRead` + `CmpCondReads` **inside `struct TaintSet`** (~:314) | `ArrayRef` include (~:26), `propagateFromSeeds` + `adjudicateTaintDelta` (~:924), `foldIdentityBitcasts` `Scrub` parameter (~:1163) | **no** — struct body vs free-function block | both kept |
| `tests/e2e/CMakeLists.txt` | 6 slices (`slice_control_select_cmp_*`, `slice_control_phase_bool_loop_iterlocal*`) | 2 slices (`slice_control_fused_regions_{int,phase_bool}`) | **no** — different regions of the list | **both groups kept**, verified by name |

Also applied from A.1, with no b6ap counterpart: the deletion of
`ir-pass/test/lowering_live_record_tape_ctrl_observed_accept.ll` (A.1's one
accepted parity over-decline).

`CLAUDE.md` and `ROADMAP.md` were **NOT touched by either track** (measured:
`git diff --name-status 0c7380c <tip> | grep -E 'CLAUDE.md|ROADMAP'` is empty on
both sides), so there were no status paragraphs or count lines to merge here —
those are the orchestrator's at squash time. The counts to use are in §5.

### 1a — the ORDER, which is the thing that had to survive

Both stages are position-critical and they sit on opposite sides of the round-2
fixpoint. Verified by grep on the merged tree:

```
peel + adjudicate   CQLoweringPass.cpp:451/452   ->  detectControlRegions :455    (run)
peel + adjudicate   CQLoweringPass.cpp:938/939   ->  detectControlRegions :942    (runOnFunction)
peel (Delta=null)   TaintPropagation.cpp:1430    ->  detectControlRegions :1431   (round-2 fixpoint)
reverifyRailCondReads :510   reverifyCmpCondReads :519    (run, after the fixpoint)
reverifyRailCondReads :954   reverifyCmpCondReads :957    (runOnFunction)
```

b6ap's grep-checkable RULE — *the peel is called immediately before EVERY
`detectControlRegions` in the tree* — still holds: **3 `detectControlRegions` call
sites, 3 peel calls, one immediately before each.** A.1's stage runs strictly
after the round-2 fixpoint, so the peel's taint growth is already settled when it
re-asks its rungs under FINAL taint; the two are complementary, not competing.

### 1b — the one SEMANTIC interaction the merge creates, checked not assumed

`reverifyCmpCondReads` skips an entry whose whole seed set was nulled, and its
header states the **retirement trigger** verbatim: *"a stage that erases a LIVE
cone member without RAUW-ing it — then this `continue` would be skipping a real
obligation and must become a decline."*

b6ap adds **two new erasers** to the pipeline, both upstream of that stage, so the
trigger had to be checked:

| eraser | RAUW before erase? | evidence |
|---|---|---|
| `peelIndependentMergePhis` (the merge phi) | **yes** | `MergePhiPeel.cpp:525` `Phi->replaceAllUsesWith(Sel)` then `:553` `Phi->eraseFromParent()` |
| `foldIdentityBitcasts` (the identity bitcast) | **yes** | `TaintPropagation.cpp:491` `BC->replaceAllUsesWith(Src)` then `:506` `BC->eraseFromParent()` |

`WeakTrackingVH` FOLLOWS a RAUW, so a cone member that is peeled or folded keeps
its entry and is re-asked on the new value. **The trigger is not tripped.** This
is also measured, not only argued: 0 verdicts moved over 355 probe rows (§4).

---

## §2 — Gate lines, verbatim, on the merged tree

Both targets rebuilt first (`cmake --build build -j8`; `CQPass` **and** `cq-opt`).
The only warnings are the two pre-existing `-Wunused-parameter` in
`TaintPropagation.cpp` (`resolveSources`' `PhiFns`, `deleteGlobalPhases`' `M`),
both present verbatim at `0c7380c` and untouched by either track.

```
$ ctest --test-dir build -R ir-pass-lit --output-on-failure
1/1 Test #8: ir-pass-lit ......................   Passed   89.52 sec
100% tests passed, 0 tests failed out of 1

$ ctest --test-dir build -j6 -R '^e2e-' --output-on-failure
384/384 Test #318: e2e-loop-twin-matrix ..............................   Passed  409.39 sec
100% tests passed, 0 tests failed out of 384
Total Test time (real) = 409.44 sec

$ git status --porcelain tests/          # after the merge commit
                                          (empty)

$ ctest --test-dir build -j6 --output-on-failure
393/394 Test #318: e2e-loop-twin-matrix ..............................   Passed  389.03 sec
394/394 Test   #8: ir-pass-lit .......................................   Passed   58.22 sec
100% tests passed, 0 tests failed out of 394
Total Test time (real) = 404.15 sec

$ cmake --build build --target cq-opt-equivalence-full
cq_opt_equivalence: compared 1851 fixtures, 0 mismatch(es)
```

Before the merge commit, `git status --porcelain tests/` showed only the 10
STAGED merge additions (`A `/`M ` in the index column, worktree column blank) —
i.e. **no golden was regenerated by any run**. After the commit it is empty.

`e2e-loop-twin-matrix` passing matters here specifically: b6ap modified
`tools/loop_twin_matrix.expected.txt`, and that gate is the only instrument that
can see a leaked template-minted rail.

---

## §3 — Method for the corpus re-runs

The committed runners hardcode `ROOT`/`SUBJ` and several write their
intermediates back into the probe directories, whose `.s1.ll` / `.o.ll` / `.s.ll`
artefacts are **tracked**. Running them in place would have dirtied the worktree,
so:

* `review_b6ap_r2_probes/sweep.sh` was used as-is — it writes only to a `mktemp -d`
  and its `SUBJ` already points at this worktree, which is now the merged tree.
* Everything else was driven from a scratchpad copy; **nothing outside
  `$TMPDIR`/scratchpad was written.**

The comparison is against **each track's own pre-merge binary**, which is stronger
than the recorded READMEs (it is a binary A/B, not a prose cross-check):

* **B6PRE** — `25984cc` extracted with `git archive` into scratchpad (no repo
  writes at all) and built there: `cmake --build build --target CQPass cq-opt -j8`.
* **A1PRE** — `/Users/sorenwilkening/Desktop/CQ_trackA/build/ir-pass`, still on disk.
* **ORACLE** — `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass` at `0c7380c`,
  read-only, never rebuilt.
* **MERGED** — this worktree's build.

The recorded sweep baselines were diffed too, as a second, independent check.

---

## §4 — Corpus verdicts: NO VERDICT MOVED

### 4a. b6ap corpora — MERGED vs **b6ap pre-merge**

| corpus | rows | MERGED != B6PRE |
|---|---|---|
| `session-b6ap/probes` | 50 | **0** |
| `session-b6ap/review_b6ap_r1_probes` | 38 | **0** |
| `session-b6ap/review_b6ap_r2_probes` | 63 | **0** |
| `session-b6ap/review_b6ap_r2_probes/auto` | 93 | **0** |
| **total** | **244** | **0** |

Against the recorded baselines, independently:

* `sweep_implprobes.txt` (47 rows) vs the merged sweep (50 rows): **0 differences
  on the 47 common rows**; the 3 extra are `S02`/`S03`/`S04`, copied into
  `probes/` by the round-2 review *after* that baseline was written — exactly the
  `+3` `FIX_b6ap_R2.md` §(sweep table) predicts — and each matches its recorded
  SUBJECT verdict (`S02` `operand predates a non-diagonal gate`, `S03` ACCEPT
  (bd `3d8q`, pre-existing), `S04` ACCEPT).
* `sweep_r1probes.txt` (38 rows): **byte-identical.**

The peel's own contract — *"produce the module the hand peel already is"* — still
holds: `z08_threepred` and hand-peeled `z12_z08_handpeeled` lower to a
**byte-identical instruction stream** (the only diff is `ModuleID`/`source_filename`
and z08's unused `@g` declaration, which exists only in its input).

### 4b. A.1 corpora — MERGED vs **A.1 pre-merge**

| corpus | rows | MERGED != A1PRE |
|---|---|---|
| `session-9pum/probes` | 20 | **0** |
| `session-9pum/review_a1_r1_probes` | 23 | **0** |
| `session-9pum/review_a1_r2_probes` (+ `multi/`) | 68 | **0** |
| **total** | **111** | **0** |

Every row also matches the SUBJECT column recorded in `session-9pum/probes/README.md`
(`r10v`, `r903b`, `9pum` and `d1`–`d4` declining; `a1`–`a7`, `k10`, `sw1`
accepting; `sw2` declining; `ip1`/`ip3` pre-empted by `cq loop lowering`).

**Grand total: 355 probe rows, 0 verdicts moved.**

### 4c. Both capabilities are LIVE in the merge (the check that a merge can hide)

Zero movement against each track's own binary is necessary but not sufficient —
it is also what you would see if one track's code had been silently dropped. So
the converse was measured:

* **The peel is live.** Of the 244 b6ap rows, **132 differ from the A.1-only
  binary** — and they are exactly the 132 rows where B6PRE differs from A1PRE.
  Example: `p09_owner_int` is `control flow` on A1PRE and **ACCEPT** on MERGED.
* **A.1's fences are live.** Its three headline plain-C silent miscompiles:

| probe | ORACLE 0c7380c | b6ap pre-merge | **MERGED** |
|---|---|---|---|
| `r10v` | ACCEPT (rc 0) | ACCEPT (rc 0) | **DECLINE** `condition measured before the control route` |
| `r903b` | ACCEPT (rc 0) | ACCEPT (rc 0) | **DECLINE** `condition measured before the control route` |
| `9pum` (2 TUs) | ACCEPT (rc 0) | ACCEPT (rc 0) | **DECLINE** `condition predates a non-diagonal gate` |

---

## §5 — The owner's file, and the counts

`scratchpad/owner_file_2026-09-11.c` (the `example/grover/grover_oracle_uncompute.c`
snapshot), through `clang -O1` + the merged `build/ir-pass/cq-opt`:

**(a) as written (`bool b0` / `bool b1`) — exit 1**, as expected (bd `l4x4.b` is
not merged yet):

```
CQ_CTRL_DBG: decline [bare i1 register condition] at:
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
error: <unknown>:0:0: in function main i32 ():
  cq controlled lowering: bare i1 register condition under quantum control
```

The anchor is `b0`'s `cq_theta_i1`, i.e. the **PREP ARM** — the second of the
file's three walls, exactly where `IMPL_b6ap.md` §6 records it. The 2-phi wall
(this increment's) is gone.

**(b) `int b0` / `int b1` — exit 0, ACCEPT, 22 trace lines**, stage 2b
`0 violation(s), 0 unproven`, and the trace is **byte-identical to the committed
`tests/e2e/slice_control_fused_regions_int.expected.log`**.

### Counts, by command, on the merged tree

```
$ ls ir-pass/test/*.ll | wc -l              1851     (A.1 1813 + b6ap 38)
$ ls tests/e2e/*.expected.log | wc -l        347     (A.1  345 + b6ap  2)
$ ctest --test-dir build -N | tail -1        Total Tests: 394   (A.1 392 + b6ap 2)
$ ctest --test-dir build -N -R '^e2e-'       Total Tests: 384
$ ctest --test-dir build -N -R '^e2e-slice-' Total Tests: 345
```

`1851` is corroborated independently by `cq-opt-equivalence-full`
("compared 1851 fixtures"). All three totals are exactly additive — the merge
neither dropped nor duplicated a fixture, a golden or a ctest entry.

---

## §6 — Findings

**None.** No verdict moved on any of the 355 probe rows; no gate is red; no
golden churned; the retirement trigger A.1 documents is not tripped by either of
b6ap's new erasers.

Two things are worth carrying to the squash, neither a defect of this merge:

1. `S03_stale_mux_sibling` accepts and emits one register where the source names
   two. That is bd `test_C_libtooling-3d8q`, **pre-existing** — `S04` reproduces
   it with no peel anywhere, on the ORACLE — and A.1 does not close it (it is the
   `cq_theta`/`cq_measure` reader of a stale name, which the pass-wide
   stale-record guard never asks about because it sweeps PURE ops only).
2. `sw1.ll` still accepts on the merged binary: the 4.5 `switch` mints its
   eq-flags through `emitEqFlag`, which has no `CmpInst`, so neither A.1's new
   rung nor `CmpCondReads` reaches it. Recorded by A.1 as F-A1-4 / bd
   `test_C_libtooling-lo7u`, unchanged here.
