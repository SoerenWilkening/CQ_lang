# inc1-records/session-adc5590a — the C-1 fix rounds (2026-09-06)

Session 2 of epic bd `test_C_libtooling-3qlq`. Session 1 (`session-0a61aa31/`) ended with the independent clearance
BLOCKING Inc 0 + Inc 1 on finding C-1. This directory is the record of the three fix rounds that followed, the lens on
each, the re-clearance, and the landing:

* `fix_c1.md` / `review_c1.md` — round 1 (the capability: invariant root mints admitted beside carried roots) and
  its lens (FINDINGS: F-C1-1 preheader in-place op; F-C1-2 onward-region mixed loop).
* `fix_c1b.md` / `review_c1b.md` — round 2 (F-C1-1/F-C1-2 fixed) and its lens (FINDINGS: F-C1B-1, a CONFIRMED
  miscompile INTRODUCED by round 2 — a quantum handle in `cqrt_addc`'s immediate slot; F-C1B-2 a module-wide claim
  key for a per-loop property).
* `fix_c1c.md` / `review_c1c.md` — round 3 (the NARROWING: `isa<Constant>` at commit, a loud lowering-time tripwire,
  a per-loop claim key; the fix agent found a second round-2 miscompile, F-C1C-1, itself) and its lens
  (CLEAR-WITH-ITEMS; F-C1C-B = bd `eqpx`, PRE-EXISTING on the pre-3qlq oracle).
* `docs_c1.md` / `docs_c1c.md` — the two count/record-truth docs passes.
* `clearance2.md` — the re-clearance whose verdict decided the landing.
* `briefs/` — every brief of the session; `c1_reproducers/` — the load-bearing plain-C reproducers (second TU
  `tu_extf.c` for the onward ones); `full_ctest_summaries.txt`; `COMMIT_MSG_inc1.md`.

The narrative record is `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 (§3.1–§3.12) and the PRD §0 ERRATA (E2 rewritten twice).
