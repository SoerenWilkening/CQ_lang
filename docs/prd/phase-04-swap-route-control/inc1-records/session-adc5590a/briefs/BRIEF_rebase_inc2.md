# BRIEF_rebase_inc2 — REBASE Inc 2 (bd test_C_libtooling-3qlq.3, branch `3qlq-inc2`) onto the LANDED Inc 1, rebuild, re-run its gates
Read `$SP/briefs/BRIEF_common.md`, then `bd show test_C_libtooling-3qlq.3`, then from the repo record dir
`docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/`: `impl_inc2.md`, `fix_inc2_r1.md`,
`review_inc2_V1.md`, `review_inc2_V2.md`, `briefs/BRIEF_impl_inc2.md`; then on the branch itself
`RETIRE_SWAP_ROUTE_INC2_NOTES.md` (§1 — esp. §1.11 "what worries me"; `git show 3qlq-inc2:docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC2_NOTES.md`),
and the PRD §7 (value arms) + §0 ERRATA E1 (the dirty chain-final). Agent name: `rebase_inc2`. Model: opus.

## Where you work
Worktree `$SP0/wt/inc2` is on branch `3qlq-inc2` at 87a90d7 (base dfb8e83 = the pre-Inc-1 main; BUILT).
Do the rebase THERE (it is Inc 2's own worktree):
`git -C $SP0/wt/inc2 rebase __INC1_LANDED__` (the landed Inc-1 commit on `main`, = __INC1_LANDED__).
Expect conflicts in exactly these six files (measured by `comm` over the two `git diff --name-only` lists):
`ir-pass/src/SwapRouteEmit.cpp` (the big one — Inc 1 DELETED the phase-arm route from it and added the
kickback emitters `emitPhaseKickbackRegion` / `emitPhaseKickbackNestRegion` + `markBranchPhaseGate` calls;
Inc 2 REPLACED its value-arm path with the hoist + `emitSelectRegion` merge), `ir-pass/include/ControlPlan.h`,
`ir-pass/src/EmitInverse.cpp` (Inc 1: `isInverseEmittable` refuses `!cq.branchphase`; Inc 2: the cswap-seam prose),
`docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` (§0 ERRATA: Inc 1 wrote E1–E9 + the status
header; Inc 2 wrote E1's dirty-chain-final text — keep BOTH, E1 is Inc 2's), `tests/e2e/CMakeLists.txt`
(both added blocks; keep both; re-count), `ir-pass/test/control_swap_value_diamond_derived.ll` (Inc 1 migrated
it off the register `cq_phi`; Inc 2 re-derived it for the merge — RE-DERIVE it from the REBASED binary's
output, never hand-merge CHECK lines). Resolve by INTENT, not by side: after Inc 1 there is NO phase-arm route
and NO `emitRz`; after Inc 2 there is NO value-arm route; `cqrt_cswap` must be minted by `AbortParkEmit` ONLY
(grep the sources after the rebase — `grep -rn 'cswap' ir-pass/src | grep -v AbortPark` should show only
prose/declarations and the `EmitInverse` adjoint seam). Every `cqrt_rz_i1` emitter must call
`markBranchPhaseGate` (Inc 1's F-L7-1 fence; count `CreateCall(Rz` vs `markBranchPhaseGate` sites — they were
6 = 6 at 542d588; the value path must add NONE). Record every conflict and its resolution in the progress file.
Then `cmake --build build -j8` (BOTH targets) in the background.

## Gates to re-run on the rebased binary (background, logs under `$SP/progress/`)
1. `ctest -R ir-pass-lit` → the expected colour is GREEN except the standing XFAIL; any red is a rebase defect
   (a fixture whose subject is the value path may need RE-DERIVING from the rebased output — say which and why;
   never edit a CHECK by hand to make it pass).
2. Inc 2's four `cmp` twin gates: `e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical` and their
   eight slices; the Inc-1 gates that touch the same files: `e2e-phase-*-twin-identical` (all), the perbit
   family, `e2e-loop-twin-matrix` (background, ~7 min) + `e2e-loop-twin-quarantine-selftest`.
3. The 14-accept injection matrix of `fix_inc2_r1.md` re-pointed at the rebased binary (0 MISSED / 0 DIRTY).
4. The cswap census: a full-corpus sweep of `ir-pass/test/*.ll` outputs → `cqrt_cswap` appears ONLY in
   abort-park fixtures; `cqrt_rz_` at width `i1` only; `#cqrt_rz_i1 == #!cq.branchphase` per fixture.
5. Goldens: `diff` every golden the rebased tree changes vs the landed Inc-1 tree — the ONLY diffs allowed are
   the value-arm goldens Inc 2 already regenerated (list them) and NEW files; a phase golden that moves is a
   rebase defect.
Report the counts (`ls ir-pass/test/*.ll | wc -l`, `ctest -N | grep -c e2e-`) and commit the rebase as a
tidy sequence (`git rebase` result is fine; add ONE `wip(3qlq): Inc 2 rebased onto <hash>` commit for any
re-derivation). Do not push. Hand back per BRIEF_common with the conflict table and the gate table.
