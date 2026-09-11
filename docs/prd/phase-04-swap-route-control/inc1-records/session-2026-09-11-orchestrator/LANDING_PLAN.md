# Landing plan — session 2026-09-11 (`01NHxGVinGBKbb499HFCuwhT`), four tracks, sequential

Owner rulings this session: expressiveness first; option 1 (compare-select parity fences, then widenings);
H-3 = admit; the `i1` state-prep decline reversed (no `int b1`, no new `cq_*`). Customer:
`example/grover/grover_oracle_uncompute.c` (snapshot `scratchpad/owner_file_2026-09-11.c`), whose walls
are b6ap → l4x4.b → F2.

## Order and why

1. **A.1** (`compare-select-parity`, worktree `../CQ_trackA`) — decline-only fences; base 0c7380c; two
   Rule-13 rounds (r1 BLOCK → fixed; r2 CLEAR-WITH-ITEMS → items applied). Lands FIRST because it is the
   fence everything else builds on.
2. **b6ap** (`merge-phi-peel`, `../CQ_b6ap`) — base 0c7380c; r1 BLOCK → fixed; r2 CLEAR-WITH-ITEMS → items
   applied. Must be MERGED with the landed A.1 (shared `CQLoweringPass.cpp`, `TaintPropagation`), rebuilt
   and re-gated before its squash.
3. **F2** (`f2-condwire-narrowing`, `../CQ_f2`, checkpoint 1419b5e) — base 0c7380c; r1 CLEAR-WITH-ITEMS →
   applied. Merge with landed A.1 + b6ap (shared `ArmClassify.cpp`), rebuild, re-gate, squash.
4. **l4x4.b** (`l4x4b-bool-ry-arm`, `../CQ_l4x4`) — base = F2 checkpoint 578dbc4; r1 CLEAR-WITH-ITEMS →
   applied. Merge with landed main (A.1 + b6ap + F2), rebuild, re-gate, squash.
5. Primary checkout: rebuild BOTH targets, full `ctest -j6`, `cq-opt-equivalence-full`, re-run the owner's
   file (`./tools/show_pipeline.sh example/grover/grover_oracle_uncompute.c`) — it MUST compile; record the
   trace in this dir.

## Per-landing procedure (one opus agent per merge-and-gate; the squash commit is the orchestrator's)

In the track's worktree: `git merge main` (resolve conflicts by READING both sides — never by taking one
side wholesale; every conflict in `ir-pass/src` is listed in the report with the resolution and the
reason); `cmake --build build -j8` (both targets); `ctest --test-dir build -R ir-pass-lit`; `ctest
--test-dir build -j6 -R '^e2e-'`; the FULL `ctest --test-dir build -j6` (mandatory: Rule-13 core + a
merge); `cmake --build build --target cq-opt-equivalence-full`; the track's own probe corpora and the
previous tracks' review corpora re-run on the merged binary (every verdict listed — a verdict that moves
across the merge is a FINDING, reported before the squash, not after); the owner's file measured. Report
the gate lines verbatim, counts (lit / goldens / ctest), conflicts, movers. Then the orchestrator squashes:
`git -C CQ_lang checkout main && git merge --squash <branch> && git commit` with the tip hash, the
verdicts, the counts and the record paths in the message; `git log main -1` becomes the record's landing
hash (CLAUDE.md, PRD, bd, memory). The primary `build/` stays the 0c7380c ORACLE until step 5 — every A/B
measurement in flight depends on it; it is rebuilt exactly once, at the end.

## After landing

`bd close` the landed increments' issues (9pum, r10v; b6ap; the drbq.14 note; l4x4 partial — l4x4.a/c
remain) and the "closed by A.1" I/O-sink issue; `bd remember` per increment; CLAUDE.md status paragraphs
(each track wrote its own — merge them, re-measure the counts by command); ROADMAP; lab-report entry 004
(`tools/labreport/build.py --seal`); `git pull --rebase && git push`; `NEXT_SESSION_PROMPT.md` in this dir.
