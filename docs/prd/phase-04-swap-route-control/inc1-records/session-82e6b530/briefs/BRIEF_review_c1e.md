# BRIEF_review_c1e — ONE narrow Rule-13 lens on the REBASED C-1 round 4 (branch `c1-round4` @ aa9d702, base main 258d974/b99b853), READ-ONLY
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_rebase_c1d.md`, then `$SP/progress/rebase_c1d.md` IN FULL (the
rebase agent's record: conflict table, gates, the `q4b` measurement, the extra_ry matrix), and from the repo
`inc1-records/session-adc5590a/c1-round4/{fix_c1d,review_c1d}.md` (the round and the pre-rebase lens, verdict
CLEAR-WITH-ITEMS, items F-C1D-1..4 — the rebase agent folded them in) and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.14 on the
subject branch. Agent name: `review_c1e`. Model: opus. READ-ONLY (write only under `$SP/progress/review_c1e_work/` and
`$SP/progress/review_c1e.md`). No commit, no push, no bd.

## Binaries — name every one, verify each before use (`find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` EMPTY)
SUBJECT = `$SP1/wt/c1d` at aa9d702 (the rebased branch, built by the rebase agent) ·
PRE-FIX = `main` 258d974 (the main checkout, or the frozen copy `$SP/bin/main-258d974/`) — the leak is LIVE there ·
PRE-REBASE round-4 binary = `$SP/bin/c1d-59f6a95/` (link with main's runtime archives) ·
ORACLE = `$SP0/wt/pre-3qlq` (52d7764). Copy `$SP1/progress/review_c1d_work/run.sh` into your work dir, re-point `W=`
and add the cases `subj` (SUBJECT), `pre` (`$SP/bin/c1d-59f6a95`), `main`. Control the harness first: clean + known-bad
(`q5sel_preadd_{rolled,unrolled}` must DIVERGE on main 4/0 44 vs 4/4 52 and be IDENTICAL on the subject).

## The rebase question, which is the whole review: did the rebase onto Inc 2 change what round 4 does, and does round 4
## now serve Inc 2's fourth producer without reaching anything Inc 2 protects with G6/G7 alone?
1. **The code diff is ONE non-comment change.** `git diff main HEAD -- ir-pass/src` on the subject must show ONLY
   `LoopLowering.cpp` (`if (!P || !P->hasOneUse()) return;` → `if (!P) return;`) plus comments, and comment-only in
   `ArithLowering.cpp` (F-C1D-2's cross-reference). `git diff --stat main HEAD -- runtime tools/opcode_table.yaml include`
   EMPTY (owner D3). Quote the diff.
2. **SUBJECT vs PRE-REBASE binary, over the ENTIRE C-1 population** (every `p/`, `p2/`, `p3/` dir under
   `$SP1/progress/*_work/` — fix_c1, review_c1, fix_c1b, review_c1b, fix_c1c, review_c1c, clearance2 (p/p2/p3),
   review_inc2_r2, fix_inc2_r2, clearance_inc2, fix_c1d, review_c1d — ~1000 files incl. duplicates; dedupe by content
   hash; second TUs `tu_extf*.c` linked where a program needs one). Status + decline message + trace byte-diff. The
   ONLY admissible movers are programs whose lowering Inc 2 itself changed (value diamonds/if-else/switch that used to
   route now merge by controlled copy — their traces change for Inc-2 reasons, and MUST be byte-identical between the
   SUBJECT and `main` 258d974). So: run the population on all three of {main, pre-rebase, subject} and partition:
   (a) subject == pre-rebase (round 4 unchanged by the rebase); (b) subject == main ≠ pre-rebase (Inc 2's own movers —
   list them and confirm each is a value-arm program); (c) anything else = a FINDING. Expected (c) = EMPTY except the
   merge-preadd family where subject ≠ main is the capability (rolled == unrolled on the subject; list them all).
3. **0 DECLINE→ACCEPT flips between `main` 258d974 and the SUBJECT** over that population and over the whole lit corpus
   (run every `ir-pass/test/*.ll` through both binaries: rc + first diagnostic + output hash; report RCDIFF / DIAGDIFF /
   OUTDIFF counts; every OUTDIFF must be a round-4 discharge or a NEW fixture). Any DECLINE→ACCEPT is a finding.
4. **`q4b` and the Inc-2 chain head (F-C1D-2).** Re-derive `q4b_preadd_{rolled,unrolled}` yourself on all four binaries:
   subject rolled == unrolled IDENTICAL; the chain head `p+3` OUT of place (`cq_template_add_i32_hl`); exactly ONE
   `cqrt_addc_i32(<out>, 7)`; the `%out` rail's `+7` committed and discharged (4/4). Then ATTACK the claim "the commit
   cannot reach an Inc-2 chain head": write ≥ 8 spellings where a value diamond's chain head or interior member sits in
   the PREHEADER of a per-bit loop, or where the diamond's SOURCE `p` (left allocated, entangled — PRD E1) or its
   chain-final rail is the loop's invariant root, or where the merge `%out` feeds TWO loops, or where a second value
   diamond reads the `%out` before the loop, or an if/else value arm (V2) and a value switch (V3) as the producer. For
   each: subject must be IDENTICAL twins (capability), or a LOUD decline (quote), or byte-identical to main (untouched);
   never a `cqrt_addc`/`cqrt_xorc` on a rail whose PRE-op value is read later (G6), never a handle in an immediate slot,
   never a free of a chain final or of `p`. Compare each against the ORACLE for the record.
5. **The extra_ry row (F-C1D-4).** Re-run the rebase agent's injection matrix yourself (`$SP/progress/rebase_c1d_work/inj.py`)
   over every `control_phase_kickback_*` accept AND independently inject an uncontrolled `cqrt_ry_i32` at THREE positions
   (after the flag free; between mint and rz; after the last `_unc`) into the q4b fixture and the two round-4 fixtures:
   every injection must be caught by a named prefix. Confirm no positive `COUNT` directive was folded into a NOROUTE
   prefix (the windowing recurrence): `grep -n 'NOROUTE-COUNT' ir-pass/test/control_phase_kickback_*.ll` must be EMPTY.
6. **Record truth**: the conflict table matches `git log`/`git diff` (LoopLowering/matrix/INC1 notes did NOT conflict);
   counts reproduce by command (lit, ctest -N, `^e2e-`, `^e2e-slice-`, twin gates, goldens, matrix 259 rows + 29
   quarantine, sub-grid F4 present); the two new goldens re-derived from source on the subject build GOLDEN-MATCH and
   STRICT 2b `0 violation(s), 0 unproven`; notes §3.14's three F-C1D-3 refinements are TRUE of the tree (verify the
   `AsLowered=true` call-site count, `WireWalk.cpp`'s zero code reads, the second `declineStaleRecordOps` call's position);
   every "in flight" sentence about round 4 now reads "landing"; the duplicate `session-adc5590a/fix_c1d.md` is gone.
7. **The one-round-out question** (the C-1 record is 8 findings over 6 rounds on this function; assume a 9th): with Inc 2
   in the tree, is there a NEW writer or reader of `taint.InPlaceRailOps` / `PreLoopCommittedInPlaceOps` / `ClaimedRailRoots`
   (grep both sets on the subject; compare the file:line census against review_c1d's "4 code files, 2 AsLowered=true
   sites")? Does Inc 2's `emitValueRegion` hoist (it moves a chain into the PRED — the preheader of a following loop)
   create a preheader op the commit now sees that it did not before? Construct it.
Grade each finding `CONFIRMED-MISCOMPILE` / `LEAK` / `OVER-DECLINE` / `DOC` / `CLEAR`. Write `$SP/progress/review_c1e.md`
(findings F-C1E-k with reproducers under `$SP/progress/review_c1e_work/`, a WHAT I RAN table, and the verdict line
`CLEAR` / `CLEAR-WITH-ITEMS` / `FINDINGS`). Return it as your final message.
