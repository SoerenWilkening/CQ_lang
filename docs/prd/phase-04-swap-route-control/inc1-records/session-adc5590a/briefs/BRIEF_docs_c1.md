# BRIEF_docs_c1 — the COUNT/STATUS docs pass after the C-1 fix round (docs only, no code, no fixtures)
Read `$SP/briefs/BRIEF_common.md`, then `$SP/progress/fix_c1.md` §1–§2 (what shipped and the measured counts),
then `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 and the PRD §0 ERRATA E2 as rewritten by the fix agent.
Agent name: `docs_c1`. Model: opus. You edit ONLY `.md` files, ONLY in `$SP/wt/fix-c1` (branch `3qlq-inc1-fix-c1`,
tip 3ec40c9). A full `ctest` and a read-only lens are running against that worktree — you must not touch anything
under `ir-pass/`, `tests/`, `tools/`, `include/`, `runtime/`, or `build/`. Commit ONE docs commit at the end,
message prefixed `docs(control): 3qlq — `.

## Every number is MEASURED in the worktree by the command shown, never copied from a hand-back
```
cd $SP/wt/fix-c1
ls ir-pass/test/*.ll | wc -l                                   # lit corpus (fix_c1 says 1660)
ctest --test-dir build -N | grep -c '^  Test'                  # total ctest entries (fix_c1 says 342)
ctest --test-dir build -N | grep -c 'e2e-'                     # ^e2e- (fix_c1 says 332)
ctest --test-dir build -N | grep -c 'e2e-slice-'               # ^e2e-slice- (should be 304)
grep -c '^m_' tools/loop_twin_matrix.expected.txt              # matrix expected rows (fix_c1 says 255)
grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt         # quarantine cells (should still be 29)
ls tests/e2e/*.expected.log | wc -l                             # goldens (304 + 2 = 306?)
grep -c 'twin-identical' tests/e2e/CMakeLists.txt              # the cmp twin gates
git diff --name-status 52d7764 HEAD -- ir-pass/test | awk '{print $1}' | sort | uniq -c   # A/M/D vs the oracle
```
(`ctest -N` needs no build to be fresh; `build/` is configured.) If a number disagrees with fix_c1.md, YOUR
measurement wins and you say so in the commit message.

## What to update (and nothing else)
1. **`CLAUDE.md`** — the Build & Test block: the `# 339 ctest entries (2026-09-05 …` paragraph gains a dated
   line at its TOP: "**342 ctest entries (2026-09-06, the 3qlq C-1 fix round: +2 e2e slices
   `e2e-slice-control-phase-perbit-loop-mixed{,-unrolled}` + 1 `cmp` twin gate
   `e2e-phase-perbit-loop-mixed-twin-identical`; `^e2e-` 329 → 332, `^e2e-slice-` 302 → 304; MEASURED by
   `ctest -N`)** — was 339 …" (keep the 339 paragraph verbatim under it as history, the way the earlier
   "was 327 / was 324 / was 305" chain is written). The `ir-pass-lit` line (`# ONE ctest entry wrapping 1656
   *.ll fixtures …`): 1656 → 1660 with a dated parenthetical "(1660 since the 2026-09-06 C-1 fix round: +4 — the
   C-1 mixed-loop accept, the Q-R1-1 mixed hoisted-template LEAK CONTROL, the B3 decline pin
   `lowering_reject_break_phase_answer_kickback.ll` and its global-phase accept control; measured `ls … | wc -l`)",
   keeping the 1656 sentence's history intact. The twin-matrix paragraph (`> ⚠ THE TWO NUMBERS IN THE PARAGRAPH
   ABOVE ARE 2026-09-04 HISTORY …` → "245 rows … 29 cells … 245 + 29 = the 274 cells the gate runs"): add a
   dated sentence: "**Re-measured 2026-09-06 after the C-1 fix round: 255 expected rows + 29 quarantined = 284
   cells — sub-grid F, the second-CARRIED-register axis (10 cells), the only axis that can see C-1; every one of
   the 245 earlier rows byte-unchanged.**" Also the `1656-fixture suite` mention near line ~1004 ("Two of them
   have now been found by adversarial review and **zero** by the 1656-fixture suite") — make it "three … and
   zero by the 1656-fixture suite (the third, C-1, by the clearance itself)", keeping the number since it is
   the corpus at which they were missed. Do NOT rewrite the fix agent's one-sentence C-1 addition.
2. **`ROADMAP.md`** ~lines 784–789: the "245 rows … 245 + 29 = the 274 cells" sentence gets the same dated
   re-measurement sentence (255 + 29 = 284, sub-grid F). Also find the ROADMAP's 3qlq status lines
   (`grep -n '3qlq' ROADMAP.md`) — wherever it says Inc 0/1 are on branch `3qlq-inc1` NOT on main / clearance
   BLOCK, add a dated line: "2026-09-06: C-1 FIXED on branch `3qlq-inc1-fix-c1` (LoopLowering: the `Collapsed`
   branch also admits invariant root mints; `e2e-phase-perbit-loop-mixed-twin-identical`), one lens + a
   re-clearance pending; landing on main follows the re-clearance verdict." Do NOT claim it landed.
3. **PRD `retire-swap-route-PRD.md`** — the Status header block at the top (the "Shipping status" sentence in
   §0 that says NOT on main, clearance BLOCK on C-1): add the same dated line as ROADMAP's. Lines ~152–163 (E7's
   migration counts `1582 → 1656`, `327 → 339`, `317 → 329`, `293 → 302`) are the Inc-1 measurement and stay
   as written; append ONE sentence at the end of E7: "*(The C-1 fix round of 2026-09-06 then took the corpus
   1656 → 1660, the ctest layer 339 → 342 and `^e2e-` 329 → 332 — E2 and notes §3.)*" E9's "none by the
   1656-fixture suite" — same treatment as CLAUDE.md's ("three … a third instance … the clearance").
4. **`docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/README.md`** (8 lines): add a line
   pointing at the session-2 record directory the orchestrator will create,
   `inc1-records/session-adc5590a/` (fix_c1.md, review_c1.md, clearance2.md, briefs/), "copied at landing".
Nothing else: no `bd` edits, no fixture edits, no `tools/` edits. Hand back the numbers you measured and the
commit hash.
