# NEXT SESSION PROMPT — after session adc5590a (2026-09-06)

You are the ORCHESTRATOR (Fable). You do not implement or review yourself; you spawn opus agents (Agent tool,
model "opus"), write briefs, judge output, keep the owner informed. Fable is permitted for ONE clearance review per
increment.

## Read first
1. `bd prime`; `bd show test_C_libtooling-3qlq` (epic notes carry the state) and its open children `.4 .5 .6 .7 .8
   .9 .10 .11 .12 .13 .14`, plus `67n5`, `eqpx` (P1), `7yd0` (P2).
2. `docs/prd/phase-04-swap-route-control/inc1-records/session-adc5590a/` — README, `clearance2.md`, `inc2/README.md`,
   `inc2/clearance_inc2.md`, `c1-round4/` (round 4's reproducers), the `review_c1d.md` lens report (verdict:
   CLEAR-WITH-ITEMS), and `briefs/` (BRIEF_common.md is the template; `BRIEF_rebase_c1d.md` is the unused next step).
3. `retire-swap-route-PRD.md` §0 ERRATA (E1–E12), `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.1–§3.14,
   `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1–§5.
4. bd memories: `3qlq-inc1-landed-2026-09-06`, `3qlq-inc2-landed-2026-09-06`,
   `fix-that-predicts-a-later-stage-must-reverify-there`, `rolled-idiom-needs-body-gate-or-invariant-root`,
   `once-only-stage-round2-false-premise`, `drbq-inc4-review-pattern`, `workflow-model-tiering`.

## State (main = origin/main = 258d974)
- Inc 0 + Inc 1 LANDED (a3c1513); Inc 2 LANDED (258d974). The swap route is fully retired (`cqrt_cswap` = `AbortParkEmit`
  only). Full ctest 361/361 at the Inc-2 tree; main rebuilt and lit/runtime green.
- **C-1 round 4** (bd `7yd0`, the `hasOneUse` retirement under the tripwire): branch `c1-round4` at 59f6a95 (base
  a3c1513, PUSHED, NOT rebased onto 258d974, NOT landed). Full ctest 351/351 on its tree. Lens `review_c1d` verdict:
  CLEAR-WITH-ITEMS — the hasOneUse retirement is a narrowing of a proxy onto the real predicate; the tripwire is the ONLY net (deleting it on a mutant reproduces the round-2 wrong unitary byte-identically); 0 class flips over 615 programs, all 20 movers gain discharges; F-C1D-1 the leak (bd 7yd0) is LIVE on landed main 258d974 in D4's own idiom (q4b/q5sel/g1/k3 rolled 4/0 vs twin 4/4) so the rebase+landing is a CORRECTNESS OBLIGATION and mechanical (Inc 2 did not touch LoopLowering/matrix); F-C1D-2 re-run control_swap_value_ifelse_head_out_of_place.ll + the value twin gates on the rebased tree (Inc 2's ArithLowering CONSUMER-2 comment); F-C1D-3 three closure-table refinements incl. the F-3 row (staleRailRecordRead's SKIP set is the chain, AsLowered=false, cannot shrink); F-C1D-4 add an extra_ry row to the injection matrix.
- Owner stopped the session after that lens ("stop after this agent finished").

## Step 1 — land round 4 (if the lens verdict allows)
Per `briefs/BRIEF_rebase_c1d.md`: rebase `c1-round4` onto 258d974 (docs-only conflicts expected), rebuild, re-run its
gates, RE-MEASURE `q4b` (Inc 2's value-merge + preadd spelling — must be rolled == unrolled now; add it as a fixture +
e2e pair + `cmp` gate), fold in any lens items, full ctest -j6, ONE squash commit onto main, push, `bd close 7yd0`,
`bd remember`. If the lens found a CONFIRMED miscompile: do NOT land; bring it to the owner.

## Then (owner's call — rulings needed)
- **`eqpx` (P1)**: PRE-EXISTING silent miscompile on main since before 3qlq — an in-loop in-place XOR whose immediate
  is derived from an onward `%out` emits a rail handle in the immediate slot. Proposed fix: re-ask G2 at `lowerOps`
  for every `InPlaceRailOps` member, decline loudly. Fix before anything else?
- `3qlq.13` (OQ-C2-1..4 C-1 residuals: `m11d` is G7 arm (e), `short`/sext oracle regression, Q-R1-1 disclosure
  widening), `3qlq.14` (diamond-vs-select asymmetries: base-from-cond, rotation-after-region, gate-5 seeding),
  `3qlq.9` (interleaved regions flat over-decline), `.10` (OQ-29), `.11` (OQ-21), `.12` (Q-R2-1/3), `67n5`
  (measure/ret-sink stale read), OQ-11/12/13/23 (Inc 2), OQ-1..OQ-29 standing.
- Increments: `3qlq.4` (bare tainted i1, one-lens), `3qlq.8` (phase half of the i128 condition), follow-ons `.5`
  (UNSOUND BY DEFAULT under the dirty chain-final leak), `.6`, `.7`.

## Workflow that worked — repeat it
Briefs in the scratchpad (copy `briefs/BRIEF_common.md` and update the paths/hashes) → implementer → ONE narrow lens
per round → fix → lens → clearance (Fable, one per increment) → full ctest → ONE squash commit → push → bd close →
bd remember. Report only what you ran. Over-declining is safe; over-accepting is the one unforgivable bug. If a lens
finds a confirmed miscompile INTRODUCED by a fix, the next round is a NARROWING only; a third such round means stop
and ask the owner. Save each round's binary before rebuilding (red-green needs it). The pre-3qlq ORACLE build lives in
the session-1 scratchpad worktree `wt/pre-3qlq` (52d7764) — rebuild it from that commit if /private/tmp was cleaned.
