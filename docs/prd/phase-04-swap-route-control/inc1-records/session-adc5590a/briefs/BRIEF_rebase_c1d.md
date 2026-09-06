# BRIEF_rebase_c1d — REBASE C-1 round 4 (branch `c1-round4`, bd 7yd0) onto the LANDED Inc 2 (`main` = 258d974), re-run its gates, prepare the landing
Read `$SP/briefs/BRIEF_common.md` (MAIN = `main` at 258d974: Inc 0/1/2 landed; its `build/` may still be rebuilding —
see `$SP/progress/main_rebuild2.log`, wait for `BUILD_EXIT=0` before using its binary), `$SP/briefs/BRIEF_fix_c1d.md`,
`$SP/progress/fix_c1d.md`, `$SP/progress/review_c1d.md` (the lens verdict: __VERDICT__), and `$SP/progress/fix_c1d_lens_items.md`
if the orchestrator wrote one (items the lens asked to be folded in before landing). Agent name: `rebase_c1d`. Model: opus.
Worktree `$SP/wt/c1d`, branch `c1-round4` at 59f6a95 (10 commits on a3c1513; built).

## Steps
1. `git rebase main` (258d974). Expected conflicts: docs only — `CLAUDE.md`, `ROADMAP.md`, the PRD §0 ERRATA (E10/E12 vs
   E2's residual list), `RETIRE_SWAP_ROUTE_INC1_NOTES.md` (§3.13/§3.14 vs the Inc-2 landing sentences), `tests/e2e/CMakeLists.txt`
   (both added blocks — keep both), `tools/loop_twin_matrix.{py,expected.txt}` (Inc 2 did not touch them — should be clean).
   `LoopLowering.cpp` should NOT conflict (Inc 2 did not touch it) — if it does, STOP and report. Resolve docs by INTENT:
   both landings are history; round 4 is "in flight → landing now". Record the conflict table.
2. Rebuild (both targets, background). Then: the two round-4 lit fixtures + `ctest -R ir-pass-lit` (background) → green
   but the XFAIL; the merge-preadd slice pair + its twin gate + every `*-twin-identical` gate + the perbit/mixed/value
   slices + `e2e-loop-twin-quarantine-selftest`; the matrix in the background (no cell may move; sub-grid F4 present);
   **re-measure `q4b`** (Inc 2's value-merge + preadd spelling, `$SP/progress/review_inc2_r2_work/p/q4b*.c`) on the
   rebased binary: it must now be rolled == unrolled IDENTICAL (the fix agent could only argue it analytically) — if it
   is, ADD it as a lit accept fixture (`control_phase_kickback_mixed_value_merge_preadd_inloop.ll`, derived from the
   rebased binary's output, red on `main`'s binary once main is rebuilt) and as an e2e pair + `cmp` twin gate
   (`slice_control_phase_perbit_loop_value_merge_preadd{,_unrolled}.c`); if it is NOT, that is a finding — report it,
   do not paper over it.
3. Fold in any lens items the orchestrator listed (`fix_c1d_lens_items.md`), each red-green.
4. Docs: the round-4 status lines → "landing on `main` after the rebase onto 258d974 (Inc 2)"; PRD E12's "in flight"
   clause → the same; counts by command (lit, ctest, matrix); notes §3.14 gains the `q4b` measurement.
5. Commit per step (`wip(c1-round4): …`). Do NOT push, do NOT touch bd. Hand back per BRIEF_common: the conflict
   table, the gate table, the `q4b` measurement, and the tip hash.
