# BRIEF_fix_eqpx — IMPLEMENTER: the decline-only consumer tripwire for bd `test_C_libtooling-eqpx`

Agent name: `fix_eqpx`. Progress file: `$SP/progress/fix_eqpx.md`. Worktree: `$SP/wt/eqpx`, branch `eqpx-fix`
(the ONLY tree you edit). Work dir for probes: `$SP/progress/fix_eqpx_work/` (set `W=` when calling the harness).
Read `$SP/briefs/BRIEF_common.md` FIRST, then `investigate_eqpx.md` §3 and §6 WHOLE, then `OpcodeLowering.cpp:200-345`,
`ArithLowering.cpp:307-331` and `:600-700`, `LoopLowering.cpp:130-215`, `:1520-1560`, `:1690-1700`, `:2268-2282`,
`:2668-2680`, `:3060-3090`, `:3400-3420`, `TaintPropagation.h:359-406`, and the fixture
`ir-pass/test/control_phase_kickback_reject_preloop_commit_stale.ll` (the (1b) template — header style, RUN line, CHECKs).

## Step 0 — wait for the build, then control the harness (do not skip)
`tail -1 $SP/progress/orch_wt_eqpx_build.log` must read `BUILD_EXIT=0`; then in `$SP/wt/eqpx`
`find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` must be EMPTY. Copy the harness:
`mkdir -p $W/out && cp -f $SP/harness/run.sh $W/run.sh` (it reads `W` from the environment). Control it:
`W=$W $W/run.sh $SP/harness/p/ctlA_clean_xor_const.c fix` → `ACCEPT … lines=9 imm=0`;
`W=$W $W/run.sh $SP/harness/p/c1c_m_xor_and_noregion.c fix $SP/harness/p/tu_extf.c` → `ACCEPT … lines=21 imm=1` (the
pre-fix tree accepts the known-bad — that is your RED). Record both lines in the progress file.

## Step 1 — RED first (Rule 12): write the 8 decline fixtures + 7 accept controls, watch them fail/pass on `main`
Fixture sources: stage-1 `.s1.ll` of each reproducer from the harness (`$W/out/<base>.main.s1.ll`; the two-TU ones are
already `llvm-link`ed). Strip `@main` and everything it pulls in, keep `!llvm.loop` metadata VERBATIM (the loop
recognizers key on it), keep `!dbg` if present. Naming: `lowering_reject_inplace_rail_stale_<writer>_<stem>_<imm>.ll`
for declines (e.g. `..._w2_xor_derived.ll`, `..._w2_xor_bareout.ll`, `..._w2_add_derived.ll`, `..._w3_xor_derived.ll`,
`..._w3_add_derived.ll`, `..._w1_xor_derived.ll`, `..._w1_xor_bareout.ll`, `..._w2_xor_commuted_handir.ll`) and
`lowering_inplace_rail_<name>_accept.ll` for the accept controls (`ctlA` const-imm, `k01` argument-imm xor, `k02`
argument-imm add, `k03` volatile-load imm, `n09` W4 preheader xor, `n02` select-merge xor, `n03` value-merge xor, `z36`
in-region add). Each header: the plain-C source, which writer, which stem, which immediate class, the measured trace on
`main` (the `cqrt_xorc_i32(h1, 6)` line and what `6` is), and for the commuted one "HAND IR — plain-C spellings
canonicalize back at LLVM 19 -O1".
- Decline RUN line: `; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s`
  with `; CHECK: error{{.*}}cq loop lowering: in-place rail op no longer provable at lowering` and `CHECK-NOT`s for
  `cqrt_xorc_i32`/`cqrt_addc_i32` AND for the out-of-place `cq_template_xor_i32`/`cq_template_add_i32` (no silent
  fallback). For `n15`/`n16` ALSO pin what `lowerBreakReversePlay` prints after our `continue` (measure first).
- Accept RUN line: ONE `%cq-opt … -S %s > %t.ll` then every prefix reads `%t.ll` (spawn-bound — see CLAUDE.md). Use
  COUNT prefixes (`; XCNT-COUNT-3: call void @cqrt_xorc_i32(` etc.) and a whole-file pure-negative `NOROUTE` prefix;
  NEVER a positive count inside the NOROUTE prefix (the Inc-3 F-L6-1 defect). Derive handle names from the pass output.
- RED measurement, per decline fixture, on the FROZEN main binary:
  `$SP/bin/main-16b15b3/cq-opt -load-pass-plugin $SP/bin/main-16b15b3/libCQPass.so -passes=cq-lowering -S <f> | python3 $SP/harness/p/immcheck.py /dev/stdin`
  → `railInImm=1` (RED = accepts with a rail in the immediate slot). Record all 8. The accept controls must pass on `main`
  AND on the fix with `%t.ll` byte-identical (`cmp`) — record the `cmp`.

## Step 2 — the fix (minimal, then the stronger form)
2a. `OpcodeLowering.cpp`: `#include "LoopPlan.h"`; a `diagnoseRailOpStale(Instruction *)` beside
`diagnosePreLoopCommitStale` with the string above; the block from `investigate_eqpx.md` §6 immediately after the (1b)
block and before M-C, with a Rule-0-sized comment: what it re-asks (G2 ALONE, and WHY not the full fence — G5), for whom
(W1–W3, by name and line), what moves it (E1 at `lowerControlRegions`, E2 at `repropagateControlMerges`), why no silent
fallback (name the four licences), and the 8h7d.5 answer (decline-only ⇒ `railValueConsumerDisposition` unchanged).
2b. THE STRONGER FORM: add `llvm::DenseMap<llvm::Instruction *, unsigned> InPlaceRailIdx;` to `TaintSet` (beside
`InPlaceRailOps`, documented: "the operand INDEX of the proven RAIL operand — an index, never a `Value *`; written by every
`InPlaceRailOps` writer, erased by the rollback"). At each of the FOUR insert sites record `BO->getOperand(0) == Rail ? 0 : 1`
(W1 has `Base`; W2 has `KV.first`'s rail — read the surrounding code to find the rail value each writer proved; W3 has
`RailMembers` and the root; W4 has `P`). Erase it at `LoopLowering.cpp:3411` beside the two `erase`s. In
`rewriteInPlaceValueRail` CONSUME `taint.InPlaceRailIdx.lookup(bo)` when present (fall back to `TL` ONLY for the M-C
`InPlaceReassign` route, which has no index — or record one for it too from `classifyInPlaceReassignment`'s `P`; pick the
simpler that keeps M-C byte-identical). In the Phase-1 re-ask, ALSO decline if `inPlaceValueRailOperand`'s fresh answer
is not `BO->getOperand(Idx)` (same string). If the stronger form turns out to touch more than ~40 lines or to move ANY
accept control, SHIP 2a ALONE, say so, and write why under `## OWNER QUESTION`.
2c. Rebuild (`cmake --build build -j8`, background), currency check EMPTY, re-run the 8 + 7 through the harness on `fix`;
then `lit` on every new fixture; then `ctest -R ir-pass-lit` (background) — expect 1691 + 15 = 1706 discovered, 1 XFAIL,
0 unexpected. If ANY pre-existing fixture moves, STOP and report it (do not "fix" the fixture).

## Step 3 — the 0-golden-churn gate and the corpus diff
- `ctest --test-dir build -j6 -R '^e2e-' --output-on-failure` (background, ~4 min; 357 entries). Every golden must match;
  0 regenerated. If a golden moves, STOP and report with the diff.
- Corpus diff main vs fix over all 1691 pre-existing lit fixtures: for each `.ll`, run both binaries, compare exit code,
  first diagnostic line and (for accepts) the output module — report `RCDIFF / DIAGDIFF / OUTDIFF` counts; expect 0/0/0.
  (Script it; `review_c1e.md` step 5 is the model.)
- Run ALL 43 reproducers through the harness on `main` and `fix` (two-TU ones with `tu_extf.c`); tabulate
  `probe | main status/lines/imm | fix status/lines/imm | verdict`. Expect: exactly the members (imm≥1 on main) flip to
  the mirrored decline; every other program byte-identical (`cmp` the traces). `n15`/`n16`: also record the FULL stderr.

## Step 4 — the record-truth items (same increment, COMMENTS/DOCS ONLY outside the code above)
1. `TaintPropagation.h` ~:374-377: the writer enumeration → FOUR writers by name and line (W1 `emitBreakForward`, W2
   `tryCaseA` ACCEPT = "round 1's `railRoot` marking", ONE site; W3 `collapseRailPhisIn` step (3); W4
   `commitOutOfLoopInPlaceOps`), and the paragraph's "filed as bd eqpx, whose proposed fix …" → "FIXED (this increment):
   `lowerOps` Phase 1 re-asks G2 alone for every member …".
2. `OpcodeLowering.cpp` (1b) comment block: the "⚠ IT IS NOT A CLEAN BILL OF HEALTH … Filed as bd eqpx; the proposed fix
   is …" paragraph → past tense, pointing at the new block below it.
3. `RETIRE_SWAP_ROUTE_INC1_NOTES.md`: §2's ⭐ table eqpx row (line ~985): writers → four, disposition → FIXED with the
   string; a NEW `### 3.16 bd eqpx — the consumer tripwire for W1–W3 (2026-09-06)` after §3.15 with: the four writers, the
   two growth events, the ADD row of §3.12 FALSIFIED (the located `-O1` cause, the four plain-C add members), the bare
   `%out` producer path, the fix, the red-green table, the 0-churn measurement, the stronger form if shipped, and what is
   NOT covered (the round-2 re-ask alternative rejected and why; the capability genuinely lost = the shape has no correct
   ROLLED lowering, the hand-unrolled spelling still compiles). §3.12's ADD row gets a dated "⚠ FALSIFIED by the eqpx
   investigation, see §3.16" line — do not delete the row.
4. PRD `retire-swap-route-PRD.md` §0: a dated **E13** (three lines: eqpx fixed, the string, the four writers).
5. `CLAUDE.md`: the C-1 bullet's sentence "… plus ONE PRE-EXISTING member of the same class found in passing by the
   round-3 lens — bd `test_C_libtooling-eqpx` (F-C1C-B, notes §3.12) …" gains a dated "**FIXED 2026-09-06 (this session):
   …G2 alone re-asked at `lowerOps` for every `InPlaceRailOps` member, declining `cq loop lowering: in-place rail op no
   longer provable at lowering`; four writers, not three — `emitBreakForward` was unlisted; the `add` stem was reachable
   and correct only by `-O1`'s accident …**" clause; the Build & Test lit count line gets a dated `1706` prefix in the same
   style as the existing ones (`ls ir-pass/test/*.ll | wc -l`, MEASURED); ctest counts UNCHANGED (say so: no new slice).
   `ROADMAP.md`: if it names eqpx as open, flip it (grep first; if absent, leave it).
Keep the docs edits SURGICAL; do not rewrite paragraphs that are true.

## Step 5 — hand back
Commit on `eqpx-fix` (as many `wip(eqpx):` commits as you like). Progress file's last section = the hand-back (format in
BRIEF_common). Include: the exact diff stat of `ir-pass/src ir-pass/include` (expect: `OpcodeLowering.cpp`,
`TaintPropagation.h`, `ArithLowering.cpp`, `LoopLowering.cpp` if 2b shipped; NOTHING in `runtime/`, `tools/opcode_table.yaml`,
`include/`), the 8-RED/8-GREEN table with `immcheck` counts, the 7 accept `cmp`s, the lit count, the e2e result, the
RCDIFF/DIAGDIFF/OUTDIFF triple, the 43-program table, and every OWNER QUESTION.

## Things that are NOT yours
- Do not widen or narrow any writer's fence, `inPlaceValueRailOperand`, G5, or `railValueConsumerDisposition`.
- Do not add a re-ask at the writers after `repropagateControlMerges` (the once-only-stage mistake, investigation §6).
- Do not regenerate any golden. Do not add a slice unless the orchestrator asks. Do not touch the twin matrices.
- If the stronger form (2b) requires changing what ANY writer proves, stop: `## OWNER QUESTION`.
