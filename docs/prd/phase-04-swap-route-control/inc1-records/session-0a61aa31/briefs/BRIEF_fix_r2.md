# BRIEF_fix_r2 — Inc 1, Rule-13 ROUND-2 FIX agent
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_fix_r1.md`, `$SP/progress/fix_r1.md`, then
`$SP/progress/review_r2_R1.md` IN FULL (and `$SP/progress/review_r2_R2.md` when the orchestrator sends it).
Agent name: `fix_r2`. Model: opus.

## Where you work
Worktree `$SP/wt/fix-r1`, branch `3qlq-inc1-fix-r1` at c4bd888 (= main's tip; build current). Never touch
main (lens R2 is running against it). SUBJECT-BEFORE = main's binary at c4bd888; ROUND-1 SUBJECT =
`$SP/wt/r1-subject` (fa96336); ORACLE = `$SP/wt/pre-3qlq`.

## F-R1-1 — CONFIRMED rolled≠unrolled divergence (fix, then ask what else runs once)
`for (i<3) if ((y>>i)&1) cq_phi(θ)` where `y` is an ONWARD 6.5 classical-call-arm rail: 0 `and_unc`, 3
leaked entangled rails; the hand-unrolled twin discharges all three; declines on fa96336 (the round-1 fixes
CREATED the population). Root cause (R1, measured with a discriminating control): `collapseFlattenedLoopRails`
— the ONLY caller of `invariantRegisterRoots`/`markIfRailLocal` — runs ONCE at `CQLoweringPass.cpp:393`,
BEFORE `repropagateControlMerges` (:409); an onward region is claimed and flattened at round 2 inside
`detectAndLowerOnwardControl` (`TaintPropagation.cpp:1550`), which never calls the collapse; at round 1 `y`
is not even tainted. FIX options: (a) run `collapseFlattenedLoopRails` again after `repropagateControlMerges`
with round-2 taint (the F-L3-1 repair shape) — then enumerate EVERY OTHER stage that runs once before
round 2 and whose premise is round-2-false (`declineStaleRecordOps`? `lowerLoops`? the classical-mux guard?
the FreePoint/uncompute interplay for round-2 regions?) and write a decision for each in the notes; or (b)
decline a region whose entry is in a loop when claimed at round 2. Try (a); measure rolled == unrolled on
R1's `p/o_onward_inloop{,_unrolled}.c`, its control `_ctrl.c`, `_interf.c`, and the Q-R1-1 hoisted-temp
pair; pin with `control_phase_kickback_onward_inloop.ll` (ACCEPT, `UCNT-COUNT-3` of `and_unc` in the body)
and a red-green against main's binary; add an e2e pair + `cmp` gate under prep-b's naming
(`slice_control_phase_onward_perbit_loop{,_unrolled}.c`) — write the .c files into
`$SP/wt/prep-b/tests/e2e/`? NO — prep_b2 is working there; put them in your tree under `tests/e2e/` and
the orchestrator merges.

## F-R1-2 — OVER-DECLINE introduced by F-L5-6
An UNCONTROLLED `cq_phi` after a 7.2 abort park declines `phase-class value escaping under quantum
control`: the three carriers ask `reachedThroughTaintedBranch` (`TaintPropagation.cpp:1640`, "ANY tainted
branch on ANY path") BEFORE `lowerControlRegions`, when every tainted `br` still stands, so "reached from"
is answered where the header promises "CONTROL-DEPENDENT ON". Fix at :1640: a phase call whose block
POST-DOMINATES the tainted branch's block (or is reached from BOTH successors) is a global phase, not a
branch phase. Pin: ACCEPT `control_phase_kickback_abort_global_phase.ll` (R1's `p/g_abort_uncond_phase.c`,
byte-identical to the no-phase circuit) + a DECLINE for the genuine escaping-branch-phase subject so the
fence stays a discriminator; correct the notes' "LATENT at this HEAD" sentence (measurably false for abort).

## F-R1-3/4/5 — doc truth
- `ChainWalk.h:122` + notes:64 say THREE emission sites; there are FIVE (`SwapRouteEmit.cpp:1539, :1569,
  :1774`, `AngleSelectEmit.cpp:179/181`, `SwitchRouteEmit.cpp:169→179`) — enumerate all five and add a lit
  assertion that keeps the enumeration honest (R1's `mdsweep.sh` idea: count `CreateCall(Rz` sites? no —
  a fixture per site already exists; state the five in the comment and cite the MDCNT fixtures).
- The F-L7-1 closure table omits `preservesBorrowedParent` clause (1) (`Uncomputation.cpp:591-597`), a
  `cqrt_rz_` NAME test that ADMITS the kickback gate (soundly — diagonal ⇒ label preserved; reached by
  `p/u8_share_tail.c`). Add the row, say the verdict is sound and MUST NOT be narrowed "for symmetry".
- `ChainWalk.h:116` reason (3) for metadata ("survives CloneFunctionInto") is unreachable at HEAD by
  F-L3-3's own fix (any cq_phi in a callee is a loud reject) — restate as a property.
- F-R1-6 (a D2 global phase inside a specialization candidate is refused, pre-existing) — record as an
  owner item in the notes, no code change.

## Also
Red-green every fixture against main's binary; STRICT 2b on every reproducer; `RETIRE_SWAP_ROUTE_INC1_NOTES.md`
§2 (round 2); lit on your binary in the background (red partition ⊆ retired-family set; report anything
else); commit per finding; hand back per BRIEF_common with the round-2 "what else runs once" table.
