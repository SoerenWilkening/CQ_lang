# Next session — orchestrator prompt (written 2026-09-11 at the close of session `01NHxGVinGBKbb499HFCuwhT`)

You are the ORCHESTRATOR for this session of CQ_lang (`/Users/sorenwilkening/Desktop/CQ_lang`, `main` at
the hash `git log -1` shows, ≥ e96f89c). **Every agent you spawn is `model: "opus"`** — the owner said on
2026-09-11, verbatim, "you are only allowed to spawn opus agents", and the orchestrator does NOT run
builds, ctest or the pipeline itself: it spawns an opus agent for that too (memory `workflow-model-tiering`).
You own the briefs (bd ids, `file:line` anchors, predicates verbatim, the pipeline commands, what NOT to
touch, "do not commit", "report only what you ran"), the gates (full `ctest -j6` before any Rule-13-core
commit; `cq-opt-equivalence-full` after any diagnostic-surface change), the landing (one squash commit per
increment on `main`, branch tip in the message; every landing after the first is a MERGE-AND-GATE in the
track's worktree first — see `LANDING_PLAN.md` beside this file — and beware a merge RESURRECTING a
`git mv`'d fixture, memory `merge-resurrects-git-mv-fixture`), the lab-report entry, the handoff and the
owner conversation. Read first: `CLAUDE.md` (the Prime Directive; Rules 1/2/12/13/17/19; the
CORRECTNESS-RISK paragraph "SESSION 2026-09-11 — FOUR LANDINGS AND THE OWNER'S FILE COMPILES" and its
neighbours "INCREMENT 1b" / "INCREMENT 1b-B.1"; Session Completion), `bd prime`, this directory
(`LANDING_PLAN.md`, `REVIEW_BRIEF_INTEGRATION.md`, `review_integration.md`), PRD
`retire-swap-route-PRD.md` §13–§15, and the lab report entry 004.

## What the owner ruled on 2026-09-11 (binding until the owner says otherwise)

1. **Expressiveness first.** "our end-goal is to not decline any code that will lead to a valid quantum
   circuit (over decline). we want to be able to express as many quantum algorithms as possible." An
   over-decline of a valid circuit is a DEFECT to file and remove; the Prime Directive (never over-ACCEPT)
   is untouched. Every review brief now grades OVER-DECLINE explicitly.
2. **Option 1** for the compare-select holes: fences first (Track A.1, LANDED 7203d1c), then the
   widenings (bd for "Track A.2", filed).
3. **H-3 = ADMIT** — the S† after a VALUE region is the Grover cascade's own idiom; the 6.5 path already
   accepts it; the value diamond's P1 refusal is inherited from the retired route (part of A.2).
4. **The `i1` state-prep decline is REVERSED.** "WE DO NOT WANT TO WRITE int b1. also WE DO NOT WANT ANOTHER
   cq function. it should just be an application of gates". Track C narrowed F2 (LANDED a9cc062).

## State at close

* **`main`** carries four squash landings: A.1 7203d1c (compare-select fence parity: r10v + 9pum +
  r903(b) + the pre-existing 7.6/7.5 flag-mint hole 61k6, all CLOSED), b6ap 3a3a2b9 (the multi-phi merge
  peel, CLOSED), F2 a9cc062 (the CondWire narrowing, noted on drbq.14), l4x4.b e96f89c (the bool
  controlled-Ry arm + state prep incl. negation; l4x4 stays OPEN for l4x4.a and l4x4.c).
* **The owner's `example/grover/grover_oracle_uncompute.c` COMPILES AS WRITTEN** (`bool b0`, `bool b1`):
  exit 0, empty stderr, 19 trace lines, STRICT stage 2b clean — `MERGE_l4x4_2.md` has the stream. Re-run it
  FIRST in Step 0 (`./tools/show_pipeline.sh example/grover/grover_oracle_uncompute.c`, via an agent); the
  file is git-excluded and the owner may have adjusted it again. If it declines, name the wall against
  the open list below before anything else.
* Counts (measured at e96f89c): lit 1893 · goldens 355 · ctest 403 (`^e2e-` 393, `^e2e-slice-` 353,
  `twin-identical` 30) · twin matrix 259 + 29 quarantined.
* Integration review (the four capabilities as ONE binary): verdict recorded in `review_integration.md`
  — **CLEAR-WITH-ITEMS** (no confirmed miscompile in the combination; 770 corpus rows, 0 both-accept circuit changes; items: I-1 the peeled compare CLONE is the F2 collider for a bool prep under an int compare in a fused diamond — bd `rb9x` corrected; I-2 `cq_invert` around the file accepts and fails to link — Phase 8, bd `ixao`; I-3 a new `3d8q` customer; I-4 `b0` measured before the fused region is a policy decline). No fix landed after it; the three ERRATA lines it required are in the closing docs commit.
* Worktrees `../CQ_trackA`, `../CQ_b6ap`, `../CQ_f2`, `../CQ_l4x4` exist with their branches (all landed;
  safe to `git worktree remove` once the next session has re-measured `main`).

## Open work, in the order that compiles the most C (the owner's stated goal)

| bd | what | why it matters |
|---|---|---|
| **A.2** (filed today; grep `bd list` for "Track A.2") | S† after a compare select (DT prong for compare seeds) UNDER a new live-arm-chain-rail fence; P1's `SawValueArm` retirement for disjoint chains; `AllowLogicalSelect` for data selects | three measured plain-C over-declines on the most common control shape; the S11b fence is REQUIRED first (a chain rail left entangled on the condition wire, invisible to stage 2b) |
| `rb9x` | F2 follow-on: a bool prep under an INT compare in a FUSED diamond still collides — on b6ap's peeled compare CLONE (integration review I-1 corrected the ground; the region's own compare IS excluded) | ordinary code; exclude the clones (the condition value re-spelled) on the same 2026-09-11 argument; rewrite `MergePhiPeel.cpp`'s false comment with it |
| `54ur` | the 6.5 classical-call arm on a bool (SCOPE_B2 §2.1; H-3 = admit) | plain-C reachable, ~35–50 lines |
| `l4x4.a` | the Ry-stem ANGLE SELECT on a bool (`if (b) r=Ry(r,A); else r=Ry(r,B);`) | cheapest half of l4x4, no `cqrt_x`, `AngleSelectEmit`'s Ry stem |
| `boi6.a` | the loop-CARRIED bool as a phase condition (header phi; SCOPE_boi6 D-A; answer H-1 — the reverify-vs-collapse slot — with the owner first; pin the two unpinned accepts `p2`/`p9` regardless) | Grover as a loop on a bool; needs a `_Bool` axis in the loop twin matrix (none exists) |
| `wx8g` (l4x4.c) | the IN-LOOP bool-controlled rotation/prep | compiles in NO spelling today; a rolled Grover with a controlled prep |
| `r903` (1)+(2) | negated nest level + `!b && …` (one capability at two levels; (3) has no C customer; (a) a narrowing-only round; (b) LANDED with A.1) | plain C after De Morgan |
| `35t0` | hcrg over-decline: a 6.5 arm followed by any flat region (`reorderable()` admits two kinds) | valid circuit, filed from l4x4's review |
| `3d8q` | theta/measure stale readers (population WIDENED by the peel: a mux out-rail as the shared parent) | P1 pre-existing miscompile, own guard in `OpcodeLowering.cpp` |
| `lo7u` | the 4.5 switch mints from a measured scrutinee (hand IR so far) | pre-existing, A.1's rung cannot reach `emitEqFlag` |
| `boi6.b`, `fg9k`, the 57-cell injection debt, `6uqc`'s lost M-A pin | later | |

## Method that worked today (keep it)

Scoping agents first (read-only, measure-first `SCOPE_<id>.md`), one implementation agent per track in
its OWN worktree + build dir, the primary `build/` frozen as the ORACLE for every A/B, an independent
opus Rule-13 round per increment (today: A.1 r1 BLOCK, b6ap r1 BLOCK, F2 r1 CLEAR-WITH-ITEMS, l4x4.b r1
CLEAR-WITH-ITEMS — budget two rounds minimum), fix agents with a written brief per finding, a
merge-and-gate agent per landing (full `ctest -j6` on the merged tree, every corpus re-run on the merged
binary, movers explained), then an INTEGRATION round on the merged tree. Never relink under a running
measurement; never `pkill` by pattern (memory `never-relink-or-pkill-under-measurement`). The usage limit
resets on the hour boundary the error names — relaunch, don't wait for it to self-heal.

## Session completion (non-negotiable, `CLAUDE.md`)

File follow-ups in bd; full `ctest -j6` before any core commit; one squash commit per increment; `bd
remember` every lesson; lab-report entry 005 (`docs/labreport/TEMPLATE.tex`, ≤5 pages,
`tools/labreport/build.py --seal`, commit the sources never the PDF); `git pull --rebase && git push`; the
next `NEXT_SESSION_PROMPT.md` in the session's record dir.
