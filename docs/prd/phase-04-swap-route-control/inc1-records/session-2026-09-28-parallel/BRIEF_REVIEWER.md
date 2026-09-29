# Common brief — Rule-13 REVIEWER agents (compiler-correctness code review), session 2026-09-28

You are an **independent adversarial reviewer** (CLAUDE.md Rule 13) of one implementer's
change. You did not write it and you must not trust its record: reproduce every key claim.
`CLAUDE.md` is loaded; obey it — especially the Prime Directive, Rule 2 (verify-clean is
never sufficient), Rule 10 (bugs are deep and interlocked), Rule 11 (skepticism), and §3 of
CORRECTNESS RISK (the standing lessons L1–L10). **Every verify-clean silent miscompile in this
project's history was found by a round like yours, never by the green suite.**

## Fixed paths

- **Frozen ORACLE** (main `9a230646`):
  `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646` (sha-256 `3f6db37f5cf937b4d70f5736`).
- **SUBJECT**: the implementer's worktree and binaries, given in your specific brief. Use them
  READ-ONLY. Never rebuild in the implementer's worktree.
- **Your private worktree** for mutants (at most ONE private build):
  `git worktree add <scratchpad>/rev_<round>_<bead> <subject-commit>` — remove it when done
  (`git worktree remove --force`).
- LLVM tools: `/usr/local/opt/llvm@19/bin/{clang,opt,FileCheck,llvm-link}`.
- **Output** (UNCOMMITTED, in the implementer's worktree record dir):
  `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_<round>_<bead>/REVIEW.md` + `probes/`.

## Efficiency rule (owner request — the process was too slow)

- Do NOT re-run the implementer's sweeps (lit, corpus A/B, mutation matrix). Read their
  counts; spot-check ONE.
- Budget: **30–90 minutes**. Load: `-j4` at most; five agents share the box.
- Test the argument, not the coverage. Start from the implementer's own "ATTACK FIRST" list (the weak points they name)
  and then go where they did not look.

## What a round must do

1. **Read the diff** (`git diff <base>..<subject>` in the implementer's worktree) and the
   TRACK file. Restate the fix's soundness argument in your own words; find the step that is
   ASSERTED rather than measured.
2. **Test with programs**: hand-written C (two-TU where relevant, runtime values via
   `atoi(argv[1])`, never `main(){return f(4);}`) AND hand-written IR. For every accept you
   construct, compare the subject's stage-4 trace with its HAND-INLINED / HAND-UNROLLED TWIN
   (the twin defines the correct circuit) and run stage 2b (`tools/free_pairing_check.py`).
   For every decline, check the twin's verdict agrees. Check the ORACLE on each probe so
   INTRODUCED vs PRE-EXISTING is measured, not guessed.
3. **Standing-lesson questions**, each answered in REVIEW.md with evidence:
   - L1: does any new/changed computation between the two control rounds rest on a premise a
     round-2 taint delta falsifies? Is it recorded and re-asked in BOTH entry points?
   - L2/L3: what other set / predicate names the same gate or closure? Was it widened or
     narrowed consistently — and if not, is the asymmetry SOUND (as with
     `preservesBorrowedParent`)?
   - L4: is any wire question answered by a return-first walker instead of a gate set?
   - L5: is any semantic question answered syntactically?
   - L7: does any comment (new or old) state a justification that is wrong or unruled?
   - Rule 14: is a predicate spelled twice?
   - Rule 12: is every new accept-predicate paired with a decline fixture whose subject still
     exists, and are negatives pure (no positive CHECK-COUNT inside a negative prefix)?
4. **Mutants** (≤6, in your private worktree): delete each new conjunct one at a time; a
   conjunct whose deletion leaves the full lit suite green is UNPINNED — file it. Run a no-op
   null mutant first.
5. **Composition**: what does this change do TOGETHER with the other changes landing this
   session (listed in your specific brief)? Name at least one program that exercises the
   composition, or say why none exists.

## Output format — `REVIEW.md`

- Header: subject commit + `cq-opt` sha-256, oracle path, diff range, time spent, what you
  ran LITERALLY (and what you did NOT run).
- **Verdict**: `CLEAR` / `CLEAR-WITH-ITEMS` / `NOT-CLEAR`.
- **Findings** `F-<round>-<n>`, each graded **P1** (wrong circuit / crash / unpinned
  accept-predicate that admits a wrong unitary) / **P2** (over-decline, unsound stated
  reason, unpinned conjunct, missing L1 re-ask with no reachable exhibit) / **P3**
  (comment/record/fixture hygiene), each tagged **INTRODUCED** or **PRE-EXISTING** with the
  oracle measurement that proves it, the probe file, and the exact repro command.
- **What you tested and did not break**, so the orchestrator can tell coverage from silence.
- You may `bd create` a bead for a confirmed finding (say which review found it); never close
  a bead; use `--append-notes`, never `--notes`.

## Final message to the orchestrator

Verdict, the P1s (with repro commands), the P2s in one line each, the P3 count, beads
filed, and the path of REVIEW.md.
