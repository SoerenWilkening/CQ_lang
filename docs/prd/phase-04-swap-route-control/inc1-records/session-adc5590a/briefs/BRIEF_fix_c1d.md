# BRIEF_fix_c1d — C-1 ROUND 4 on a branch off `main` (IN PARALLEL with Inc 2's landing): retire the `hasOneUse` conjunct under the tripwire (bd 7yd0 / OQ-C2-1)
Read `$SP/briefs/BRIEF_common.md` (MAIN = `main` at a3c1513, Inc 0 + Inc 1 landed, built; Inc 2 is NOT landed yet — it is on branch `3qlq-inc2` in `$SP0/wt/inc2` at 6ee3ea3, built, being cleared in parallel; measure the Inc-2 value-merge spelling of the finding against THAT binary only as a reproducer — do not add fixtures/slices for it, main has no value merge yet; the orchestrator rebases your branch onto the landed Inc 2 afterwards), then
`docs/prd/phase-04-swap-route-control/inc1-records/session-adc5590a/{fix_c1b,fix_c1c,review_c1b,review_c1c,clearance2}.md`
(the rounds that built `commitOutOfLoopInPlaceOps`, the tripwire, and the questions OQ-C1-5/OQ-C1-7/OQ-C2-1),
`$SP/progress/review_inc2_r2.md` F-I2-1 (the customer: reproducers under `$SP/progress/review_inc2_r2_work/p/`),
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.10–§3.13, and the code: `LoopLowering.cpp` `commitOutOfLoopInPlaceOps` (the
`P->hasOneUse()` conjunct), `OpcodeLowering.cpp`'s tripwire (`PreLoopCommittedInPlaceOps` re-ask +
`diagnosePreLoopCommitStale`), `ArithLowering.cpp` `classifyInPlaceReassignment` (G2/G4/G5/G6/G7).
Agent name: `fix_c1d`. Model: opus. Worktree `$SP/wt/c1d` on a NEW branch `c1-round4` from `main`
(`git -C /Users/sorenwilkening/Desktop/CQ_lang worktree add $SP/wt/c1d -b c1-round4 main`); configure + build there
(background). PRE-FIX = the main checkout's binary (never rebuilt this round). ORACLE = `$SP0/wt/pre-3qlq`.

## The finding (F-I2-1, LEAK on main, C-1 class)
```c
int m = (q>5) ? p : r;   /* 4.4 select merge -> %out (also: a 6.5 arm, an Inc-2 value merge) */
m = m + 7;               /* preheader dtzb op on the merge out-rail */
for (int i=0;i<4;i++) if ((m>>i)&1) cq_phi(0.7);
```
rolled 4 mints / 0 `_unc`; hand-unrolled 4/4; K=32 32/0 vs 31/31; `cqrt_addc_i32(h4,7)` IS in place in the trace.
Cause: `P->hasOneUse()` is false for every merge out-rail (two `cqrt_copy_<W>_controlled` WRITERS precede any
reader), so the commit never fires, the peel stops, clause (ii) refuses, nothing is marked — while M-C converts the
op in place at `lowerOps`. `hasOneUse` cannot tell a prior WRITER from a later READER; M-C's G6/G7 can.

## The fix — ONE conjunct, with the argument written at the site
Drop `P->hasOneUse()`: commit iff `classifyInPlaceReassignment` (M-C's own fence, the ONE spelling) says in place
AND the immediate `isa<Constant>` (round 3's monotone fence, KEPT). The SAFETY is the round-3 TRIPWIRE: `lowerOps`
re-asks the same fence under final DT/LI/taint and declines loudly on any change — so a commit that was true at
round 1 and false at lowering (F-C1C-1's wire-vs-SSA class: a later read of a pre-op NAME that rotation lowering
RAUWs onto the same handle) becomes a LOUD DECLINE, never a leak and never a wrong unitary. Write that argument in
the function header, and re-do the §3.11 input-stability table's `P` row for the conjunct that is gone (what did
`hasOneUse` guard that G6/G7 does not? — answer with programs, not prose: the F-C1C-1 family `v3/v5/v6/v7/y1`, the
review_c1c `s07/s10/s20`, and the merge-out-rail family `q5sel_preadd`, `q4b`, `q7_k32`, plus the 6.5-arm and
Inc-2-value-merge spellings). Expected dispositions on YOUR binary: the merge-out-rail family → rolled == unrolled
IDENTICAL (the capability); the F-C1C-1 family → still DECLINES with the tripwire string (was: leak-refused at
commit on `main`? MEASURE what main does for each — if main leaks them and yours declines them loudly, that is a
strict improvement; if main accepts any CORRECTLY out of place and yours declines, record the over-decline as
OQ-C1-7's cost with the count); every other program in the C-1 populations (rounds 1–3 + clearance2 + review_inc2_r2)
byte-unchanged vs `main`.

## Red-green (Rule 12), on `main`'s binary (RED) vs yours (GREEN)
* `control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll` (4.4 select merge + `+7` + per-bit loop;
  `UCNT-COUNT-4`; `cqrt_addc` in its own prefix; NOROUTE whole-file) + the 6.5-arm and value-merge spellings if
  their `-O1` modules differ structurally (else headers cross-reference).
* The F-C1C-1 family: if any flips leak → decline, a decline fixture per stem with the tripwire string mirrored
  (`lowering_reject_preloop_commit_stale_*`), and the existing `control_phase_kickback_reject_preloop_commit_stale.ll`
  must stay RED-without-tripwire (re-run round 3's mutation on a scratch copy).
* e2e: `slice_control_phase_perbit_loop_merge_preadd{,_unrolled}.c` (from `q5sel_preadd_*`) + `cmp` twin gate;
  goldens by the full pipeline, STRICT 2b.
* `tools/loop_twin_matrix.py`: a sub-grid F4 cell (or two) whose invariant root is a SELECT-MERGE out-rail with a
  preadd (single-TU expressible), sizes asserted, all pre-existing generated sources byte-unchanged (hash proof).
* Docs: notes **§3.14** (round 4: the finding, the argument, the table, the population), PRD §0 E2 residual list
  (the `hasOneUse` line goes; OQ-C2-1 answered "retired under the tripwire" — one revert if the owner disagrees),
  CLAUDE.md's C-1 sentence, counts by command.
Verification: red-green per fixture; the WHOLE C-1 population (every `p/` dir of the session: fix_c1_work,
review_c1_work, fix_c1b_work, review_c1b_work, fix_c1c_work, review_c1c_work, clearance2_work, review_inc2_r2_work)
on `main` vs yours — list every mover; mutation validation (restore `hasOneUse` → the new accept RED; remove the
tripwire on a scratch copy → the F-C1C-1 fixtures RED); `ctest -R ir-pass-lit` background; the perbit/mixed/
value slices + all `*-twin-identical` gates + quarantine selftest; the matrix in the background; injection matrix
over the new accepts (0/0); STRICT 2b everywhere. Commit per step on `c1-round4`. Hand back per BRIEF_common:
first line = the merge-out-rail family's rolled/unrolled counts and the F-C1C-1 family's dispositions on main vs yours.
