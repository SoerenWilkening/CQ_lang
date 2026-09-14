# Track P — GATES.md

Format (PROTOCOL): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <time>`
A gate result is a fact about a BINARY. Before running a gate, read this file; if
the hash is unchanged and the gate is recorded, CITE the line, do not re-run it.

ORACLE (read-only, frozen): `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
sha256 `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`,
`libCQPass.so` `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`
— VERIFIED byte-for-byte against PROTOCOL.md before the first measurement.

SUBJECT builds:
* `f7b65d8ccd7bc472` — the worktree BASELINE (no edits yet). Bit-identical to the
  ORACLE, which is the control that the worktree toolchain reproduces it exactly.
* `da71bba00e2ff033` — the Track P implementation.

| gate | binary | result | who | when |
|---|---|---|---|---|
| `cmake --build build -j8` (BOTH targets) | `f7b65d8ccd7bc472` | baseline, bit-identical to the ORACLE | impl | 2026-09-14 09:5x |
| `cmake --build build -j8` (BOTH targets) | `da71bba00e2ff033` | first implementation build, exit 0 | impl | 2026-09-14 10:2x |
| `ctest -R ir-pass-lit` | `da71bba00e2ff033` | **1 FAILED** — `control_phase_kickback_reject_bare_i1_loop_phi.ll` (bd `boi6`): a SHIPPED DISCRIMINATOR silently re-labelled `branch phase on a bare i1 condition` -> `control flow`, disposition unchanged. 1943 passed, 1 XFAIL. Fixed by reproducing `collectCondTree`'s `IsCondTree` string split inside step 5c | impl | 2026-09-14 10:3x |
| `cmake --build build -j8` (BOTH targets) | `2c5c8febc49288f7` | string-partition fix, exit 0 | impl | 2026-09-14 10:4x |
| `ctest -R ir-pass-lit` | `2c5c8febc49288f7` | `1/1 Test #8: ir-pass-lit .... Passed 262.70 sec` (box under heavy concurrent agent load — `load averages: 395`); `ls ir-pass/test/*.ll \| wc -l` = 1945 at that moment | impl | 2026-09-14 10:5x |
| `cmake --build build -j8` (COUNTERFACTUAL: `RegionFlatten`'s `isCondRailPhiShape` conjunct reverted) | `b0eec07ebe4d9e25` | exit 0 | impl | 2026-09-14 11:0x |
| counterfactual measurement | `b0eec07ebe4d9e25` | **NEGATIVE** — all three φ accepts lower BYTE-IDENTICALLY, exit 0, clean under `libgmalloc`. The guard still has NO SUBJECT; the claim that this increment gave it one would have been false | impl | 2026-09-14 11:0x |
| `cmake --build build -j8` (source RESTORED) | `2c5c8febc49288f7` | **hash returns to the pre-counterfactual value** — the revert is bit-exact | impl | 2026-09-14 11:1x |
| `lit --filter` per fixture (14 new + the flipped one) | `2c5c8febc49288f7` | each green as written; the whole `mergephi` family 38/38 | impl | 2026-09-14 10:3x-11:1x |
| `ctest -R '^e2e-slice-control-phase-mergephi'` (4 new slices) | `2c5c8febc49288f7`* | 4/4 Passed, STRICT stage 2b on each | impl | 2026-09-14 10:5x |
| `vacuity_p.py` over the new accepts | `2c5c8febc49288f7` | 10 fixtures, 85 negative patterns checked for path collision (0 bad), 0 named handles (0 vacuous) | impl | 2026-09-14 10:5x |
| `ctest -R '^e2e-slice-control-phase-mergephi'` (4 new slices) | `2c5c8febc49288f7` | **4/4 Passed**, STRICT stage 2b on each (20/25/17/9 trace lines) | impl | 2026-09-14 11:2x |
| `ctest -R` the MUST-NOT-MOVE slices (cascade family incl. `_base`=`va` 19 and `_int` 28, the two in-loop ones, `…-inplace-ry-stateprep-bool{,-negated}`, `…-stateprep-bool-under-int-compare-fused`) | `2c5c8febc49288f7` | **9/9 Passed** | impl | 2026-09-14 11:2x |
| targeted byte-compare, `control_peel_*` + `control_inplace_ry_*` | ORACLE vs `2c5c8febc49288f7` | **288 files, 0 differ** | impl | 2026-09-14 11:2x |
| targeted byte-compare, `control_swap_*select*` | ORACLE vs `2c5c8febc49288f7` | **149 files, 2 differ** — both are this increment's intended bd `4aiu` accepts | impl | 2026-09-14 11:3x |
| `inject_p.py` (11 mutations x 12 accept fixtures) | `2c5c8febc49288f7` | **97 applied, 0 MISSED, 35 N/A** (structural absences, enumerated in IMPL_P §8) | impl | 2026-09-14 11:0x |
| injection-harness CONTROL (unmutated IR vs every prefix) | `2c5c8febc49288f7` | **69 (fixture, prefix) pairs, 0 failures** — a 0-MISSED run is not trusted without this | impl | 2026-09-14 11:1x |
| **`ctest -R ir-pass-lit` — THE HAND-OFF RUN, every fixture in place** | `2c5c8febc49288f7` | **1/1 Passed** (Passed  193.42 sec); `ls ir-pass/test/*.ll \| wc -l` = 1946. Box at `load averages: 588` — contention causes false FAILURES, never false passes, so a green here stands; the TIMING does not compare with a quiet-box figure | impl | 2026-09-14 11:0x |
| corpus sweep ORACLE-vs-SUBJECT (fixtures + probes), **STOPPED at 1434 / 269 rows** | `2c5c8febc49288f7` | **2 movers: F-P1** `control_swap_reject_select_mergephi_tree_leaf.ll` `control flow` -> ACCEPT (the intended bd `4aiu` flip) and **F-P2** `trackL/probes/p1.c` — SAME message, DIFFERENT stderr hash = the φ declines had lost their `!dbg` (Rule 1). Stopped deliberately: the fix requires a relink and CLAUDE.md forbids relinking under a running measurement | impl | 2026-09-14 11:1x |
| `cmake --build build -j8` (F-P2 fix: `PhiAnchor`) | `e942d5fac3a19bc3` | exit 0 — φ-root refusal anchored on `BI` | impl | 2026-09-14 11:2x |
| `cmake --build build -j8` (F-P2 fix extended to the wire decline) | `283e3b3322a9a94c` | exit 0 — `PhiAnchor` == `declAnchor(Region)` for every compare/rail shape | impl | 2026-09-14 11:3x |
| `trackL/probes/p1.c` stderr byte-compare | ORACLE vs `283e3b3322a9a94c` | **IDENTICAL** — the regression is closed at the byte level, not merely at the string | impl | 2026-09-14 11:3x |
| `lit --filter 'mergephi\|bare_i1_loop_phi\|rail_after_prep\|phase_kickback_rail'` | `283e3b3322a9a94c` | **61/61 Passed** | impl | 2026-09-14 11:3x |
| `ctest -R ir-pass-lit` — **THE HAND-OFF RUN, post-F-P2-fix** | `283e3b3322a9a94c` | **1/1 Passed, 146.14 s**, 1946 `.ll` fixtures | impl | 2026-09-14 11:4x |
| targeted post-fix probe sweep (exit + FULL stderr on declines + lowered IR on accepts), 362 probes | ORACLE vs `283e3b3322a9a94c` | **18 movers, 18 ATTRIBUTABLE, 0 unattributable** — 16 Track P probes, plus `session-boi6/probes/p14.c` (bd `3qps`'s customer in its original spelling) now ACCEPT and `session-boi6/probes/p5.c` (bd `drbq.7`'s chained arm) string-moved with the same location and the same disposition. `trackL/probes/p1.c` is NOT a mover — F-P2 closed | impl | 2026-09-14 11:5x |
| corpus sweep, `ir-pass/test` half, post-fix | `283e3b3322a9a94c` | **NOT COMPLETED** — box at `load averages: 574`, ~3 rows/min. Stands on `ir-pass-lit` (green, 1946, strictly stronger for that corpus) + the §10 byte-compares. ⚠ Neither covers a diagnostic's LOCATION; the merge-and-gate agent's sweep on the merged binary must be run and read | impl | 2026-09-14 11:5x |
| `ctest -R` the 4 new slices + the must-not-move cascade/stateprep ones | `283e3b3322a9a94c` | **6/6 Passed** (re-run at the FINAL binary) | impl | 2026-09-14 11:5x |
| `inject_p.py` (11 mutations x 12 accept fixtures) | `283e3b3322a9a94c` | **97 applied, 0 MISSED, 35 N/A** — re-run at the final binary, identical | impl | 2026-09-14 11:5x |
| `vacuity_p.py` | `283e3b3322a9a94c` | 12 fixtures, **101 negative patterns**, 0 path collisions, 0 vacuous names | impl | 2026-09-14 11:5x |

## Rule-13 ROUND-1 FIX (2026-09-14, fix agent) — the binary DID NOT MOVE

The fix touched **comments, records and one new fixture only**. `cmake --build build -j8` (BOTH targets)
reproduces `cq-opt` **`283e3b3322a9a94c206eb94471e519e5c9e4ffd60c0917743519ae895a0b2daf`** and
`libCQPass.so` **`fa563f6941280d3d1dc181116b380621e4bc63108f366f09826a9af004d931c5`** — bit-identical to
the implementation tip `98951fa1` and to the binary `REVIEW_P_R1.md` cleared. **Every gate line above
therefore still cites correctly**, and round 1's CLEAR-WITH-ITEMS verdict transfers unchanged.

| gate | binary | result | who | when |
|---|---|---|---|---|
| `cmake --build build -j8` (BOTH targets), after the comment/record/fixture edits | `283e3b3322a9a94c` | **BIT-IDENTICAL** — `cq-opt` `283e3b33…a0b2daf`, `libCQPass.so` `fa563f69…04d931c5`. A comment-only edit that moved the binary would have been a FINDING; it did not | fix R1 | 2026-09-14 12:3x |
| `cq-opt` on the new fixture's module, SUBJECT | `283e3b3322a9a94c` | exit 0; 21-gate stream **byte-equal to review probe `r08`'s trace** | fix R1 | 2026-09-14 12:2x |
| `cq-opt` on the same module, frozen ORACLE | `f7b65d8ccd7bc472` | **exit 1**, `cq controlled lowering: control flow under quantum control` — the red-green half (Rule 12) | fix R1 | 2026-09-14 12:2x |
| `tools/free_pairing_check.py` on that lowered IR | `283e3b3322a9a94c` | STRICT: `4 rail mint(s) of which 3 left allocated, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven` | fix R1 | 2026-09-14 12:2x |
| `lit ir-pass/test --filter 'mergephi_tree_leaf_data_use'` | `283e3b3322a9a94c` | **1/1 PASS**, 0.49 s; Total Discovered 1947 | fix R1 | 2026-09-14 12:3x |
| `ctest --test-dir build -R ir-pass-lit` | `283e3b3322a9a94c` | **1/1 Passed, 56.94 s** — box QUIET (`load averages: 4.47 / 16.54 / 52.55`), so this timing IS comparable with a quiet-box figure, unlike every earlier lit line in this file | fix R1 | 2026-09-14 12:4x |
| `lit ir-pass/test` (full, for the counts) | `283e3b3322a9a94c` | **Total Discovered 1947 · 1946 Passed · 1 Expectedly Failed**, 91.55 s | fix R1 | 2026-09-14 12:4x |

NOT RUN by the fix agent (forbidden by the fix brief; no subset substitutes for any of them):
the corpus sweep, the full `ctest`, `^e2e-`, `cq-opt-equivalence`, the loop twin matrix.
⚠ The `ir-pass/test` half of the corpus sweep is **still not completed at this binary** — unchanged from
the line above; it remains owed to the merge-and-gate agent, and it is the only instrument in the matrix
that can see a **diagnostic's LOCATION**.
