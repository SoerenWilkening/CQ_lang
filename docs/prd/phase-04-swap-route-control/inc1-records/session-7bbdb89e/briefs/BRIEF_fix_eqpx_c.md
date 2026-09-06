# BRIEF_fix_eqpx_c — DOCS-ONLY round closing lens round 2's four DOC items (F-E2-1..4)

Agent name: `fix_eqpx_c`. Progress file: `$SP/progress/fix_eqpx_c.md`. Worktree: `$SP/wt/eqpx`, branch `eqpx-fix` at
**beb34e0** (the ONLY tree you edit). Read `$SP/briefs/BRIEF_common.md`, then `$SP/progress/review_eqpx_r2.md` from its
`## VERDICT` line to the end (the four findings F-E2-1..4 with their measurements), then `$SP/progress/fix_eqpx_b.md`'s
hand-back (the previous docs round, whose "cite NAMES, the numbers move" rule you are enforcing).

## HARD SCOPE: NO edit to any non-comment line of any `.cpp`/`.h`; no fixture body change (fixture HEADER comments only if
## a citation there is stale); no golden; no `runtime/`, `tools/opcode_table.yaml`, `include/`. At the end:
## `git diff 1333278 -- ir-pass/src ir-pass/include | grep '^[+-]' | grep -v '^[+-]\s*//' | grep -v '^+++\|^---'` EMPTY,
## rebuild, and `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt` BYTE-IDENTICAL. If not, STOP and report.

1. **F-E2-1** — commit `tu_exth.c` (`int ext_h(int a){ return a+3; }`, the exact file at
   `$SP/progress/review_eqpx_r1_work/p/tu_exth.c`) into `docs/prd/phase-04-swap-route-control/inc1-records/session-7bbdb89e/eqpx_reproducers_r1/`
   and fix that README's two-TU rule to name `ext_f` → `tu_extf.c` (in `../../session-82e6b530/eqpx_reproducers/`) AND
   `ext_h` → `tu_exth.c` (here). Verify by running `d03_classical_phi_imm.c` and `d05_classical_call_imm.c` through
   `$SP/harness/run.sh … fix <tu>` exactly as the README now says → `ACCEPT … lines=6 imm=0` both. Check every other
   published `.c` in that dir for an `ext_` symbol the README does not cover (`grep -l 'ext_[a-z]' *.c`).
2. **F-E2-2** — replace the six stale `LoopLowering(.cpp)?:<n>` citations by FUNCTION NAMES (the lens's table lists them:
   `OpcodeLowering.cpp:~426` and notes §3.16 → "`railValueConsumerDisposition`'s `InPlace` cell"; notes §3.14 table
   `:~2073-2074` → its `OutOfPlace` return / the round-1 and round-2 Rule-8 fan-out guards / `collectRailGates`'
   `railValueConsumerDisposition` call; notes §3.11 `:~1589` → "`commitOutOfLoopInPlaceOps`' (A) DIRECTION comment").
   Then run the lens's citation sweep idea yourself: for every `LoopLowering(.cpp)?:<n>` and `ArithLowering(.cpp)?:<n>`
   and `OpcodeLowering(.cpp)?:<n>` in the notes, the PRD, `CLAUDE.md`, `ROADMAP.md`, the three edited sources and the 16
   new fixtures, check that line `<n>` on the SUBJECT contains what the citation names (script it; print the misses).
   Fix every miss INTRODUCED by this branch (compare against `git show main:<file>`); for a PRE-EXISTING miss (wrong on
   `main` too — the lens named `:3214`/`:3412-3413` for the `AsLowered=true` sites) fix it only if it is in a paragraph
   this branch touched, and list the rest in your hand-back untouched.
3. **F-E2-3** — notes §3.16's `strictimm` breakdown: `16 add` (not 15) and the `@g` load is one of the 19
   `load volatile` (delete the separate "1 `@g` load" item); total stays 82, 0 rail producers.
4. **F-E2-4** — `CLAUDE.md`: the pre-existing sentence "**That last one** also RETIRES a sentence…" now follows the
   inserted FIXED clause; re-anchor it ("The eqpx member also RETIRES …" or move the FIXED clause after it) so the
   antecedent is the eqpx member again. Minimal edit.
5. Also record, in notes §3.16's round-2 subsection (add it: verdict CLEAR-WITH-ITEMS; the 80-injection superset matrix
   0 MISSED vs 47/80 pre-edit; M2+M3 0 OUTDIFF over 1707 / M-E 24 moved; 879 accept modules 0 rail producers; the full
   ctest 367/367 350.23 s at beb34e0 READ from the orchestrator's log; the four DOC items and that they are closed by this
   commit), and copy `$SP/progress/review_eqpx_r2.md` + `$SP/progress/fix_eqpx_b.md` + `$SP/progress/review_eqpx_r1.md`
   + `$SP/progress/fix_eqpx.md` into `docs/prd/phase-04-swap-route-control/inc1-records/session-7bbdb89e/` (as
   `fix_eqpx.md`, `review_eqpx_r1.md`, `fix_eqpx_b.md`, `review_eqpx_r2.md`) and the five briefs into `.../briefs/`
   (the orchestrator will add the clearance record and the README/NEXT_SESSION_PROMPT afterwards — do not write those).

Verification (Rule 19): rebuild (background) → currency EMPTY → the `cmp`; `lit --filter inplace_rail` → 16 Passed
(fixture headers may have moved); the d03/d05 harness runs; the citation sweep output. Commit `wip(eqpx-c): …`.
Hand back per BRIEF_common: files, the sweep's before/after miss counts, the cmp, every command.
