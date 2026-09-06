# BRIEF_common — bd `test_C_libtooling-eqpx` (P1) FIX SESSION (2026-09-06, session 7bbdb89e)

You are ONE agent in a multi-agent session. An orchestrator wrote this brief and will judge
your output; the owner is NOT watching. Read this file completely, then your own brief.

## Paths (absolute; nothing is on PATH except `lit`, `python3`, `cmake`, `git`, `bd`)
- LLVM 19 tools:   `/usr/local/opt/llvm@19/bin/{clang,opt,FileCheck,not,llvm-link}`  (use absolute paths)
- Main checkout:   `/Users/sorenwilkening/Desktop/CQ_lang` — branch `main` at **0b402d6** (= origin/main; docs-only
  over the last CODE commit **16b15b3**, C-1 round 4 landed). Build CURRENT for 16b15b3 (measured: `find
  ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` is EMPTY). **This is the PRE-FIX baseline for this
  session's red-greens: NOBODY edits it, NOBODY rebuilds it, NOBODY runs `git` mutations in it.**
    - a frozen COPY of that binary: `$SP/bin/main-16b15b3/{cq-opt,libCQPass.so,libcq_templates.a,libcq_runtime.a}`
- Scratchpad (THIS session): `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/7bbdb89e-f7ed-43f7-80e1-bda20ba33640/scratchpad`
  — call it `$SP`. Briefs in `$SP/briefs/`, progress files in `$SP/progress/`, worktrees in `$SP/wt/`, saved binaries
  in `$SP/bin/`, the shared harness in `$SP/harness/`.
- **THE FIX WORKTREE**: `$SP/wt/eqpx`, branch **`eqpx-fix`** (base = `main` 0b402d6). The orchestrator configured and
  built it (`$SP/progress/orch_wt_eqpx_build.log`, last line `BUILD_EXIT=0` when done). Only the IMPLEMENTER edits it;
  lenses read it and run its binary.
- **ORACLE** (pre-3qlq, commit **52d7764**, BUILT and current): `$SP0/wt/pre-3qlq` where
  `$SP0=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/0a61aa31-6fbe-43af-b2fd-a09b6d203ae5/scratchpad`
  (`build/ir-pass/cq-opt`, `build/ir-pass/libCQPass.so`, `build/runtime/libcq_{templates,runtime}.a`).
- **THE HARNESS**: `$SP/harness/run.sh <file.c|file.ll> <main|orac|fix|<tree-root>> [extra TUs]` = stage 1 → 2 →
  2b STRICT → immcheck → 3 → 4. Prints `ACCEPT <base> <tag> 2b=<rc> lines=<n> imm=<rails-in-immediate-slot> run=<rc>`
  or `DECLINE rc=<rc> <base> <tag> :: <diagnostic>`. Outputs in `$W/out/` (default `$W=$SP/harness`; set `W=` to your
  own work dir to avoid clobbering others). CONTROLLED by the orchestrator: `p/ctlA_clean_xor_const.c main` →
  `ACCEPT … lines=9 imm=0`; `p/c1c_m_xor_and_noregion.c main p/tu_extf.c` → `ACCEPT … lines=21 imm=1`, trace
  byte-identical to `orac`. COPY it into your own work dir if you change it.
- **THE 43 REPRODUCERS + `immcheck.py`**: `$SP/harness/p/` (a copy of
  `docs/prd/phase-04-swap-route-control/inc1-records/session-82e6b530/eqpx_reproducers/`). Two-TU programs (every
  `ext_f` user) take `p/tu_extf.c` as the extra TU.
- Progress file: `$SP/progress/<your-agent-name>.md` — append a dated line after EVERY step.
  If you are killed mid-task a fresh agent resumes from this file and your branch.

## The record (all committed on `main`, read from the repo)
- **THE INVESTIGATION (read it whole, it is the spec)**:
  `docs/prd/phase-04-swap-route-control/inc1-records/session-82e6b530/investigate_eqpx.md` — §1 the signature on
  four binaries, §2 the add/xor asymmetry located in `clang -O1`, §3 the FOUR writers, §4 the 43-program census,
  §5 blast radius, §6 the proposed fix made concrete (site, predicate, string, why no silent fallback, the 8h7d.5
  question, the red-green list), the three record-truth items.
- `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 (the ⭐ once-only-stage table, line 962 — the eqpx row is the 8th),
  §3.11 (F-C1B-1: the same class through W4 and how round 3 fenced it — the (1a) monotone `isa<Constant>` fence +
  the (1b) loud tripwire), §3.12 (eqpx), §3.14–§3.15; PRD `retire-swap-route-PRD.md` §0 E2/E10.
- Session-82e6b530 record: `README.md`, `review_c1e.md` (the last lens on `main`'s round-4 tree, CLEAR-WITH-ITEMS —
  its §"WHAT I RAN" table is the model of a hand-back), `rebase_c1d.md`.
- bd: `bd show test_C_libtooling-eqpx` (the OWNER RULING 2026-09-06 is in its NOTES), `bd show test_C_libtooling-3qlq`.
  Do NOT close or edit bd issues; the orchestrator does that. You MAY `bd remember` a hard-won LLVM-19 fact.
- bd memories (`bd prime | sed -n '/^### <key>$/,/^### /p'`): `fix-that-predicts-a-later-stage-must-reverify-there`,
  `once-only-stage-round2-false-premise`, `3qlq-c1-round4-landed-2026-09-06`, `rolled-idiom-needs-body-gate-or-invariant-root`,
  `drbq-inc4-review-pattern`.

## The defect, in one paragraph
`taint.InPlaceRailOps` has FOUR writers in `LoopLowering.cpp` (`grep -n 'InPlaceRailOps.insert' ir-pass/src/LoopLowering.cpp`
→ **4**: W1 `emitBreakForward` :1698, W2 `tryCaseA` ACCEPT :2281, W3 `collapseRailPhisIn` step (3) :2679, W4
`commitOutOfLoopInPlaceOps` :3084). Each marks an in-place `add`/`xor` after proving G2 (`inPlaceValueRailOperand`,
`LoopLowering.cpp:143` — EXACTLY ONE tainted operand) under ROUND-1 taint. W1/W2 run at `lowerLoops`
(`CQLoweringPass.cpp` ~:363); W3/W4 at `collapseFlattenedLoopRails` (~:393). TWO taint-growth events follow:
E1 — `lowerControlRegions` (~:376): `ClassicalCallArmEmit.cpp:209` / `SwitchDataMuxEmit.cpp:144` taint the BARE merge
`%out` at emission; E2 — `repropagateControlMerges` (~:409) taints everything DERIVED from `%out`. At `lowerOps`
(~:536) `OpcodeLowering.cpp:428` dispatches every marked op to `rewriteInPlaceValueRail` (`ArithLowering.cpp:307-331`),
which re-picks the rail by `TL = taint.Tainted.count(L)` and passes the OTHER operand — now a quantum rail — as the
ABI's CLASSICAL IMMEDIATE: `cqrt_xorc_i32(h1, 6)` where `6` is `h6`'s HANDLE ID (`opt` exit 0, verify-clean, STRICT 2b
`0 violation(s)`; commuted hand IR mutates the WRONG register). W4 is ALREADY fenced (round 3: `isa<Constant>(Imm)` at
the commit + the (1b) tripwire at `OpcodeLowering.cpp:325-333` re-asking the whole M-C fence for
`PreLoopCommittedInPlaceOps`). W1–W3 prove the RAIL; none proves the IMMEDIATE stays classical. PRE-EXISTING (byte-
identical on the oracle 52d7764). 0/323 goldens carry the signature; blast radius is the 10 known reproducers.

## THE FIX (owner ruling 2026-09-06; Rule 17 — build THIS, do not decline the target shape)
A **SECOND predicate** in `OpcodeLowering.cpp` Phase 1, immediately AFTER the existing (1b) block (ends ~:333) and
BEFORE the M-C block (~:340): for every `taint.InPlaceRailOps` member NOT in `taint.PreLoopCommittedInPlaceOps`, re-ask
**G2 ALONE** under FINAL taint — `inPlaceValueRailOperand(BO, taint) != nullptr` (declared `LoopPlan.h:332`;
`OpcodeLowering.cpp` must `#include "LoopPlan.h"`) — and DECLINE LOUDLY with the string, mirrored character-for-character:

    cq loop lowering: in-place rail op no longer provable at lowering

`DiagnosticInfoUnsupported(DS_Error)` + `!dbg`, same surface as `diagnosePreLoopCommitStale` (`OpcodeLowering.cpp:78`);
`continue` (never enqueued ⇒ never rewritten ⇒ never erased).
- **NOT the existing tripwire widened**: `inPlaceFenceHolds`' G5 loop test (`ArithLowering.cpp:646-648`) is NOT gated by
  `IgnoreSelfMarking`, so re-asking the full fence refuses 100 % of in-loop sites.
- **NO silent fallback to out-of-place**: the marking already licensed `IterationLocalBlocks`, the ERASED rail phi,
  `ClaimedRailRoots`, and for W1 the whole break transform + `lowerBreakReversePlay`.
- **NOT the writer-side `isa<Constant>(Imm)` analogue**: it costs three measured capabilities (`k01`/`k02`/`k03` —
  Argument and volatile-load immediates dtzb deliberately accepts — G2 itself constrains the immediate only by "not tainted" (`LoopLowering.cpp:143`), and W1's (E10) says "dtzb accepts ANY untainted immediate" (`LoopLowering.cpp:~1568-1570` on the fix tree; ⚠ this line first cited `:1528-1537`, which is (E6)/(E12) code — corrected after `fix_eqpx_b` measured it)).
- **Stronger form, worth doing**: record the proven rail-operand INDEX (0/1) at every writer (a `DenseMap<Instruction*,
  unsigned>` on `TaintSet`, NEVER a `Value *` — the drbq Inc-1 dangling defect) and have `rewriteInPlaceValueRail`
  CONSUME it instead of re-picking `TL` from a `Tainted` that `promote()` mutates during Phase 2; the Phase-1 re-ask
  then also checks the index agrees with G2's fresh answer. Written and ERASED in lockstep with `InPlaceRailOps`
  (the rollback at `LoopLowering.cpp:3411`).
- **8h7d.5, answered up front**: a decline-only widening does not narrow `railValueConsumerDisposition`'s `InPlace`
  cell (`LoopLowering.cpp:206` — the Rule-8 fan-out guard + `collectRailGates`); a silent REMOVAL from the set would
  reopen 8h7d.5 F-1. Readers of the set: `ArithLowering.cpp:644`, `OpcodeLowering.cpp:341,428`, `LoopLowering.cpp:206,3070,3411`.
- **W1 has a post-`lowerOps` stage**: `lowerBreakReversePlay` (`BreakReversePlay.cpp:886` → `emitOneBreak` :707) walks
  the lowered body and declines `kMsgBreakRederive`/`kMsgBreakUncovered` on an un-lowered op — MEASURE what `n15`/`n16`
  print after the Phase-1 `continue` (a SECOND diagnostic after ours is acceptable; a crash or `LLVM ERROR` is not).

## Red-green (Rule 12), on `main` (RED = accepts with imm≥1) vs `fix` (GREEN = the mirrored decline)
DECLINES (8, one per reachable writer × stem × immediate class): W2·xor·derived `c1c_m_xor_and_noregion`(+tu_extf) ·
W2·xor·bare-`%out` `n04` · W2·add `a1` (or `hand_add_from_xor.ll`) · W3·xor `c1c_m_xor_and` · W3·add `n08` · W1·xor·derived
`n15` · W1·xor·bare `n16` · commuted wrong-REGISTER `hand_xor_commuted.ll` (hand IR; header must say so).
ACCEPT CONTROLS (7 groups, trace BYTE-UNCHANGED main vs fix): `ctlA` · `k01`/`k03` (the two that separate "G2 alone" from
`isa<Constant>`) · `k02` · `n09`/`n10` (W4, its own tripwire) · `n02`/`n03` (4.4 select / Inc-2 value merge — NOT producers,
tainted at round 1) · `z36`/`c1c_w1_bodyadd_r2derived`. **0 new goldens, 0 golden churn — that invariance is the gate.**

## CLAUDE.md rules that bind you (read the file; these are the load-bearing sentences)
* Prime Directive: over-declining is safe; over-accepting is a verify-clean SILENT MISCOMPILE, the one unforgivable bug.
* Rule 17: for the TARGET shape a decline is NOT the escape hatch — here the target IS a decline-only tripwire, and the
  thing that must NOT be declined is every correct program (the accept controls, the 323 goldens, 1691 fixtures).
* Rule 12: red-green; the `RUN: not … | FileCheck` mirrors the string character-for-character. Watch it FAIL on `main`.
* Rule 13: this is the Rule-13 core. A green suite does not clear it; two lenses and a clearance do.
* Rule 19: run the layer that can WITNESS your edit. NEVER the full `ctest` (the orchestrator runs it once at the gate).
  Report only what you ran: "lit green (N)", never "tests pass".
* THE C-1 LESSON: a stage that PREDICTS a later stage's decision needs a MONOTONE commit-time fence PLUS a LOUD tripwire
  at the consumer that re-asks the SAME predicate under final state. This fix IS that tripwire for W1–W3.
* THE 8h7d.5 LESSON: "when you widen a set, ask what OTHER set was computed over the same closure."
* HARD RULE: **NO new `cqrt_*` or `cq_template_*` symbol** (owner D3). Do not touch `tools/opcode_table.yaml`, `runtime/`, `include/`.
* Stop and write `## OWNER QUESTION` if anything contradicts a PRD §2 decision (D1–D7) or the ruling above.

## Build (only in YOUR worktree; the main checkout is never rebuilt this session)
```
cmake --build build -j8            # builds BOTH CQPass and cq-opt. NEVER `--target CQPass` alone (FALSE GREEN, measured).
cd build && lit ir-pass/test --filter '<name>'            # one fixture (1.5 s)
ctest --test-dir build -R ir-pass-lit --output-on-failure  # all fixtures (~35–105 s) — BACKGROUND
ctest --test-dir build -R '^e2e-slice-<name>$'             # one slice (1.7 s)
ctest --test-dir build -j6 -R '^e2e-' --output-on-failure  # all 357 e2e (~4 min) — BACKGROUND; the 0-golden-churn gate
```
Before trusting ANY binary: `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` must be EMPTY.
Save a copy of every binary you red-green against under `$SP/bin/<tag>/` BEFORE rebuilding.

## Anti-stall rules (agents have been killed by the 600 s stream watchdog and by an API rate limit)
1. Anything > 2 min (a build, a full lit run, an e2e run, a sweep) runs with `run_in_background: true`, writing a log
   under `$SP/progress/`; poll with `tail`. Never block the foreground on it.
2. Append to your progress file after EVERY step (what you ran, the measured result, the next step).
   Numbers are MEASURED, with the command that measured them.
3. Non-interactive flags always: `cp -f`, `mv -f`, `rm -f`, `rm -rf`. Use `bash -c` for word-splitting loops (zsh does not
   word-split — a session-2 lens scored declines as accepts because of it). macOS `/bin/bash` is 3.2: no `declare -A`.
   BSD `mktemp` needs the `X`s LAST.
4. Do not run the full `ctest`. Do not `git push`. Do not commit to `main`. Commit on YOUR branch as often as you like,
   message prefixed `wip(eqpx):`.
5. No TodoWrite, no markdown TODO lists, no MEMORY.md. Progress file + bd only.

## Verification claims
Quote counts with the command that produced them. Distinguish MEASURED from analytic. Say "declines with `<exact
string>`" and "accepts, trace N lines, imm=0", never "works". Name every binary path you compare. When something is not
verified, say so first.

## Hand-back format (last section of your progress file AND your final message)
1. What shipped (files, counts, commit hashes on your branch).
2. What you ran (commands + results) — a table like `review_c1e.md`'s "WHAT I RAN".
3. Findings that are NOT yours to decide (`## OWNER QUESTION`), each with the reproducer.
4. What is left.
