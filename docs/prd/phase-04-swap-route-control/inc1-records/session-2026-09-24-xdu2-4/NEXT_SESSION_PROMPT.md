# Next session — rail-bank follow-ups after bd `xdu2.4` (parallel orchestrator)

You are the **orchestrator**. You spawn **parallel subagents, one per track, each in its own
git worktree** (`isolation: "worktree"`), then merge, gate and push. You do not edit pass source
yourself except for Step 0. Read first: `AGENTS.md`, the full `CLAUDE.md` (Rules 12, 13, 17, 19;
§3 L1–L10), `CODE_MAP.md` (before any source search), `bd prime`, `bd show` for every bead below,
and this session's lab entry `docs/labreport/sessions/022-2026-09-24-xdu2-4-runtime-rail-bank.tex`.

```
REPO = /Users/sorenwilkening/Desktop/Projects/CQ_lang
SES  = docs/prd/phase-04-swap-route-control/inc1-records/session-<today>-railbank-parallel/
LLVM = /usr/local/opt/llvm@19/bin        # NOT on PATH
```

Do NOT add the user-owned untracked `.agents/` or `.codex/`. `example/grover/main.c` is ignored
via `.git/info/exclude` and is the primary local customer: it must keep compiling (exit 0, no
`cqrt_qram_*`, no `store i32 0, ptr %cq.bank.addr`, STRICT stage 2b clean) at every merge.

## State at close of 2026-09-24 (measured — re-measure, never quote)

`main` = `2143a535`. Full `ctest -j6` 486/486; `cq-opt-equivalence-full` 2170/0; lit 2170
(1 XFAIL). `xdu2.4` CLOSED after two Rule-13 rounds (round 2 CLEAR-WITH-ITEMS, 0 P1/P2).
The last four P3 fences (lifetime.start-in-cycle, `returns_twice`, `trunc` removal, literal-cell
lit fixture) are decline-direction and mutation-tested but had **no third review round** — the
first reviewer of any track touching `QramLowering.cpp`'s carve should also read them.

## The tracks (independent; one subagent each)

| track | bead | what | hot files |
|---|---|---|---|
| **A** | `xdu2.10` (P2) | plain `int b[n]` without an explicit `n<=0` guard declines `array has cells no iteration writes`: C6's read-order test is dominance-SYNTACTIC. Ask the semantic question (L5): "read executes ⇒ write loop executed", via SCEV-equal trip counts + the guards' implied conditions. | `QramLowering.cpp` `railBankCarveVerdictImpl` (C6 read loop) |
| **B** | `xdu2.1` (**P1 over-accept**) | a rail parked in a bank cell is measured after a later non-diagonal gate relabels its wire; the register spelling declines. Bring bank reads under the 3d8q stale-reader fence. RE-MEASURE FIRST on `2143a535` — the bank machinery changed a lot since 2026-09-15. | `OpcodeLowering.cpp` stale readers, `RailBankPromote.cpp` `railBankParkedRails`, `WireWalk` |
| **C** | `xdu2.8` (P2) | a classical `p[i]` read under `if (q && m==n)` declines because PredMux would speculate it; keep the read guarded by the CLASSICAL half, or clamp the index, instead of speculating. | `PredMuxFlatten.cpp`, `QramLowering.cpp` `classicalRuntimeAllocaReadIsInBounds` |
| **D** | `xdu2.9` (P3) | a bank cell whose conditional store is constant-dead declines at the literal-cell postcondition; its flat twin compiles. Un-mark such an object (not a rail bank) or fold the dead store before the carve. | `RailBankPromote.cpp` (promoter / `markRailBankAllocas`) |

A and C both edit `QramLowering.cpp` but in DIFFERENT functions; merge them separately and
re-run the conflict file's lit slice after the second merge. Merge **B first** (it is the P1).
Wave 2, only after this wave's merge gate is green: `xdu2.7` (dynamic `bool`), `xdu2.5`
(`calloc`), `xdu2.6` (fresh bank per outer activation) — each needs its own design brief.

## Step 0 (orchestrator, BEFORE spawning) — make the C matrix shardable

`tests/e2e/run_railbank_dynamic_matrix.py` hard-codes `CASES`/`TWINS` for ONE source file, so
four tracks editing `railbank_dynamic_matrix.c` would collide and all re-run each other's cases.
Make the runner read its expectations from a sidecar (`<source>.cases.json`, same schema as
`CASES`/`TWINS`), move today's 27 cases into `railbank_dynamic_matrix.c.cases.json` unchanged,
and register one ctest entry per matrix source. Prove it with a null control (same 27 verdicts,
same twin result) and a mutant (flip one expectation → red). It is a harness change, so run the
full `ctest -j6` ONCE here (Rule 19 #3), then spawn.

## TEST OWNERSHIP — no two agents run the same test

Every track owns a **disjoint** fixture-name prefix, a disjoint lit filter, its own matrix
source, and its own e2e entries. Inside a track the inner loop runs ONLY what it owns:

| track | new fixture prefix | owned lit filter (`lit ir-pass/test --filter …`) | owned ctest (`-R`) |
|---|---|---|---|
| A | `railbank_readorder_` | `'railbank_readorder\|lowering_reject_railbank_dynamic'` | `'^e2e-slice-railbank-dynamic-int$\|^e2e-railbank-readorder-matrix$'` |
| B | `railbank_stale_` | `'railbank_stale\|stale_reader\|reader_predates'` | `'^e2e-railbank-register-twin-(decline\|selftest)$\|^e2e-railbank-stale-matrix$'` |
| C | `predmux_guarded_vla_` | `'predmux_guarded_vla\|runtime_vla'` | `'^e2e-railbank-guarded-vla-matrix$'` + its own new slice |
| D | `railbank_deadcell_` | `'railbank_deadcell\|railbank_literal\|railbank_promote'` | `'^e2e-slice-railbank-bool-\|^e2e-railbank-(flat\|uninit-zeroinit)-twin-identical$\|^e2e-railbank-deadcell-matrix$'` |

Rules for every track agent (put them verbatim in each spawn prompt):

1. Build ONLY in your worktree, both targets: `cmake --build build --target CQPass cq-opt`.
   Never touch the primary `build/`. Never relink a binary another process is measuring.
2. **Forbidden inside a track:** full `ctest`, the full `ir-pass-lit` entry or unfiltered
   `lit ir-pass/test`, `cq-opt-equivalence(-full)`, the corpus A/B, `e2e-loop-twin-matrix`, and
   any test outside your ownership row. Those belong to the orchestrator's merge gate and run
   ONCE per merge. If you believe you need a test you do not own, report it; do not run it.
3. Red-green (Rule 12): write your owned decline/accept fixtures FIRST, watch them fail on the
   `2143a535` binary, implement, watch them pass. Positive C coverage goes in YOUR matrix source.
4. Source-mutation injection over every new conjunct, with a NULL-CONTROL mutant first, detected
   only by YOUR owned tests (record MISSED honestly; add a fixture or document why it's shadowed).
5. Report: files touched, owned test results (quoted), mutation table, what you did NOT test.
   Do not commit to `main`, do not push, do not close beads.

**Rule-13 reviewers** (one per track, independent, spawned AFTER that track reports; disjoint
surfaces): they get a FROZEN copy of the track's binary and the diff, run hand/C probes only
(no suites), and return CLEAR / CLEAR-WITH-ITEMS / BLOCK with reproducers. Budget ≥2 rounds per
track; this area's measured hit rate is a P1 per first round (xdu2.4: two first-round P1s, both
pre-existing for fixed banks). Round 2 goes to a NEW reviewer.

## Merge gate (orchestrator only — the one place the shared suites run)

Per merged track, in order: rebuild both targets in the primary tree → the track's owned tests →
**full `ctest -j6`** (Rule 19 #1/#5) → `cmake --build build --target cq-opt-equivalence-full` →
corpus A/B against the pre-merge binary over every `ir-pass/test/*.ll` + stage-1 of every
`tests/e2e/*.c` + every matrix case + `example/grover/main.c` (null control first; report
A→D / D→A / decline-string / stream moves, and attribute every A→D) → exact Grover
compile/link/run → `python3 tools/update_code_map.py && --check` → `git diff --check`.
Do not run the shared suites in parallel with each other or with a track's rebuild.

## Close

File beads for anything left; update/close beads only when that track's Rule-13 rounds and the
merge gate are clear; append and seal the lab entry (`tools/labreport/build.py --seal`); commit;
`git pull --rebase && git push`; `git status` must say up to date with origin; remove worktrees.
