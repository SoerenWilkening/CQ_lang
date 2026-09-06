# Session start — bd epic test_C_libtooling-3qlq, CONTINUATION: land Inc 0+1 (fix C-1 + re-clearance), then Inc 2

You are the ORCHESTRATOR (Fable). You do not implement or review yourself; you spawn opus agents (Agent tool,
`model: "opus"`), write briefs, judge output, keep the owner informed. Fable is permitted for ONE clearance
review per increment (this change can free a rail / alter a unitary silently).

## Read first, in this order
1. `bd prime`; `bd show test_C_libtooling-3qlq` and children `.2`, `.3`, `.4`, `.8`, `.5`–`.7` (the epic
   and .1/.2/.3 notes carry the state).
2. `docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/` — READ `clearance.md` FULLY (the
   BLOCK verdict, C-1's root cause, the B3 fixture, the unpinned shapes), then `OWNER_QUESTIONS.md`
   (OQ-1..OQ-29 with the dispositions taken), then skim the round reports and `briefs/` (BRIEF_common.md
   is the template every agent brief inherits; BRIEF_review_inc2_r2.md is the unused Inc-2 round-2 brief).
3. `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` (§0 ERRATA first) and
   `RETIRE_SWAP_ROUTE_INC1_NOTES.md` (§1, §2, the once-only-stage table), `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1.
4. bd memories: `3qlq-inc1-not-landed-clearance-block-2026-09-05`, `once-only-stage-round2-false-premise`,
   `kickback-gate-must-be-opaque-to-the-spine`, `fixture-repairs-propagate-to-every-family`,
   `keep-alive-idiom-retired-3qlq`, `rolled-idiom-needs-body-gate-or-invariant-root`,
   `drbq-inc4-review-pattern`, `workflow-model-tiering`, `api-session-limit-kills-agents-relaunch-from-progress`.
5. `CLAUDE.md` (Prime Directive; Rules 12, 13, 17, 19). NO new runtime symbol, ever (owner D3).

## State (main = origin/main = dfb8e83; NOTHING of the epic is on main)
- Branch `3qlq-inc1` (pushed; tip bcf3fd2): Inc 0 + Inc 1 fully implemented, migrated (1656 fixtures,
  ir-pass-lit green with the standing XFAIL), 304 goldens regenerated under the extended audit, twin matrix on
  the void surface (245 rows, 29 quarantined), docs updated; full `ctest -j6` 338/339 at be4e2ea (the one red
  was a fixture re-pointed in cd2f071; re-run green). Two Rule-13 rounds + a flips lens + a clearance were run.
- **Clearance verdict: BLOCK on C-1.** Reproducer `inc1-records/session-0a61aa31/clearance_c1/d1i_mixed_invariant_interf.c`
  (+ `_unrolled` twin + both traces): `int q=cq_theta(u,.5); int r=cq_theta(u,.3); for(i<3){ if((q>>i)&1)
  cq_phi(.2); r=cq_theta(r,.1); } q=cq_theta(q,.9);` — a loop-INVARIANT root register under D4's per-bit
  condition PLUS a second loop-CARRIED register: rolled mints `and_i32_hl(h0,1/2/4)` and never `_unc`s/frees
  them (3/0), then runs `cqrt_ry_i32(h0,.9)` with three which-path records live; the hand-unrolled twin
  discharges (3/3); the pre-3qlq oracle on the old-surface twin discharges too (37 = 37). opt exit 0,
  verify-clean, STRICT 2b 0 violations (blind by design). Root cause `LoopLowering.cpp` ~3163-3177 +
  ~2877-2887: `collapseFlattenedLoopRails` takes `Collapsed` for `r` and hands `markIfRailLocal` only `r`'s
  roots; `invariantRegisterRoots` (the F-L5-1 fix) is reached only on `NotClaimed` and its clause (i) refuses
  any tainted header phi — the mixed loop is served by neither path, although the fix's own (I1) proof covers
  the root mint. Population (clearance §2): carried register rotated / xor'd in place / itself a kickback
  condition; a P3 tree with the per-bit leaf; K=32 (32 leaked rails); dead q (leak, no dirty free).
- Also owed (clearance §4): a fixture for B3 `early break preserves a phase answer` — now plain-C reachable
  (`clearance_c1/f1_break_kick_before.c`, fixture-ready .s1.ll beside it); the flat over-decline of
  interleaved round-1/round-2 sequential regions (`b2u`/`b6u` decline `control flow` while rolled accepts);
  OQ-29 (decl-only unused retired `@cq_phi_<sfx>` is SWEPT; tighten to the reserved-name rule now the corpus
  is migrated?); PRD §0 E2 must say C-1 is a THIRD thing the per-bit fix does not cover until fixed.
- Branch `3qlq-inc2` (pushed; tip 87a90d7; base dfb8e83): Inc 2 implemented + round-1 reviewed (0
  miscompiles) + round-1 fixed (lit 1593/1 XFAIL, e2e 330/330, 4 cmp twin gates). NOT rebased onto Inc 1.
- Worktrees from the last session lived under /private/tmp (scratchpad) and are probably GONE: run
  `git worktree prune`. Build fresh: ORACLE from 52d7764 (`git worktree add <scratch>/wt/pre-3qlq 52d7764`,
  cmake configure + `cmake --build build -j8` — BOTH CQPass and cq-opt), and a PRE-FIX SUBJECT from bcf3fd2
  for the C-1 red-green. The main checkout is on branch `3qlq-inc1` with `build/` at bcf3fd2 (verify mtimes).

## Step 1 — the C-1 fix round (bounded), then RE-CLEARANCE, then LAND
1. Fix agent (opus) on `3qlq-inc1`: admit invariant root mints beside carried roots in
   `collapseFlattenedLoopRails` (the same (I1) proof `invariantRegisterRoots` uses) — OR, if that cannot be
   proven bounded, decline the mixed shape loudly. Red-green: lit pair (`control_phase_kickback_inloop_mixed_
   invariant_carried.ll` accept with `UCNT-COUNT-3` of `and_unc`; a decline twin for whatever stays refused),
   e2e pair + `cmp` twin gate from `d1i`/`d1iu`, a second-carried-register AXIS in `tools/loop_twin_matrix.py`
   (the 274-cell matrix cannot see C-1 — no such axis), PRD §0 E2 + NOTES §3 updated; plus the B3 fixture.
   Then ask the 8h7d.5 question: what OTHER set is computed over the closure you widened (the two collapse
   passes, Q-R1-1's template-rail residual, `IterationLocalBlocks` sharing — Q-R2-1)?
2. One narrow lens on the fix (both binaries + oracle; rolled == unrolled on every population member).
3. Clearance (Fable allowed): re-run `clearance.md`'s three questions; verdict decides.
4. Full `ctest -j6` (Rule 19 gates 1 and 5; ~400 s), then ONE squash commit of `3qlq-inc1` onto main (message
   draft: the old scratchpad's COMMIT_MSG_inc1.md is gone — write it from `clearance.md` + the notes: the
   four confirmed classes and their fixes, counts measured by command), `git pull --rebase && git push`,
   `git status` up to date, `bd close test_C_libtooling-3qlq.1` and `.2`, `bd remember` the landing.

## Step 2 — Inc 2 (bd 3qlq.3)
Rebase `3qlq-inc2` onto the landed Inc 1 (overlap: `SwapRouteEmit.cpp`, `ArmClassify.cpp`, `ControlPlan.h`,
`SwitchRouteEmit.{h,cpp}` value-side comments — expect conflicts, value path vs phase path); rebuild; re-run its
four `cmp` twin gates and the 14-accept injection matrix; ROUND 2 = one lens per `BRIEF_review_inc2_r2.md`
(the "emitSelectRegion reachable with a coherent operand" flag re-asked — a KICKBACK-PHASED register is the new
coherent operand class; value×kickback interplay; the dirty chain-final class vs Inc 1's invariant-root
discharge — and now also vs the C-1 fix); fix; clearance; full ctest; ONE commit; push; `bd close 3qlq.3`.

## Then (owner's call)
3qlq.4 (bare tainted i1 condition, one-lens), 3qlq.8 (phase half of the unclaimed i128 compare condition),
follow-ons .5 (UNSOUND BY DEFAULT under the dirty chain-final leak — needs the deltas/finals discharged first),
.6, .7 (if/else with ≥2 cq_phi per arm: two selects / two tail phis on one flag). Open owner questions are
all in OWNER_QUESTIONS.md; the ones that need a RULING (not a revert) are OQ-1 (linear rule enforced for pure
ops only), the loop-INVARIANT-condition over-decline (drbq.12 at the phase stem), P5's missing plain-C
customer (table-fold recognizer?), P2 inside a rolled loop, Q-R2-1/Q-R2-3 (once-only stages), Q-R1-1,
OQ-21 (a defined `void cq_phi(double)` body is silently captured), OQ-23 (V2's basis-state evaluator as an
instrument), OQ-25, OQ-27/28, OQ-29.

## Workflow that worked — repeat it
Oracle worktree first → briefs in the scratchpad (copy `briefs/BRIEF_common.md` from the record dir; every
brief gives full context: bd ids, PRD §, file:line anchors, strings verbatim, anti-stall rules) → implementer →
N parallel READ-ONLY lenses against BOTH binaries (each compiles/links/runs every twin it cites) → ONE fix agent
→ 2 narrower lenses → fix → clearance → full ctest → commit → push → bd close → bd remember. Concurrency cap 6.
Report only what you ran. Over-declining is safe; over-accepting is the one unforgivable bug. Stop and ask the
owner on any contradiction of a PRD §2 decision or a §12 assumption.
