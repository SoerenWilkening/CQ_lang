# BRIEF_fix_eqpx_b — FIX ROUND 2 (DOCS + FIXTURES ONLY, NO LOWERING CHANGE) after lens round 1 CLEAR-WITH-ITEMS

Agent name: `fix_eqpx_b`. Progress file: `$SP/progress/fix_eqpx_b.md`. Worktree: `$SP/wt/eqpx`, branch `eqpx-fix` at
**1333278** (the ONLY tree you edit). Work dir: `$SP/progress/fix_eqpx_b_work/`. Read `$SP/briefs/BRIEF_common.md`,
`BRIEF_fix_eqpx.md`, `BRIEF_review_eqpx_r1.md`, then `$SP/progress/fix_eqpx.md` (the implementer's hand-back) and
`$SP/progress/review_eqpx_r1.md` (the lens report) WHOLE. The lens's work dir is `$SP/progress/review_eqpx_r1_work/`
(its attack programs `a/`, `b/`, its `inject2.sh`, `sweep2.sh`, `strictimm.py`, `census.sh`) — READ them, COPY what you reuse.

## HARD SCOPE: no change to any `.cpp`/`.h` line that is not a comment. The lowering is CLEARED; you are closing the
## lens's DOC/FIXTURE items and folding its measurements into the record. Verify at the end that
## `git diff 1333278 -- ir-pass/src ir-pass/include | grep '^[+-]' | grep -v '^[+-]\s*//' | grep -v '^+++\|^---'` is EMPTY
## and that the rebuilt `cq-opt` is `cmp`-BYTE-IDENTICAL to `$SP/bin/eqpx-1333278/cq-opt`.

### Item F-E1-1 — stale line numbers / stale grep (COMMENTS)
`OpcodeLowering.cpp` (the tripwire's Rule-0 block, ~:377-386) and `LoopLowering.cpp` (`markInPlaceRailOp`'s header,
~:159-161) cite `grep -n 'InPlaceRailOps.insert('` → four sites and the lines `:1698 :2281 :2679 :3084`. On the tree the
insert has ONE site (inside the helper) and the four writers are the `markInPlaceRailOp(` callers at `:1729 :2312 :2710
:3115` (re-measure; they may shift by your own comment edits — cite them AFTER your last edit, or cite the helper name
and the four function names without numbers, which is the robust form). `TaintPropagation.h:404-412` already has it
right — make the other two agree with it.

### Item F-E1-2 — vacuous `CHECK-NOT`s in the 8 decline fixtures (FIXTURE HEADERS)
MEASURED by the lens: on a `DS_Error` decline `cq-opt` writes 0 bytes to stdout, so with `RUN: not … 2>&1 | FileCheck`
the `CHECK-NOT: cqrt_xorc_i32` / `cq_template_xor_i32` lines can never fire; the "no silent fallback" property is pinned
by the `not` inversion (mutant M-B: 8 RED). In each of the 8 decline fixtures add a header sentence saying exactly that
(which mechanism pins what), and either delete the vacuous `CHECK-NOT`s or keep them with a one-line comment that they
are documentation of the forbidden output, not a live assertion. Do NOT touch the pre-existing (1b) template fixture
`control_phase_kickback_reject_preloop_commit_stale.ll` (same house style; out of scope — mention it in §3.16 as a
pre-existing pattern). Re-run `lit --filter inplace_rail` → 16 Passed.

### Item F-E1-3 — the 8 accept controls under-assert (FIXTURES)
Give ALL EIGHT accept fixtures: (i) a whole-file pure-negative `NOROUTE` prefix carrying BOTH stems' rail-immediate
form — `; NOROUTE-NOT: call void @cqrt_xorc_i{{[0-9]+}}(i32 %{{.*}}, i32 %{{.*}})` and the `addc` twin (a Constant
immediate prints as `i32 7`, never `i32 %…`, so this is exactly "no rail in the immediate slot"); (ii) an `FCNT` prefix
with `FCNT-COUNT-<n>: call void @cqrt_free(` derived from the pass output, followed by `FCNT-NOT: call void @cqrt_free(`;
(iii) where the fixture's expected stream has NO out-of-place `cq_template_{xor,add}_i32` call, a `NOROUTE-NOT` for it.
NEVER a positive count inside the NOROUTE prefix (F-L6-1). Every prefix reads the ONE `%t.ll`. Then re-run the lens's
`inject2.sh` (copy it; it injects a rail-immediate `cqrt_xorc_i32(%h, %rail)`, an extra `cq_template_xor_i32`, an extra
`cqrt_free`, each at head and tail) over the 8 → expect **0 MISSED**, and a clean control green on all 8. Record the
before/after (28 MISSED → 0) with the command.

### Item (A) — the in-source argument for the stronger form (COMMENTS)
At `ArithLowering.cpp` ~:341 (the `InPlaceRailIdx.find` consume) the comment says the index is "a checked fact, not a
prediction" without saying why `TL` and the index cannot disagree. Add the lens's argument, verbatim in substance:
(1) `rewriteInPlaceValueRail` has exactly one call site, reached only from `Work`, and every `Work` member passed the
Phase-1 tripwire; (2) every Phase-2 `Tainted` mutation is `promote(repl, orig)` (`ArithLowering.cpp:49-57`, mirrored in
`CastLowering`, `CompareLowering`, `IntrinsicLowering`) — it INSERTS a fresh instruction and ERASES an already-tainted
value just RAUW'd to it, so an operand untainted at Phase 1 is neither RAUW'd nor inserted, and one tainted at Phase 1
is only ever replaced by another tainted value; (3) the one non-`promote` Phase-2 RAUW, `emitInPlaceReassign`'s
`Site->replaceAllUsesWith(Handle)`, substitutes the rail handle G2 proved tainted. State the measured status honestly:
"agrees with `TL` on every program in the corpus (M2+M3 mutant: 0 fixtures move) and is LIVE (M-E, a wrong index:
23 fixtures red) — argued defence-in-depth, not a fence with a red-green of its own".

### Item F-E1-4 + (B) — the record (DOCS)
1. Copy the lens's 15 new member programs (`a/x01..x04, x08..x12, x14, x15`, `b/y05..y08`, `a/x09`, `a/x10`) and its 20
   over-decline controls (`a/d01..d20`) into
   `docs/prd/phase-04-swap-route-control/inc1-records/session-7bbdb89e/eqpx_reproducers_r1/` (create the dir; a README
   line per file with its main/fix status, lines, imm — take them from the lens's tables). Keep the names.
2. Notes `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.16: add a "round-1 lens" subsection with: the verdict; F-E1-4's table (15
   members, all declined; `x09`/`x10` the i8/i16 BROKEN-MODULE face — `cqrt_xorc_i8(i32 %h2, i32 %h_op)` fails the
   verifier on `main`, rc 134, so at those widths the class was a loud crash rather than a silent miscompile — and
   `y07`, the commuted `add` from PLAIN C, which retires half of §3.12/investigation §2's "commuted is hand-IR-only":
   the wrong-IMMEDIATE face of the commuted add is plain-C reachable, the wrong-REGISTER face stays hand-IR); F-E1-5
   (20 boundary programs, 0 over-declines); the whole-corpus sweep (fix 841/866, main 849/858, 8 accept→decline, 0
   decline→accept, OUTDIFF 0 over 841; `strictimm.py` 82 non-constant immediates, 0 rail producers); the four mutants
   M-A/M-B/M-E/M-F with their results; adjudication (A) as above; adjudication (B): the `n02`/`n03` collapse is
   `unrollConstTripLoops` (`LoopUnrollPrepass.cpp`, gate U4 = `loopHasInPlaceRailStructure`), which runs at
   `CQLoweringPass.cpp:272` under the SAME round-1 taint the writers read, so whenever a writer would mark (G2 non-null)
   U4 clause (a) is true and the prepass refuses, and whenever it unrolls G2 was null and the ops reach `lowerOps` as
   ordinary out-of-place Q+Q — the two claim sets are disjoint in both directions; taint only grows, and growth turns G2
   non-null→null, never the reverse; NOT a fifth writer, NOT an escape past the tripwire (M-F: disabling it makes
   `n01`/`n02`/`n03` decline `loop-carried tainted value crosses iterations`). Also F-E1-2's house-style note.
3. PRD §0 E13: one added sentence for the 15 more members + the i8/i16 crash face.
4. `CLAUDE.md`'s eqpx clause: add "(+15 more members found by the round-1 lens, incl. an i8/i16 BROKEN-MODULE face and
   the commuted `add` from plain C; 0 over-declines over 20 boundary programs)". Keep it to one sentence.
5. `$SP/briefs/BRIEF_common.md` is the orchestrator's; do not edit it.

### Verification you owe (Rule 19 — the layers that can witness these edits)
`cmake --build build -j8` (background) → currency EMPTY → `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt`
BYTE-IDENTICAL (comments only) — if it is NOT identical, STOP and report; `lit --filter inplace_rail` → 16 Passed;
`inject2.sh` → 0 MISSED + clean control; `ctest -R ir-pass-lit` (background) → 1707 / 1 XFAIL / 0 unexpected;
`git diff --stat 1333278 -- tests/e2e runtime tools/opcode_table.yaml include` EMPTY. Commit `wip(eqpx-b): …`.
Hand back per BRIEF_common: files, counts, the injection before/after table, the cmp, every command.
