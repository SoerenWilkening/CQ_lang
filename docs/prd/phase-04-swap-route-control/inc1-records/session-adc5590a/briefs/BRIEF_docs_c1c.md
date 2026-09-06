# BRIEF_docs_c1c — record-truth fixes from lens review_c1c (F-C1C-B sentences, F-C1C-E, F-C1C-F) + counts, before the re-clearance
Read `$SP/briefs/BRIEF_common.md`, then `$SP/progress/review_c1c.md` findings F-C1C-B, F-C1C-E, F-C1C-F IN FULL, and
`$SP/progress/fix_c1c.md` §3.11-related steps. Agent name: `docs_c1c`. Model: opus. Work in `$SP/wt/fix-c1`
(branch `3qlq-inc1-fix-c1`, tip dec2019). You may edit `.md` files AND source COMMENTS only (no code, no fixture,
no tool, no golden). Because a comment edit changes a source mtime, you MUST rebuild at the end
(`cmake --build build -j8`, BOTH targets, in the background with a log) so the binary is current again, and then
prove behaviour did not move: `sha256` of `build/ir-pass/libCQPass.so` before/after may differ (timestamps), so
instead run `cd build && lit -q ir-pass/test` (background, ~45 s) → 0 failures + the standing XFAIL, and ONE e2e
slice (`ctest --test-dir build -R '^e2e-slice-control-phase-perbit-loop-mixed$'`). Report both.

## Edits
1. **F-C1C-B — two false record sentences.** (a) `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.11 and (b) the source
   comment(s) in `ir-pass/include/TaintPropagation.h` and/or `ir-pass/src/OpcodeLowering.cpp` (~:300) that say
   the other three `InPlaceRailOps` writers "mark a rail they PROVED with their own fences" (and review_c1b's
   scope sentence "the class as measured is introduced by `commitOutOfLoopInPlaceOps`", wherever the notes
   repeat it). Correct them: their fences prove the RAIL; none proves the IMMEDIATE stays classical; the
   identical defect is reachable through the LOOP writers for the `xor` stem from plain C, PRE-EXISTING on the
   pre-3qlq oracle (F-C1C-B; reproducer `c1c_m_xor_and_noregion.c`; the trace line
   `cqrt_xorc_i32(h1, 6)` with `6` = h6's handle id; STRICT 2b blind), filed as bd
   `test_C_libtooling-eqpx` with the proposed fix (re-ask G2 at `lowerOps` for every member, decline loudly).
   Add a §3.12 "what the round-3 lens found outside the round's scope" paragraph in the notes with exactly that.
2. **F-C1C-E**: notes §3.11's population headline "differ on 6 programs and no others" → "6 in the F-C1B-1 / (1a)
   / F-C1C-1 scope, plus `w3` by design (the F-C1B-2 revert)"; and "35 sites" → keep 35 but say the grep returns
   37 lines, two of them prose.
3. **F-C1C-F**: `TaintPropagation.h`'s `ClaimedRailRoots` paragraph gains ONE sentence: the "a mis-key can only
   ever REFUSE" claim covers the MISS direction; the RECYCLE direction (root address AND header address both
   recycled to matching live values) is the retirement trigger, and `RegionFlatten` erases ARM/MERGE blocks
   between the writers and the round-2 reader, never a header in any measured shape.
4. **Counts/status** (measure by command in the worktree, as `BRIEF_docs_c1.md` did): lit corpus (expect 1673),
   ctest entries / `^e2e-` / `^e2e-slice-` (expect 348 / 338 / 308), matrix rows/cells (257 / 286), goldens.
   Update the dated lines in CLAUDE.md (the `# 3xx ctest entries` chain, the `ir-pass-lit` fixture count, the
   matrix paragraph) and ROADMAP.md / PRD status header so they say: three C-1 rounds on `3qlq-inc1-fix-c1`
   (round 1 the capability, round 2 two more members + a miscompile of its own, round 3 the narrowing), lens 3
   CLEAR-WITH-ITEMS, re-clearance pending. Do NOT say landed.
5. The `CLAUDE.md` C-1 sentence: extend by one clause naming the count "seven findings over five adversarial
   rounds on one function, two of them introduced by a fix, plus one pre-existing of the same class found in
   passing (bd eqpx)".
ONE commit `docs(control): 3qlq — record-truth fixes from lens review_c1c (F-C1C-B/E/F) + counts`. Hand back:
the commit hash, the lit/slice results after the rebuild, and the measured counts.
