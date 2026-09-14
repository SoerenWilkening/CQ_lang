# MERGE-AND-GATE brief — session 2026-09-14. ONE GROUP, ONE FULL SUITE.

You are the **only** full-`ctest` runner of this session (PROTOCOL §matrix + §S1). Six branches, all
transitively sharing files under `ir-pass/`, so per §S1 they are **one GROUP and get ONE combined gate** —
not one gate per landing. Expect this to be the session's only full suite.

Work in a FRESH worktree you create off `main`:
`git worktree add -b merge-gate-2026-09-14 ../CQ_merge main`. Never write in any track's worktree, never in
the main checkout's `build/` (the frozen ORACLE `cq-opt f7b65d8ccd7bc472…`, `libCQPass.so f9e898badfd4207a…`).

## The branches, in SQUASH ORDER (merge in this order too)

| # | track | bd | branch | tip | its binary |
|---|---|---|---|---|---|
| 1 | **T** | `uq96` | `twin-matrix-bool` | `b360bc79` | == ORACLE (no pass source) |
| 2 | **U** | `z9t1` | `undef-seed-zero` | `4e7ef89f` | `a5773be142835fb8…` |
| 3 | **F** | `om35` | `f2-phi-descendant` | `5537b6c9` | `96fdd3a9d2c1cd36…` |
| 4 | **P** | `3qps`+`4aiu` | `mergephi-phase-leaf` | `ff3d210d` | `283e3b3322a9a94c…` |
| 5 | **W** | `wx8g` | `inloop-bool-prep` | `85a94c9d` | `d47297cfe72e7fa3…` |
| 6 | **D** | `3d8q` | `stale-reader-fence` | `e509e418` | `4394b3495c1c539f…` |

T first because its widened 338-cell twin matrix is the instrument that must witness W's code. U early
because its normalizer runs before classification and changes what F and P see.

## Procedure

1. Merge all six into the merge worktree **in the order above**, one at a time. Record every conflict and
   how you resolved it. `tests/e2e/CMakeLists.txt` is append-only at disjoint anchors and merged cleanly
   three times last session — if it conflicts, that is a FINDING worth reporting, not a routine resolve.
2. `cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release` then
   `cmake --build build -j8`. **Never `--target CQPass` alone** — false-green trap. Record `shasum -a 256`
   of both artefacts; that hash keys every line you write.
3. **Duplicate-body scan (L8) — MANDATORY, this merge renames and inverts fixtures.** Tracks P, D, F and W
   each `git mv`'d or inverted at least one. A merge can resurrect a `git mv`'d fixture, giving one module
   two names with contradictory verdicts, invisible to every review that ran before the merge. Use Track F's
   committed `dupscan.py`; note it gives different counts under different comment/blank normalisations
   (7/9/6/8 were all reconciled at 1938) — **report the normalisation you used and check for
   CONTRADICTORY-VERDICT groups, which is the property that matters, not the count.**
4. **The full `ctest -j6`.** One run. `-j12` oversubscribes. Contention causes false FAILURES, never false
   passes — re-run any failure serially BEFORE calling it a regression.
5. **`cq-opt-equivalence-full`.** OWED by U (analysis sites moved), F (analysis site), D (a decline string
   **and** an analysis site) and W. Not optional.
6. **ONE corpus sweep on the merged binary**, and this is where the session's sweep debt is repaid: two
   tracks' own sweeps did not finish under load and were closed by tail arguments. **Read it for DIAGNOSTIC
   LOCATIONS as well as verdicts** — a lost `!dbg` is invisible to every other gate (Track P's F-P2 shipped
   past a green 1946-fixture lit run, a 0-MISSED matrix and a byte-identical 288-file family). Attribute
   every mover to a track BY STRING; **an unattributable mover is a FINDING.**
7. **The widened twin matrix** (338 cells, ~464 s) over the merged tree. Track W predicted eight
   loop-message rows flip to `ACCEPT-IDENTICAL`; ⚠ `m_none_ddilry_none_none_binv` is predicted **unmoved**
   (it dies at gate 2c before the loop clause) and `m_none_dilesc_none_none_binv` is predicted **unmoved**
   (a move there means clause (c3) is gone). Compare against those predictions and say whether each held.
   **Never `--regenerate` to turn a red green.**

## THE CROSS-TRACK COMPOSITIONS — run these by name; no track's own gate can see them

Full detail in `GATES.md`. Summary:

* **X1** `trackF/review_r1_probes/p9_undef_seed.ll` — ORACLE declines at **F1, before F2**; on the merged
  binary Track U's normalizer turns it into Track F's accept fixture byte-for-byte, so expect
  **DECLINE(F1) → ACCEPT**. Also run the **undef spelling of each Track-F customer**.
* **X2** Track U hands F2 a seed population containing **normalized zeros F2 never saw at HEAD** — Track F's
  φ-descendant conjunct must be exercised with **both** changes present.
* **X3** `trackF/review_r2_probes/r7_mbeta_base_offcone.ll` and `r12_mbeta_ifelse_rechain.ll` must stay
  **DECLINE** — the only tripwires anywhere for the M-β RAUW-target invariant.
* **X4** `trackF/review_r2_probes/r5_round2_phidesc.ll` ACCEPT + control `r5c` DECLINE.
* **X5 (NEW, from Track F's landed retirement trigger):** Track F's φ-descendant narrowing names **bd
  `wx8g` BY NAME** as the reason its back-edge shape is unreachable — **and `wx8g` LANDS IN THIS MERGE**.
  That trigger fires here. Run Track F's `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll`
  on the MERGED binary and report whether either moves; if the back-edge shape becomes reachable, say so
  loudly — it is the one composition this session created by design and did not measure.

## Reporting

Write `$SES/MERGE_REPORT.md` and append every gate line to `$SES/GATES.md`, hash-keyed, `ran:`/`cited:`.
Report: the merged tip, the binary hashes, every conflict, the duplicate-scan verdict, the full-suite
result, the equivalence result, the corpus movers attributed per track, the twin-matrix result against
Track W's predictions, and X1–X5 each with its measured verdict. Re-measure the counts the closing pass
needs: `ctest --test-dir build -N`, `ls ir-pass/test/*.ll | wc -l`, `ls tests/e2e/*.expected.log | wc -l`,
and the twin-matrix `grep -c` lines.

**Do not squash and do not push** — the orchestrator does that. If the gate goes red, do NOT fall back to
per-track gates: bisect by reverting one branch's merge in the same worktree (§S1).


## ⚠ TWO THINGS TRACK W'S LAST ROUND ADDS TO YOUR JOB

* **Its cited corpus sweep is THREE BINARY MOVES STALE** (`95a33b2e`). Track W says so itself. Your one
  sweep is therefore the only sweep that has ever seen its final code — treat every Track-W row as
  unaudited until your sweep prints it.
* **Track W's binary moved AFTER its round-2 clearance** (`40edde36` → `d47297cf`), by three code edits:
  a `declAnchor` located-anchor fallback + the shared `anchorIsLocated`, an `isa<BinaryOperator>` narrowing
  of the `InPlaceRailOps` exclusion, and conjunct 1 switching to `anchorIsLocated`. All three are
  decline-direction or diagnostic-only, which is why the orchestrator accepted them without a further
  round — **your full suite and sweep are the verification of that judgement**, so report anything from
  Track W's files with extra prominence.


## ⚠ TRACK D'S BINARY ALSO MOVED AFTER ITS ROUND-2 CLEARANCE

`0f3d5125` → `4394b349`, and unlike Track W's this one is **ACCEPT-DIRECTION**: a new leg 1b
(`readerRunsAtMostOncePerActivation`, 8 clauses, file-local and deliberately un-exported) that admits a
reader whose own BLOCK runs once inside a loop. It closes an over-decline round 2 found. The implementer
re-measured 105 probes against the real prior binary and got exactly 2 movers, both intended, with 47
accepting probes byte-identical.

**A narrow round-3 review is running against that leg in parallel with you.** Do not wait for it. If it
returns a finding, the orchestrator will fix and ask you to re-run only what the finding touches — which is
why you should record your gate lines granularly enough that a partial re-run is possible.

Also note: an intermediate Track-D binary `6480de5f` exists in that track's record marked **VOID** (the leg
without one clause). Nothing is cited from it; if you see it referenced anywhere, that is a stale citation
and a FINDING.
