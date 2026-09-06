# docs_c1c — record-truth fixes from lens review_c1c (F-C1C-B/E/F) + counts

Agent `docs_c1c`. Worktree `$SP/wt/fix-c1` (branch `3qlq-inc1-fix-c1`, base tip dec2019).
`.md` files and source COMMENTS only. ONE commit. No full ctest, no push, no bd edits.

## Log
- 2026-09-06 step 0: read BRIEF_common.md, BRIEF_docs_c1c.md, review_c1c.md (F-C1C-B/E/F in
  full + the log), fix_c1c.md steps 6/6b/14/15. Worktree verified at dec2019.
- step 1: counts MEASURED in the worktree (commands + results):
  `ls ir-pass/test/*.ll | wc -l` -> **1673**;
  `ctest -N | grep -c '^  Test *#'` -> **348**; `-R '^e2e-'` -> **338**; `-R '^e2e-slice-'` -> **308**;
  `grep -c '^m_' tools/loop_twin_matrix.expected.txt` -> **257**;
  `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` -> **29** (257+29 = **286** cells);
  `ls tests/e2e/*.expected.log | wc -l` -> **310**.
  `grep -rn 'Tainted\.insert(' ir-pass/src | wc -l` -> **37**, of which 2 are PROSE
  (`DagTraversal.cpp:127`, `LoopLowering.cpp:2922`) -> **35 code sites** (F-C1C-E confirmed by me).
- step 2 (notes §3.11): F-C1C-B scope sentence REPLACED (their fences prove the RAIL, not the
  IMMEDIATE; the class reaches the LOOP writers for the xor stem from plain C, PRE-EXISTING on
  the oracle, bd test_C_libtooling-eqpx); F-C1C-E population headline corrected (6 in scope +
  `w3` by design; the lens's 299-corpus 286/13 added); `35 sites` -> `37 lines of which 2 prose,
  35 code sites` in BOTH notes places.
- step 3 (notes §3.12 APPENDED): "what the round-3 lens found outside the round's scope" — the
  F-C1C-B reproducer, its 5-binary trace, the population table, the root cause, the proposed
  fix, and the two DOC findings.
- step 4 (source COMMENTS): `ir-pass/src/OpcodeLowering.cpp` (the scope comment above the
  tripwire) and `ir-pass/include/TaintPropagation.h` (`PreLoopCommittedInPlaceOps` paragraph)
  both retract the "their own fences" bound and point at bd eqpx / notes §3.12;
  `TaintPropagation.h`'s `ClaimedRailRoots` paragraph gains the F-C1C-F sentence (MISS vs
  RECYCLE direction); `ir-pass/src/LoopLowering.cpp` fence comment's `35 sites` becomes
  "37 lines, 2 prose, 35 code sites". NO code touched.
- step 5 (CLAUDE.md): C-1 bullet extended (seven over five rounds, two introduced by a fix,
  plus one pre-existing found in passing = bd eqpx; the retired bounding sentence; lens 3
  CLEAR-WITH-ITEMS, re-clearance pending, nothing landed); the `# 348 ctest entries` block
  gains the re-measured counts + the three-round status; the matrix paragraph and the
  `ir-pass-lit` line note round 3 moved no cell and the re-measured 1673.
- step 6 (ROADMAP.md): the "6 programs and no others" bound corrected (+ the lens's 299/286/13),
  the eqpx clause, and the three-round / CLEAR-WITH-ITEMS / re-clearance-pending status.
- step 7 (PRD): status header = three rounds + lens CLEAR-WITH-ITEMS + re-clearance pending;
  §0 shipping-status line the same; E2 gains the F-C1C-B / eqpx and F-C1C-E paragraph.
- step 8 (notes §2 ⭐ table): a ROW for the other three `InPlaceRailOps` writers (the table's
  own instruction), and "FOUR defects now answer yes" -> four inside the epic + a fifth from
  before it.
- step 9 (REBUILD #1, log `docs_c1c_build2.log`/`docs_c1c_build.log`): `cmake --build build -j8`,
  BOTH targets (`Built target CQPass`, `Built target cq-opt`), `BUILD_EXIT=0`.
- step 10 (WITNESS #1, on the rebuilt binary): `lit -s ir-pass/test` -> **1673 discovered ·
  1672 Passed · 1 Expectedly Failed · 0 unexpected failures**, 35.63 s, exit 0;
  `ctest -R '^e2e-slice-control-phase-perbit-loop-mixed$'` -> **1/1 Passed, 1.36 s**, exit 0.
- step 11: one 110-char comment line reflowed in `LoopLowering.cpp` -> REBUILD #2 + re-run of
  both witnesses (log `docs_c1c_build2.log`).
- step 12 (REBUILD #2 + FINAL WITNESSES, log `docs_c1c_build2.log`):
  `cmake --build build -j8` -> `Built target CQPass` + `Built target cq-opt`, **BUILD_EXIT=0**;
  `find ir-pass/src ir-pass/include ir-pass/tools -newer build/ir-pass/cq-opt` -> **EMPTY**
  (the binary is current with the comment edits);
  `lit -s ir-pass/test` -> **1673 discovered · 1672 Passed · 1 Expectedly Failed · 0 unexpected
  failures · 37.20 s**, LIT_EXIT=0;
  `ctest -R '^e2e-slice-control-phase-perbit-loop-mixed$'` -> **1/1 Passed, 0.97 s**, CTEST_EXIT=0.
- step 13: `git diff -- ir-pass` re-checked for non-comment added/removed lines -> **NONE**
  (`grep -vE '^[+-]\s*(//|\*|/\*)'` over the diff is empty). Code is byte-unchanged.

---

## HAND-BACK

### 1 — what shipped
ONE commit on branch `3qlq-inc1-fix-c1`: **`da743dc`**
`docs(control): 3qlq — record-truth fixes from lens review_c1c (F-C1C-B/E/F) + counts`
(7 files, +282/-38 at the pre-final-nit stat; `git status` clean after commit).
* `docs/prd/.../RETIRE_SWAP_ROUTE_INC1_NOTES.md` — §3.11's scope sentence RETRACTED and
  replaced; §3.11's population headline corrected (6 in scope + `w3` by design, plus the
  lens's 299-corpus 286/13/0); `35 sites` -> `37 lines, 2 prose, 35 CODE sites` in both
  places; NEW **§3.12** (F-C1C-B: reproducer, 5-binary trace, population table, root cause,
  proposed fix, and the two DOC findings); §2's ⭐ once-only-stage table gains a ROW for the
  other three `InPlaceRailOps` writers and "FOUR defects answer yes" -> four inside the epic
  + a fifth from before it.
* `ir-pass/src/OpcodeLowering.cpp` — the tripwire's scope COMMENT retracts the same sentence
  and points at bd eqpx / §3.12 (comment only).
* `ir-pass/include/TaintPropagation.h` — `PreLoopCommittedInPlaceOps` paragraph the same;
  `ClaimedRailRoots` paragraph gains the F-C1C-F MISS-vs-RECYCLE sentence (comments only).
* `ir-pass/src/LoopLowering.cpp` — the (1a) fence comment's `35 sites` corrected + one
  110-char line reflowed (comment only).
* `CLAUDE.md` — C-1 bullet extended (the count as it is + the retired bounding sentence +
  lens 3 CLEAR-WITH-ITEMS + re-clearance pending + nothing landed); the `# 348 ctest entries`
  block gains the re-measured counts and the three-round status; the `ir-pass-lit` line and
  the matrix paragraph note round 3 moved no cell and the re-measured numbers.
* `ROADMAP.md` — the "6 programs and no others" bound corrected, the eqpx clause added, and
  the three-round / CLEAR-WITH-ITEMS / re-clearance-pending status.
* `docs/prd/.../retire-swap-route-PRD.md` — Status header + §0 shipping status = three rounds,
  lens CLEAR-WITH-ITEMS, re-clearance pending, NOT landed; E2 gains the F-C1C-B/eqpx and
  F-C1C-E paragraph (explicitly "do NOT fold it into the seven").

### 2 — what I ran (nothing else; no full ctest, no push, no bd write)
* `cmake --build build -j8` twice -> `Built target CQPass` + `Built target cq-opt`, exit 0.
* `find ir-pass/src ir-pass/include ir-pass/tools -newer build/ir-pass/cq-opt` -> EMPTY.
* `lit -s ir-pass/test` -> **1673 discovered · 1672 Passed · 1 Expectedly Failed · 0
  unexpected failures · 37.20 s**, exit 0.
* `ctest -R '^e2e-slice-control-phase-perbit-loop-mixed$'` -> **1/1 Passed, 0.97 s**, exit 0.
* COUNTS: `ls ir-pass/test/*.ll | wc -l` **1673** · `ctest -N` **348** / `^e2e-` **338** /
  `^e2e-slice-` **308** · `grep -c '^m_' tools/loop_twin_matrix.expected.txt` **257** ·
  `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` **29** (= **286** cells) ·
  `ls tests/e2e/*.expected.log | wc -l` **310** ·
  `grep -rn 'Tainted\.insert(' ir-pass/src | wc -l` **37**, 2 prose -> **35 code sites**.
* CODE-UNCHANGED PROOF: `git diff -- ir-pass` filtered to non-comment +/- lines -> **0 lines**.

### 3 — findings that are NOT mine to decide
None new. The one carried forward is bd `test_C_libtooling-eqpx` (F-C1C-B), already filed by
the orchestrator and recorded here; it is PRE-EXISTING and out of this epic's scope.

### 4 — what is left
The re-clearance. Nothing on this branch is landed, and no doc I touched says otherwise.
