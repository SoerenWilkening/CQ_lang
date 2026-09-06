# BRIEF_rebase_c1d — REBASE C-1 round 4 (branch `c1-round4` @ 59f6a95, bd 7yd0) onto `main` (258d974 + the docs
# commit b99b853), re-run its gates, fold in the lens items F-C1D-2/3/4, re-measure `q4b`, prepare the landing
Read `$SP/briefs/BRIEF_common.md` FIRST. Then, from the repo (all on `main`):
`docs/prd/phase-04-swap-route-control/inc1-records/session-adc5590a/c1-round4/fix_c1d.md` (round 4, IN FULL — it is
the record of what your branch contains), `.../c1-round4/review_c1d.md` (the lens; verdict CLEAR-WITH-ITEMS; its
items F-C1D-1..4 are YOUR work list below), `.../briefs/BRIEF_fix_c1d.md` and `.../briefs/BRIEF_rebase_c1d.md` (the
session-2 versions — this brief supersedes the second), `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.14 (on YOUR branch; main
does not have it yet), `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §4.1 (F-I2-1 — the customer) and §5, PRD §0 E11/E12, and the
code: `ir-pass/src/LoopLowering.cpp` `commitOutOfLoopInPlaceOps`, `ir-pass/src/OpcodeLowering.cpp`'s tripwire
(`PreLoopCommittedInPlaceOps` re-ask, string `cq loop lowering: pre-loop in-place op no longer provable at lowering`),
`ir-pass/src/ArithLowering.cpp` `classifyInPlaceReassignment` (G2/G4/G5/G6/G7) and its new "CONSUMER 2" comment (Inc 2).
Agent name: `rebase_c1d`. Model: opus. Progress file `$SP/progress/rebase_c1d.md`. Work dir `$SP/progress/rebase_c1d_work/`.

## Worktree — YOURS for this task
`$SP1/wt/c1d`, branch `c1-round4` at **59f6a95** (10 commits on a3c1513; built, current). The pre-rebase binary is
already frozen at `$SP/bin/c1d-59f6a95/`. PRE-FIX for every red-green in this task = **main's binary** (258d974, the
leak is LIVE there — review_c1d F-C1D-1: `q4b` 4/0 52 vs 4/4 60, `q5sel` 4/0 44 vs 4/4 52, `g1` 3/0 36 vs 3/3 42).

## Step 1 — the rebase (record a conflict table in your progress file)
`cd $SP1/wt/c1d && git rebase main`. MEASURED overlap between `git diff --name-only a3c1513 c1-round4` and
`git diff --name-only a3c1513 main` is EXACTLY five files: `CLAUDE.md`, `ROADMAP.md`,
`docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md`, `tests/e2e/CMakeLists.txt`, and
`.../session-adc5590a/briefs/BRIEF_fix_c1d.md` (add/add — both copies of one file; keep main's). Resolve docs by INTENT:
both landings (Inc 1 a3c1513, Inc 2 258d974) are history; round 4 is "landing on `main` after the rebase onto 258d974".
`tests/e2e/CMakeLists.txt`: keep BOTH added blocks (Inc 2's value slices/gates AND round 4's merge-preadd pair + gate).
**`ir-pass/src/LoopLowering.cpp`, `tools/loop_twin_matrix.{py,expected.txt}` and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` must
NOT conflict** (main did not touch them since a3c1513) — if any does, STOP and report.
Duplicate record file: your branch adds `session-adc5590a/fix_c1d.md`; main already has the same report at
`session-adc5590a/c1-round4/fix_c1d.md` (the later copy, with the build-currency addendum). `diff` them; keep main's
path, `git rm` the branch's duplicate, and fix any cross-reference that pointed at the old path.
The reproducer dir `inc1-records/c1-round4/` (23 files + README) is YOURS and does not exist on main — keep it. Note
that main ALSO carries `inc2-records/q4b_preadd_*.c`, `q5sel_preadd_*.c` etc. (Inc 2's copies of the same reproducers);
that duplication is acceptable — cross-reference it in `inc1-records/c1-round4/README.md`, do not delete either.
After the rebase: `git log --oneline main..HEAD` (expect 10 commits, or 9 if a docs commit became empty), and
`git diff main HEAD --stat -- ir-pass/src` must show ONLY `LoopLowering.cpp` (+ whatever step 3 adds).

## Step 2 — rebuild + the round's own gates on the rebased binary
Rebuild BOTH targets (background, `$SP/progress/rebase_c1d_build1.log`); confirm `find ... -newer` EMPTY. Then:
1. the two round-4 lit accepts (`lit --filter 'control_phase_kickback_mixed_merge_out_rail_preadd_inloop'` and
   `'..._preheader_addc_after_region_inloop'`) + the round-3 tripwire decline `control_phase_kickback_reject_preloop_commit_stale`;
2. `ctest -R ir-pass-lit` (background) → green but the 1 XFAIL; record the discovered count;
3. `ctest -j6 -R 'twin-identical|quarantine-selftest|free-pairing-selftest|perbit|onward-perbit|merge-preadd|e2e-slice-control-value'`
   (this includes the FOUR Inc-2 value twin gates `e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical` and all
   9 Inc-2 value slices — F-C1D-2's "re-run on the rebased tree");
4. `lit --filter 'control_swap_value_ifelse_head_out_of_place'` explicitly (F-C1D-2), and `lit --filter 'control_swap_value'`;
5. the twin matrix in the BACKGROUND (`ctest -R e2e-loop-twin-matrix`, ~4–7 min): **no cell may move** — the committed
   `tools/loop_twin_matrix.expected.txt` has 259 rows (257 + sub-grid F4's 2) and the quarantine 29 cells; if any cell
   moves, that is a FINDING — report it, do not regenerate.

## Step 3 — RE-MEASURE `q4b` (the Inc-2 value-merge + preadd spelling) — the one thing round 4 could only argue
Sources: `inc1-records/c1-round4/q4b_preadd_{rolled,unrolled}.c` (same files at `$SP1/progress/review_inc2_r2_work/p/`).
On main's binary (258d974) the lens measured rolled **4/0, 52 lines** vs unrolled **4/4, 60** (DIVERGE 8). On YOUR
rebased binary it MUST be **4/4 = 4/4, `cmp` IDENTICAL 60 = 60**, and the trace must show the chain HEAD (`p+3`) OUT of
place (`cq_template_add_i32_hl`, because `p` is read by the merge) and exactly ONE in-place `cqrt_addc_i32(<out>, 7)`
(the preadd on the out-rail). Also confirm on the ORACLE 52d7764 (`$SP0/wt/pre-3qlq`) for the record (it routes;
whatever it does, record it). If rolled ≠ unrolled on your binary, THAT IS A FINDING — stop this step, write it under
`## OWNER QUESTION` with the two traces, and continue with the other steps.
If IDENTICAL: pin it —
* lit ACCEPT `ir-pass/test/control_phase_kickback_mixed_value_merge_preadd_inloop.ll`, derived from the `-O1` stage-1 of
  `q4b_preadd_rolled.c` and asserted from YOUR binary's output; RED on main's binary (`$SP/bin/main-258d974/` or the
  main checkout — the merge-out-rail fixture's red/green script `$SP1/progress/fix_c1d_work/rg.sh` is the model; copy
  and re-point it). Prefix conventions EXACTLY as `control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll`
  (one `%cq-opt ... > %t.cqd0.ll` spawn; CHECK / ACNT / MDCNT / NOROUTE whole-file pure-negative / PCNT / XCNT / FCNT /
  UCNT-COUNT-4, handle names DERIVED from the pass output) PLUS this fixture's own F-C1D-2 pin: a `PCNT` block asserting
  `cqrt_addc_i32` count == 1 and a `HCNT` (or similar) block asserting `cq_template_add_i32_hl` count for the hoisted
  chain head — i.e. **the commit did NOT reach the Inc-2 chain head** (Inc 2's ArithLowering CONSUMER-2 comment: G6/G7
  is the sole net there because `Q` always has a second user). Header: which finding (F-I2-1 / F-C1D-1 / F-C1D-2),
  main's counts, yours.
* e2e pair `tests/e2e/slice_control_phase_perbit_loop_value_merge_preadd{,_unrolled}.c` + goldens by the FULL pipeline
  on your binary, STRICT 2b `0 violation(s), 0 unproven` on both, byte-identical to each other; register both slices +
  the `cmp` gate `e2e-phase-perbit-loop-value-merge-preadd-twin-identical` in `tests/e2e/CMakeLists.txt` next to the
  merge-preadd block, with a header comment in the same style (main's counts 52 vs 60 → yours 60 = 60).
  `ctest -j6 -R 'value-merge-preadd'` → 3/3.

## Step 4 — the lens items (each red-green or measured; F-C1D-1 is the rebase itself)
* **F-C1D-2** (beyond the fixture above): in `LoopLowering.cpp`'s in-source argument at the commit site, add the
  paragraph "why the commit cannot reach an Inc-2 chain head" (the head is a USER of `Q`, never an ancestor on the peel
  chain from a loop-invariant candidate; a merge `%out`'s peel stops at its own `cqrt_alloc`, not a `GateCalls`
  member), and cross-reference it from `ArithLowering.cpp`'s CONSUMER-2 comment (one sentence, naming the new fixture).
  Comments only in ArithLowering — NO code change there.
* **F-C1D-3** — three refinements to notes §3.14's 8h7d.5 closure table (on your branch, ~line 2047–2064), each
  VERIFIED on the rebased tree before you write it (quote `file:line`):
  (1) the fan-out row: "arithmetically unchanged" is complete ONLY because a committed op can never have been
  `OutOfPlace` — `railValueConsumerDisposition` returns `OutOfPlace` exactly when `blockCanRepeat(BO->getParent())`,
  and `inPlaceFenceHolds`' G5 refuses precisely that, so the commit cannot mark a repeatable-block op; without G5 the
  widening WOULD add an `InPlaceUser` and could mint a new `kMsgRailFanout` decline;
  (2) the `WireWalk` row: its reason is NOT "the stage runs before `lowerLoops`" — that is FALSE for
  `declineLiftedStaleRecordOps`, the second `declineStaleRecordOps` call (find its line in `CQLoweringPass.cpp`, the
  lens read `:522`), which runs AFTER the commit; the row survives because `WireWalk.cpp` has NO CODE READ of either set
  (its one hit is prose — verify with `grep -n`);
  (3) the row the table lacks — the F-3 question itself: when the gate set widens, what OTHER set is computed over the
  same closure? `staleRailRecordRead`'s SKIP set, which is the CHAIN, built with `peelInPlaceStep(…, AsLowered=false)`
  (the shape reading, which crosses a dtzb-shaped BO regardless of membership) — so the widening grows the gate set and
  the record set (both decline-ward) and CANNOT shrink the skip set. Verify the `AsLowered=true` call-site count
  (the lens counted 2 of 20: clause (ii)'s peel and `markIfRailLocal::onRail`) and quote it.
* **F-C1D-4** — the injection matrix gains an `extra_ry` row, over EVERY kickback accept. Copy
  `$SP1/progress/fix_c1d_work/inj.py` to `$SP/progress/rebase_c1d_work/inj.py`, re-point `REPO` at `$SP1/wt/c1d`, add
  mutation `extra_ry`: insert `call void @cqrt_ry_i32(i32 <rail>, double 5.000000e-01)` immediately AFTER the flag's
  `cqrt_free` (or before the last `ret` if simpler), `<rail>` = the register the condition reads (the `%out`/root handle
  — read it from the first `and_i32_hl`/`lshr` call's arg-0, falling back to the first `cqrt_alloc` result). Run over
  the accept set `grep -L 'RUN: not' ir-pass/test/control_phase_kickback_*.ll` (27 + the 2 round-4 accepts + the new
  q4b fixture). Expected first run: MISSED on nearly all (the lens: 0 of 25 pin an Ry count). For every MISSED fixture
  add a `RYCNT` prefix — `; RYCNT-COUNT-n: call void @cqrt_ry_` then `; RYCNT-NOT: call void @cqrt_ry_` (n from the
  pass output; n may be 0 → a single `RYCNT-NOT`) — as ONE extra FileCheck RUN line against the existing `%t.cqd0.ll`
  (NO extra `%cq-opt` spawn, per CLAUDE.md). Re-run the matrix to **0 MISSED / 0 DIRTY** over the whole set (all 17
  mutations incl. the new one); record the table. Every touched fixture must stay green on your binary; run
  `lit --filter 'control_phase_kickback'` after. Do NOT touch decline fixtures.
  ⚠ A `COUNT` directive inside the NOROUTE prefix WINDOWS every NOT after it (the Inc-3/Inc-4 recurrence) — keep RYCNT
  its own prefix, never fold it into NOROUTE.

## Step 5 — docs (status flips + counts BY COMMAND) and the record
* Status: every "in flight"/"NOT landed" sentence about round 4 → "landing on `main` after the rebase onto 258d974"
  (CLAUDE.md's C-1 bullet + its ctest/lit count lines, ROADMAP, PRD §0 E12's `7yd0` bullet + E2/E10/E11 where they say
  "not on this branch"/"in flight", notes §3.14, `session-adc5590a/README.md`'s round-4 section and
  `NEXT_SESSION_PROMPT.md`'s state line). Use the precedent wording: "LANDED on `main` 2026-09-06 as ONE squash commit
  (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit
  message; `git log main -1` shows the hash)".
* notes §3.14 gains: the `q4b` measurement (main vs yours vs oracle), the F-C1D-2/3/4 dispositions, and the extra_ry
  matrix table. PRD E11's "the FIX is not on this branch" → landed; E12's `7yd0` bullet → landed.
* Counts measured on your build: `ls ir-pass/test/*.ll | wc -l`, `ctest -N | tail -1`, `-R '^e2e-'`, `-R '^e2e-slice-'`,
  `-R 'twin-identical'`, `ls tests/e2e/*.expected.log | wc -l`, `grep -c '^m_' tools/loop_twin_matrix.expected.txt`,
  `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt`. Update CLAUDE.md/ROADMAP count lines with a dated
  "(re-measured 2026-09-06 after the round-4 rebase: …)" clause, never by arithmetic.
* Your own record: append your full progress file as `inc1-records/session-82e6b530/rebase_c1d.md` and this brief +
  BRIEF_common as `inc1-records/session-82e6b530/briefs/` (mkdir; a README.md of five lines saying what the session is).

## Step 6 — hand back
Commit per step (`wip(c1-round4): …`). Do NOT push, do NOT touch bd, do NOT run the full `ctest`. Final: the conflict
table, the gate table (every command + result), the `q4b` measurement on three binaries, the extra_ry matrix result,
`git log --oneline main..HEAD`, `git diff main HEAD --stat`, and the tip hash. First line of the hand-back = the `q4b`
verdict.
