# BRIEF_review_c1d — ONE narrow Rule-13 lens on C-1 ROUND 4 (the `hasOneUse` retirement under the tripwire), READ-ONLY
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_fix_c1d.md`, then from the repo record
`inc1-records/session-adc5590a/{fix_c1b,fix_c1c,review_c1b,review_c1c,clearance2}.md` (how the commit + tripwire came
to be and the two miscompiles they closed), `$SP/progress/review_inc2_r2.md` F-I2-1 (the customer), then
`$SP/progress/fix_c1d.md` IN FULL and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.14. Agent name: `review_c1d`. Model: opus.
READ-ONLY (write only under `$SP/progress/review_c1d_work/`).

## Binaries
SUBJECT `$SP/wt/c1d` at 59f6a95 (build current — verify) · PRE-FIX = main checkout at a3c1513 (built) ·
FIX-2 (638334c, the round-2 binary that had NEITHER hasOneUse's cost NOR the tripwire) `$SP/progress/fix_c1c_work/*.fix2` ·
ORACLE `$SP0/wt/pre-3qlq`. Control the harness (clean + known-bad) first.

## The one question: with `hasOneUse` gone, is the tripwire the ONLY thing standing between a stale commit and a wrong unitary — and does it hold everywhere the conjunct used to?
1. **Re-attack F-C1C-1's class with the conjunct gone.** Every program where the SSA `P` had one use but the WIRE
   has more after `lowerRotations` (a theta chain RAUW'd onto one handle; a chain through an in-place `add`; a chain
   whose later member is measured / returned / tape-written / passed to a clone / used as a QRAM index / read by a
   second loop); and the mirror: `P` with MANY SSA uses that are all WRITERS (merge out-rails from 4.4/6.5/4.5;
   two preheader ops in sequence; a merge out-rail also read by a later region's condition). For each: on the
   subject it must be either rolled == unrolled IDENTICAL with the op IN PLACE (the capability) or a LOUD tripwire
   decline — never a leak where FIX-2 or the oracle discharged, never a handle in an immediate slot, never K
   adjoints of one gate. Compare each against FIX-2 (which had no tripwire): anything FIX-2 got WRONG must decline
   on the subject.
2. **The tripwire's completeness, adversarially, now that it is load-bearing alone**: is every op the commit marks
   re-asked (the `PreLoopCommittedInPlaceOps` set vs the `Marked` rollback list — an op committed then rolled back
   must NOT be in the tripwire set, and an op committed and KEPT must be); the `inBennettClone` skip in the tripwire
   — can a committed preheader op live inside a specialised clone? (construct it; if reachable it is a hole); the
   tripwire runs at `lowerOps` — is there any consumer of `InPlaceRailOps` BETWEEN the commit and `lowerOps` that
   acts on the commit before the tripwire can refuse it (`staleRailRecordRead`, `collectRailGates`, `WireWalk`,
   `ArmClassify` R6, `declineLiftedStaleRecordOps`, `lowerRotations` itself) — for each, a program where the
   commit is stale and that consumer changes an answer; `cq-opt` exits at the FIRST DS_Error — can a committed-then-
   stale op's DECLINE be pre-empted by an earlier accept-path mutation that already emitted something wrong?
3. **The population, re-run**: every C-1 population dir of the session (fix_c1_work … review_inc2_r2_work) on
   `main` vs the subject: list every mover; the only movers may be the merge-out-rail family (now discharged) and
   whatever `hasOneUse` used to refuse that now commits (each must be IDENTICAL twins or a loud decline); the
   Q-R1-1 controls still leak byte-identical; ≥ 10 new spellings of your own.
4. **Record truth**: §3.14's table and counts reproduce; the red-greens reproduce (main RED / subject GREEN, and
   the round-3 tripwire fixture RED on a no-tripwire scratch copy); PRD E2's residual list is true of the binary;
   the matrix's pre-existing generated sources byte-unchanged.
Grade: `CONFIRMED-MISCOMPILE` / `LEAK` / `OVER-DECLINE` / `DOC` / `CLEAR`. Write `$SP/progress/review_c1d.md`
(findings F-C1D-k, reproducers under `$SP/progress/review_c1d_work/`, what you ran, verdict line
`CLEAR` / `CLEAR-WITH-ITEMS` / `FINDINGS`). Return it as your final message.
