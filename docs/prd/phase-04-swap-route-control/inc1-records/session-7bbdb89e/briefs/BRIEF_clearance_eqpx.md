# BRIEF_clearance_eqpx — the ONE Rule-13 CLEARANCE review of the eqpx fix (READ-ONLY on the subject)

Agent name: `clearance_eqpx`. Progress file: `$SP/progress/clearance_eqpx.md`. Work dir:
`$SP/progress/clearance_eqpx_work/` (copy the harness, set `W=`). Read, in order: `$SP/briefs/BRIEF_common.md`,
`BRIEF_fix_eqpx.md`, `BRIEF_review_eqpx_r1.md`, `BRIEF_fix_eqpx_b.md`, `BRIEF_review_eqpx_r2.md`, `BRIEF_fix_eqpx_c.md`, then the progress files
`$SP/progress/fix_eqpx.md`, `$SP/progress/review_eqpx_r1.md`, `$SP/progress/fix_eqpx_b.md`, `$SP/progress/review_eqpx_r2.md`, `$SP/progress/fix_eqpx_c.md` — WHOLE.

SUBJECT: `$SP/wt/eqpx`, branch `eqpx-fix` at **e752877** (code tip 1333278; docs rounds beb34e0 → e752877; base `main` 0b402d6). READ-ONLY: verify currency and a clean
`git status --porcelain` before trusting its binary; build mutants only under `$W/`. Binaries: `main` =
`$SP/bin/main-16b15b3/` (pre-fix), `orac` = `$SP0/wt/pre-3qlq` (52d7764), `fix` = the subject.

## Your verdict decides the commit. You are the independent second reviewer Rule 13 requires.
The rounds so far: implementer `fix_eqpx` (code tip 1333278: the G2-alone tripwire + the operand-index form, 16 fixtures, record docs) → lens round 1 `review_eqpx_r1` **CLEAR-WITH-ITEMS** (3 DOC/FIXTURE items F-E1-1/2/3, 2 CLEAR record items F-E1-4/5: 15 more `main` members incl. an i8/i16 broken-module face, 0 over-declines over 20 boundary programs; whole-corpus sweep 8 accept→decline / 0 decline→accept / OUTDIFF 0; mutants M-A/M-B/M-E/M-F; the stronger form adjudicated DOC-keep; the `n02` collapse = `unrollConstTripLoops` gate U4) → docs+fixtures round `fix_eqpx_b` (tip beb34e0, binary `cmp`-byte-identical to 1333278; injection matrix 28 MISSED → 0) → lens round 2 `review_eqpx_r2` **CLEAR-WITH-ITEMS** (narrow: fixture/record integrity + the full-suite gate READ from the orchestrator's log `$SP/progress/orch_full_ctest_eqpx.log` = 367/367, 350.23 s, EXIT=0 at beb34e0; 80-injection superset matrix 0 MISSED vs 47/80 pre-edit; M2+M3 0 OUTDIFF over 1707 and M-E 24 moved; 879 accept modules 0 rail producers; four DOC items F-E2-1..4 — a missing `tu_exth.c`, six shifted line citations, a 15/16 slip, an antecedent drift) → docs round `fix_eqpx_c` (closes F-E2-1..4, binary unchanged; tip = e752877, the SUBJECT you clear). You are NOT a third adversarial round; you are the CLEARANCE: re-derive the
load-bearing claims yourself, from the tree and with programs, and rule.

1. **The fix is what the owner ruled** (bd `test_C_libtooling-eqpx` NOTES, 2026-09-06): a DECLINE-ONLY consumer tripwire —
   G2 alone re-asked at `lowerOps` for every `InPlaceRailOps` member not in `PreLoopCommittedInPlaceOps`; NOT the full
   fence; NOT the writer-side `isa<Constant>`; NO silent fallback; NO re-ask at the writers. Read the diff
   (`git diff main..e752877 -- ir-pass/src ir-pass/include` (non-comment lines identical to `main..1333278`'s; the binary must be `cmp`-identical to `$SP/bin/eqpx-1333278/cq-opt`)) and confirm each clause by construction. Anything beyond the
   ruling (the stronger INDEX form) is disclosed and argued — rule on whether its disclosure is honest.
2. **Nothing accepted got worse, nothing correct got refused.** Re-run, yourself: the 1691-fixture corpus diff `main`
   vs `fix` (RCDIFF/DIAGDIFF/OUTDIFF), `git diff --stat main -- tests/e2e runtime tools/opcode_table.yaml include`
   EMPTY, the 43-reproducer census on three binaries with `immcheck.py` on every accept, and a sample of ≥10 of the
   lenses' attack programs re-executed by you (pick the ones nearest the boundary).
3. **The fence is a fence.** Build the M1 mutant (new block deleted) yourself and confirm the 8 declines go RED; confirm
   nothing else moves. Rule on the stronger form: pinned, argued-inert, or decoration (item 6 of the round-1 brief).
4. **The class is closed for the four writers and the 8h7d.5 question is answered**: the four `InPlaceRailOps.insert`
   sites are all routed through ONE helper; `railValueConsumerDisposition`'s `InPlace` cell is unchanged; a silent removal
   from the set does not exist anywhere in the diff.
5. **Every lens finding has a disposition** and every CONFIRMED finding is FIXED with a red-green fixture, or is
   PRE-EXISTING with the oracle measurement that proves it, or is an OWNER QUESTION. List them.
6. **Record truth**: counts by command; `TaintPropagation.h`, `OpcodeLowering.cpp`, notes §2 row + §3.16, PRD §0 E13,
   `CLAUDE.md`, `ROADMAP.md` say what the tree does; no sentence claims the class is closed beyond the four writers.

## Verdict
`CLEAR` / `CLEAR-WITH-ITEMS` / `CLEAR-WITH-OWNER-QUESTIONS` / `BLOCK`. A BLOCK names the reproducer, the binaries, the
measured status/lines/imm on each, and the one fact that makes it a wrong unitary or a lost capability. End with the
"WHAT I RAN" table and a "NOT run" row. Anything contradicting a PRD §2 decision (D1–D7) → `## OWNER QUESTION`.
