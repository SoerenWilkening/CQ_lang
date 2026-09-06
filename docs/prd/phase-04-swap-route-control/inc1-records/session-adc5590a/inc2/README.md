# inc1-records/session-adc5590a/inc2 — Inc 2's rebase, round 2 and clearance (2026-09-06)

Inc 2 (bd `test_C_libtooling-3qlq.3`, value arms by the controlled-copy merge) was implemented and round-1 reviewed in
session 1 on branch `3qlq-inc2` (base dfb8e83). This directory records session 2's part:

* `rebase_inc2.md` — the rebase onto the landed Inc 1 (a3c1513): the conflict table (two real conflicts of seven
  overlapping files), three intent repairs, every layered gate re-run.
* `review_inc2_r2.md` — the round-2 lens (Inc 2's mechanism CLEAR; F-I2-1 = a PRE-EXISTING leak on main, bd `7yd0`,
  fixed as C-1 round 4; F-I2-2 the reviewer flag resolved in the increment's favour; F-I2-7 = bd base-from-cond).
* `fix_inc2_r2.md` — the round-2 fix (record + fixtures only; binary byte-identical).
* `clearance_inc2.md` — the clearance whose verdict decided the landing.
* `briefs/`, `COMMIT_MSG_inc2.md`, `full_ctest_summaries.txt`.

Narrative record: `RETIRE_SWAP_ROUTE_INC2_NOTES.md` (§1 round 1, §2/§3 the rebase, §4 round 2, §5 the clearance) and
the PRD §0 ERRATA (E1, E11) + §7 STATUS.
