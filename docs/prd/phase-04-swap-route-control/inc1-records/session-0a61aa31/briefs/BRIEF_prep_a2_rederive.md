# BRIEF_prep_a2_rederive — Inc 1 prep (a2): re-derive the migrated fixtures' CHECKs on the Inc-1 binary + the 77 hand decisions
Read `$SP/briefs/BRIEF_common.md`, then `$SP/briefs/BRIEF_prep_a_migration.md`, then
`$SP/progress/prep_a.md` and the migration report
`docs/prd/phase-04-swap-route-control/inc1-records/MIGRATION_REPORT.md` (on your branch), then
`$SP/progress/impl_inc1a.md` (the implementer's diagnostic strings and accept shapes) and
`$SP/progress/OWNER_QUESTIONS.md` (OQ-6, OQ-9, OQ-10 carry the dispositions you execute).
Agent name: `prep_a2`. Model: opus.

## Where you work
Worktree `$SP/wt/prep-a`, branch `3qlq-inc1-migration`, which the orchestrator has REBASED onto
the Inc-1 implementer's commit c4bd888 (Inc 1a + round-1 fixes + Inc 1b, MERGED) (so `include/CQ.h` and the pass source are the new
ones). Build it in the background FIRST (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix
llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release && cmake --build build -j8`, both targets).
SUBJECT = your `build/ir-pass/cq-opt`; ORACLE = `$SP/wt/pre-3qlq`. Touch only `ir-pass/test/*.ll`
(existing files), `tools/migrate_phi_fixtures.*`, and the migration report.

## Job
1. Run lit on the whole corpus with the SUBJECT (background, ~100 s). Partition the reds:
   (i) in the 236 A/S/MIX set (expected), (ii) in the 77 hand-decision set, (iii) OTHER —
   (iii) must be empty; anything there is an implementer regression: STOP and report it
   before doing anything else (write it under `## IMPLEMENTER REGRESSION` in your progress file).
2. Re-derive every A/S/MIX fixture's CHECK lines from the SUBJECT output: keep the fixture's
   PURPOSE (its header), replace the pinned gate stream with the kickback stream the subject
   emits, handle names DERIVED from the output (never typed), counts in their own prefix
   (`ACNT`/`FCNT`), whole-file negatives (`NOROUTE-NOT: cqrt_cswap`, `NOROUTE-NOT:
   _controlled`, `NOROUTE-NOT: cqrt_rz_i32`/the width in question, `NOROUTE-NOT: @cq_phi`) in a
   PURE-negative prefix — a positive COUNT directive inside the NOT prefix WINDOWS every NOT after
   it (the Inc-3 F-L6-1 / Inc-4 recurrence). For a DECLINE fixture whose diagnostic string changed,
   mirror the new string character-for-character and say in the header which clause now fires;
   if the subject ACCEPTS a fixture that pinned a decline, that is a DISPOSITION FLIP: do not
   rewrite it silently — list it in the report under `## FLIPS` with the old string, and treat a
   flip toward ACCEPT as a potential over-accept for the reviewers (the fixture keeps its
   `RUN: not` and stays RED until a reviewer clears it; note it).
3. The 77 hand decisions: per file, apply the disposition recorded (HOLD/theta-swap where the
   `cq_theta` swap reproduced the original diagnostic; undissolvable merge phi → rewrite or
   retire; tainted-angle → rewrite with the new surface (a tainted angle into `cq_phi(double)`
   is still a decline — pin it); structural → case by case). OQ-9: one representative per
   pinned property for the 28 derived-base fixtures, the rest retired (deleted) with the reason
   in the report. OQ-10: re-spell the 8 phase-class-value declines with a VALUE op where the
   property is about the value path; G7 (`control_swap_reject_switch_value_clobber.ll`) MUST keep
   a fixture that reddens if the clobber decline is removed — prove it by a mutation (comment
   the decline out? no — you cannot edit the pass; instead verify the fixture fails on a
   hand-edited IR where the clobber is removed and passes on the clobber).
4. Fixture-integrity check on a sample of ≥40 re-derived ACCEPT fixtures: inject (a) a
   `cqrt_cswap`, (b) a `_controlled` Rz, (c) a surviving `call void @cq_phi`, (d) a dropped
   flag `cqrt_free` into the subject's output and FileCheck — every injection must be CAUGHT;
   control each with a clean run and a known-bad run.
5. Re-run `tools/migrate_phi_fixtures.py --verify-oracle` in SUBJECT-vs-ORACLE mode as the
   report describes; final lit on the subject must be GREEN apart from the listed FLIPS.
   Commit; hand back per BRIEF_common with counts: re-derived, retired (list), re-spelled,
   flips, integrity sample results.

## Added after round 1 (read $SP/progress/fix_r1.md and $SP/progress/impl_inc1b.md)
- The merged binary has 396 lit reds, ALL in the 493-file retired-family set (`grep -lE '@cq_phi_[a-z0-9]+'`);
  after your migration that set must be EMPTY of reds. The reserved-name decline (F-L6-1) means NO fixture may
  keep a `declare @cq_phi_<sfx>` — even declare-only fixtures decline now; rewrite or retire them with the reason.
- `control_angle_select_reject_runtime_arms_rz.ll` must be REWRITTEN AS AN ACCEPT (owner Q3: run-time arms are
  admitted for the phase stem), never re-spelled as a decline.
- The three `control_swap_switch_phase*` + `control_swap_reject_blockaddress_switch_arm.ll` pin the routed
  switch that no longer exists (Inc 1b hand-back): rewrite to the per-case kickback (P5) stream or retire.
- `lowering_reject_break_phase_answer.ll`: see fix_r1's F-L5-6 disposition; follow it.
- The list `$SP/progress/fix_r1_new_reds.txt` (34) is the fix round's addition to the set.
