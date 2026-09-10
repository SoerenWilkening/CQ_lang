# Rule-13 round-3 brief — bd `r9e5` 1b-B.1: the round-2 BLOCK fix (re-verification under FINAL taint)

Branch `3qlq-inc1b-b-rail-select`; tree = checkpoint f8d29e8 + the F-B1R2-1 fix (`FIX_BRIEF_B1_R2.md`
decided it, `FIX_B1_R2.md` reports it). Round 2 (`review_b1_r2.md`) BLOCKED on F-B1R2-1 and listed in
its §6 what this round owes.

## What the fix is (read `git diff f8d29e8 -- ir-pass/` first)

* `TaintSet::RailCondReads` — every emitted RAIL READ (the rail's `cq_theta_i1` call and the FIRST
  emitted `cqrt_*` call that reads it), recorded at `CondTreeEmit` (the `CopyRailRoot` cnot; the first
  node gate reading a non-root rail leaf), `SwapRouteEmit::emitKickbackGroup` (the first `cqrt_rz_i1`
  on a rail — flat kickback and nest root) and `AngleSelectEmit` (its first rz on a rail).
* `reverifyRailCondReads` — a stage after `repropagateControlMerges`' fixpoint, in BOTH entry points of
  `CQLoweringPass.cpp`, that re-asks rung (ii) (`railMeasuredBeforeReadPoint`) and rung (iii)
  (`findNonDiagonalWireGate` position-free, then positional at the recorded read, with the FINAL
  `TaintSet`) for every record, with a fresh `DominatorTree`, declining loudly with the round-1 strings.
  The walker is blind to emitted `cqrt_*` calls (it looks for `cq_theta_` users), which is why
  re-asking after emission is sound. No prediction of what round 2 will taint; no change to the
  round-1 ladder; no change to `RotationLowering`.

## Attack it

1. **Completeness of the record.** Is there ANY emitted read of a rail that is NOT recorded — a rail
   leaf reached through a path the three sites do not cover (a shared rail read by two nodes; the
   nest's INNER rail as a toffoli control; the angle select's second rz; the 4.4 select's non-root
   rail whose first gate is inside `emitCondNode`'s Inverse (strip) emission — is the FORWARD gate the
   one recorded?); a rail read by `Specialization::mintCondNetwork` (it skips rail trees — measure);
   a rail read by `IOSinkLowering`/`AbortParkEmit`/`GuardedStore` paths (they decline rails — measure).
   Every emitted read must be re-verified or the window is still open one consumer over.
2. **Survival of the read point.** Can the recorded `cqrt_*` call be ERASED or MOVED between emission
   and the stage (a round-2 flatten erasing the pred block? `deleteGlobalPhases`? a second
   `lowerControlRegions` round hoisting? `RegionFlatten` merging blocks so `comesBefore`/reachability
   change meaning?) — a nulled `WeakTrackingVH` is SKIPPED by the fix; show a program where the skip
   loses a decline, or argue it cannot.
3. **The window itself, at other taint-growth events.** `repropagateControlMerges` is one growth
   event; CLAUDE.md records TWO (the bare `%out` is tainted at `lowerControlRegions`, one stage
   earlier). Also: a value tainted by a clone's specialisation (`Specialization`), by the loop
   collapse (`collapseFlattenedLoopRails`), by `IntrinsicLowering`, by QRAM. For each: can a rail's
   arg-0 be classical at the ladder and tainted at `lowerRotations` through THAT event, and does the
   stage run AFTER it? Measure with programs; the fix's placement is only as good as the last growth
   event it follows.
4. **The re-ask's own premises.** Rung (iii) positional re-ask at the recorded read: after the select
   is erased and the branch flattened, is "provably after every execution of the read" still the
   right question (loops: the read is now inside a straight-line body; `provablyBefore`'s
   reachability half — does a rolled region's back edge still defeat it? measure `k1`/`s18`-style
   programs through the fix path by making them round-2-tainted).
5. **Over-declines the stage introduces**: a program whose rail gains a round-2-tainted SIBLING theta
   that is genuinely AFTER the read (provably) — must still accept; a program where FINAL taint makes
   the CHAINED parent's parent tainted but the wire is unchanged; a rail measured through a name that
   is tainted only at round 2 but is a DIFFERENT rail (the stop rule) — must accept.
6. **The compare select is bd `9pum`, not this round's** — but say whether the fix's record could take
   compare seeds without a second stage, and whether anything in this fix makes `9pum` harder.
7. Assume a sixth thing. Round 1: 4 items, 0 miscompiles. Round 2: 1 miscompile in the area round 1
   listed as probed-clean. Pick the two areas round 2's §5 lists as clean that you trust least.

## Method and report

As before (`REVIEW_BRIEF_B1.md` §Method): A/B against the saved f8d29e8 pair the fix agent stored in
its scratch (`scratchpad/fix_r2/pre/`) and the pre-B.1 pair (`scratchpad/impl_b1/pre/`); re-run
round 2's corpus (`review_b1_r2_probes/run.sh`, `run_multi.sh`) and round 1's; ≥30 fresh programs.
Do not rebuild; do not edit `ir-pass/`/`tests/`/`tools/`. Report to `review_b1_r3.md`, probes to
`review_b1_r3_probes/`. Verdict BLOCK / CLEAR-WITH-ITEMS / CLEAR; only what you ran.

## Addendum after the fix report (`FIX_B1_R2.md`)

* The fix agent found a FOURTH read site the brief missed — the 4.3 nest's conjunction toffoli,
  emitted by `emitPhaseKickbackNestRegion` calling `emitCondNode` directly; for an inner rail it is the
  ONLY read. Probe `w5` (`if (b) { if (c) cq_phi(θ); }` with `c` off a `%out`-derived seed) ACCEPTED
  on f8d29e8 with `ry(h,.5); ry(h,.9); toffoli(h,…,g)`. So the recording lives inside `emitCondNode`
  (the `markBranchPhaseGate` lesson: every emission site, or none). Attack the "these four sites are
  ALL of them" claim structurally (`FIX_B1_R2.md` §4 item 3).
* `e07` (the sibling AFTER the select) accepts on both binaries; the fix agent derives it correct via
  the DT prong. Re-derive it independently — "the sibling is after the read point" is the kind of
  claim to re-check (and try the loop/round-2 variants of it).
* "One diagnostic per RAIL": the reader stops at the first decline for a rail; a kickback records one
  entry per group. Look for an emitter that reads one rail at two positions with user code between.
* `c/e02` already declined on f8d29e8 (its `static f` inlines at `-O1`, making it a round-1 program);
  the two-TU `multi/e16` is the plain-C window and is pinned as its linked stage-1 module
  (`control_swap_reject_select_rail_round2_plainc_twotu.ll`) — there is no e2e decline mode.
* The compare select stays untouched (`e08`/`e13` byte-identical) — bd `9pum`.
