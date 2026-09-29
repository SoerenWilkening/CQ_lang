# Common brief — implementer agents, session 2026-09-28 (parallel)

You are an **implementer** for one bead (or a bead pair) of the CQ_lang compiler. The
orchestrator does not write compiler code; you do. `CLAUDE.md` in your worktree is the
operating manual — it is loaded for you; obey it (Prime Directive, Rules 0–19, the
Hallucination-Risk callouts). Your worktree is a fresh branch off `main` `9a230646`.

## Fixed paths

- **Frozen ORACLE** (main `9a230646`, code = `c1136be2`):
  `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646`
  sha-256 prefix `3f6db37f5cf937b4d70f5736`
  (also `libCQPass.main_9a230646.so` `356df92e0b58bbf787c41a25`, `cq-opt-debugalloc.main_9a230646` `36033dbf6641b168d7917bc4` in the same dir).
  Never write to that directory.
- **Session record dir** (create it in YOUR worktree):
  `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/`
  Your record: `TRACK_<BEAD>.md` there, probes under `<bead>_probes/`.
- Prior session's records (read what your bead cites):
  `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/`
  Reusable harnesses there: `xdu2_16_probes/ab.py` (corpus A/B; edit its hard-coded
  worktree path `W`), `xdu2_16_probes/ab_e2e.py`, `xdu2_16_probes/twins.py`, `vsfp_probes/`.
- LLVM tools: `/usr/local/opt/llvm@19/bin/{clang,opt,FileCheck,llvm-link}` (not on PATH).

## Build (in your worktree)

```
cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release
cmake --build build -j4
```
Never build `--target CQPass` alone (lit runs `cq-opt`; name all four:
`CQPass cq-opt cq-opt-debugalloc cq-scrub-selftest`, or build everything).

**LOAD DISCIPLINE — five agents share this 6-core / 12-thread box.** Use `-j4` for
cmake, `lit -j4`, and ≤4 workers in any corpus sweep. Never `pkill` by pattern. Never
relink a binary while a measurement of yours is running on it.

## The correctness criterion — the TWIN

The **hand-inlined / hand-unrolled twin defines the correct circuit.** Your fix must make
the subject **trace-identical to its twin** (same stage-4 trace; stage 2b STRICT clean), or
**decline with the twin's verdict**. "Verify-clean" and "runs" are not evidence (Rule 2).
Probe programs that take a runtime value must use `atoi(argv[1])`, never
`main(){return f(4);}` (bd `46oo`: `-O1` const-propagates it).

## What you owe

1. **Red-green (Rule 12).** Write the lit fixture(s) FIRST — positive `CHECK` for an accept,
   a negative `RUN: not %cq-opt … 2>&1 | FileCheck` mirroring the diagnostic
   character-for-character for a decline — watch them fail on the oracle, then implement.
   For a new/changed ACCEPT that runs from C: an e2e slice (`tests/e2e/`, see
   `run_slice.sh` / `run_slice_multi.sh` and how existing slices are registered in CMake)
   and a `*-twin-identical` ctest gate comparing it with its twin.
2. **Reuse existing owners (Rule 14).** Call the one predicate that already answers the
   question; never write a second spelling of it.
3. **L7 at the source.** Any comment your change falsifies is corrected in the same commit
   (the bead texts name several). A record correction that does not land in the source is
   not a correction.
4. **The L1 question** for every stage you touch that sits between the two control rounds
   (`repropagateControlMerges`): does a round-2 taint delta falsify your premise? If yes,
   RECORD and RE-ASK after the fixpoint in BOTH entry points.
5. **`TRACK_<BEAD>.md`**: mechanism (measured, not guessed — read the actual lowered IR,
   Rule 11), the fix and why it is sound, every predicate added/changed, the L1/L2/L3
   answers, what you ran LITERALLY with counts, movers, and an **"ATTACK FIRST" list** for
   the Rule-13 reviewers (where you would look to break it).
6. **bd**: `bd update <id> --append-notes "…"` (**NEVER `--notes`** — it REPLACES the whole
   notes field). Do **not** close the bead. You may `bd create` a new bead for a genuinely
   new finding (say INTRODUCED/PRE-EXISTING, measured on the oracle) and link it.
7. **Code map**: `python3 tools/update_code_map.py` then `--check`.
8. **Commit on your branch** (message ends with the attribution lines below). Do **not**
   merge, push, or edit `CLAUDE.md`/`ROADMAP.md` (put proposed CLAUDE.md text in your TRACK
   file). Do **not** self-clear — Rule-13 reviewers are independent agents.

## Measurement profile (light — owner request)

- **Every round:** full `cd build && lit -j4 ir-pass/test` (report "discovered/passed/
  XFAIL/failed"), the affected `ctest --test-dir build -R '<regex>'` entries, and every
  probe against its twin.
- **Corpus A/B vs the frozen ORACLE** over `ir-pass/test/*.ll`, the e2e sources
  (`ab_e2e.py`), multi-TU slices and the prior review probe dirs you touch: exit code,
  stdout sha-256, first error line. **Print the denominator. Run a NULL CONTROL FIRST that
  runs the SUBJECT twice** (it must move 0). Classify every mover (D→A, A→D, STRING,
  STREAM) and justify each one.
- **Mutants:** only for new/changed predicates, ≤8 plus one no-op null mutant (must move 0).
- **Once per bead** (your final round): allocator sweeps with `build/ir-pass/cq-opt-debugalloc`
  (`CQ_OPT_DEBUG_ALLOC=lifo` and `=nofree`; see `ir-pass/tools/cq_debug_alloc.cpp`) over
  the lit corpus, compared with plain `cq-opt` (exit/stdout/first error must agree).
- **NEVER on a branch:** the full `ctest -j6` (Rule 19 — the orchestrator runs it at the
  merge gate on `main`).

## Stop-and-ask conditions (report back instead of pressing on)

- The intended lowering proves genuinely hard/ambiguous and you are tempted to ship a
  decline of the very shape you were asked to build (Rule 17).
- You find a PRE-EXISTING P1 that your change newly routes programs into.
- The fix needs an owner-ruled semantic decision not already given to you.

## Traps measured last session

- zsh does not word-split `$VAR` — write sweeps as **bash** scripts (`#!/bin/bash`).
- `rc=$?` after a pipe reads the LAST stage's status (use `PIPESTATUS` or no pipe).
- A 0-byte `.ll` ACCEPTS through the passthrough early-out — check sizes. The filesystem is
  case-insensitive (`X.s1.ll` and `X.S1.ll` are one file).
- A stale `cq-opt-debugalloc` makes lit refuse to run — always check the denominator.
- A null control that runs the reference twice cannot see subject flakiness.
- IDE clang diagnostics in probe `.c` files / across worktrees are noise.
- AddressSanitizer does not run on this macOS; use Guard Malloc or `cq-opt-debugalloc`.
- `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.

## Report back (your final message)

Branch name, commit hash, `cq-opt` + `libCQPass.so` sha-256 prefixes, movers (with
classification), exactly what you ran with its literal counts, what you did NOT run, the
ATTACK-FIRST list, open questions, and any new beads filed.

## Commit attribution (end every commit message with these two lines)

```
Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01NouZgEuS5PVeoF7rVTKhxq
```
