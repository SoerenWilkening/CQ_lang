You are the ORCHESTRATOR (Fable). You do not implement or review yourself; you spawn opus agents (Agent tool, model
"opus"), write briefs, judge output, keep the owner informed. Fable is permitted for ONE clearance review per increment.
Concurrency cap 6. Report only what you ran. Over-declining is safe; over-accepting is the one unforgivable bug. NO new
runtime symbol, ever (owner D3). Stop and ask the owner on any contradiction of a PRD §2 decision.

## State (main = origin/main = the eqpx landing (hash filled by the orchestrator: the squash of branch `eqpx-fix`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash); last docs commit after it, if any, noted in `git log`)
- bd `test_C_libtooling-eqpx` (P1) is CLOSED: landed 2026-09-06 as ONE squash commit of `eqpx-fix` (`git log main -1`) —
  the decline-only consumer tripwire (`cq loop lowering: in-place rail op no longer provable at lowering`, G2 alone at
  `lowerOps` Phase 1 for every `InPlaceRailOps` member W1–W3 marked) + the operand-INDEX form (`TaintSet::InPlaceRailIdx`
  via the single helper `markInPlaceRailOp`, consumed by `rewriteInPlaceValueRail`; inert on the corpus, live when wrong).
  Two opus lenses (CLEAR-WITH-ITEMS ×2, all items closed) + one Fable clearance (CLEAR-WITH-OWNER-QUESTIONS). Full ctest 367/367.
  Record: `docs/prd/phase-04-swap-route-control/inc1-records/session-7bbdb89e/` (README, six progress files, briefs,
  `eqpx_reproducers_r1/`), notes §3.16, PRD §0 E13, CLAUDE.md, ROADMAP.md.
- Counts: lit **1707** (1 XFAIL), ctest 367 (e2e 357 / slices 321 / twin gates 26), goldens 323, matrix 259+29.
- ORACLE = 52d7764 at `$SP0/wt/pre-3qlq` (session 0a61aa31 scratchpad; rebuild if `/private/tmp` was cleaned).
  Frozen binaries from this session: `$SP/bin/main-16b15b3` (pre-eqpx), `$SP/bin/eqpx-1333278` (the fix), the lens
  mutants `$SP/bin/{eqpx-m23,r1-mut-MA,r1-mut-MB,r1-mut-ME}` (`$SP` = session 7bbdb89e scratchpad).
- Harness: `$SP/harness/run.sh <file> <main|orac|fix|<tree-root>> [extra TUs]` (prints `imm=<rails-in-immediate-slot>`);
  reproducers `$SP/harness/p/` (= `session-82e6b530/eqpx_reproducers/`) and `session-7bbdb89e/eqpx_reproducers_r1/`.

## Open items in this order (owner's call)
1. OWNER QUESTIONS from the eqpx session (all docs-level, none a wrong unitary): (a) keep `InPlaceRailIdx`? — kept,
   argued in-source; (b) a header note on the pre-existing (1b) template fixture
   `control_phase_kickback_reject_preloop_commit_stale.ll` (its `CHECK-NOT`s are vacuous on a `RUN: not` line, the `not`
   inversion pins the property); (c) the pre-existing stale `AsLowered=true` citations in notes §3.14; (d) a
   capability-preserving SECOND WRITER ROUND on top of the tripwire (re-accept the 33 measured movers out of place) — a
   separate increment, never the fence.
2. 3qlq.13 (C-1 residuals incl. review_c1e F-C1E-2: a preheader op whose PARENT has a second unlowered tainted user),
   3qlq.14, 3qlq.9, .10, .11, .12, 67n5, OQ-11/12/13/22/23; then increments 3qlq.4 (bare tainted i1, one lens),
   3qlq.8 (i128 phase half), follow-ons .5 (UNSOUND BY DEFAULT), .6, .7.

## Read first
`bd prime`; `bd show test_C_libtooling-3qlq`; `session-7bbdb89e/README.md` and `briefs/BRIEF_common.md` (the template —
update its paths/hashes); notes §3.16; CLAUDE.md (Prime Directive; Rules 12, 13, 17, 19); bd memories
`eqpx-consumer-tripwire-2026-09-06`, `fix-that-predicts-a-later-stage-must-reverify-there`,
`once-only-stage-round2-false-premise`, `drbq-inc4-review-pattern`.

## Workflow that worked — repeat it
Oracle worktree first → briefs in the scratchpad from BRIEF_common.md (full context in every brief: bd ids, PRD §,
file:line anchors — cite NAMES where the numbers can move — strings verbatim, anti-stall rules; every agent keeps a
progress file) → implementer → ONE narrow lens per round → fix → lens → clearance (Fable, one) → full ctest (run it ONCE
on the final binary; tell the lens to READ the log rather than start a second ctest in the same tree) → ONE squash
commit → push → bd close → bd remember → session record under `inc1-records/session-<id>/` + a NEXT_SESSION_PROMPT.
If a lens finds a confirmed miscompile INTRODUCED by a fix, the next round is a NARROWING only; a third such round means
stop and ask the owner. Two traps paid this session: never write the tokens `CHECK-NOT:`/`RUN:` with their colon inside
fixture prose (lit parses by substring); an accept control without a `cqrt_free` count is blind to a dirty free.
