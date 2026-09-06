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
* `clearance2.md` — the re-clearance whose verdict decided the landing. **VERDICT:
  `CLEAR-WITH-OWNER-QUESTIONS`** (2026-09-06). The BLOCK is closed — C-1's population is rolled ==
  hand-unrolled byte-identically on the subject (60 pairs, 3 new `cmp`-gated goldens, the matrix sub-grid
  F/F3 with no new quarantine cell), the two miscompiles round 2 introduced are gone, and the tree is a
  strict improvement over the pre-fix `542d588` at every layer measured: **0 DECLINE→ACCEPT flips over 404
  programs, 1667/1673 fixtures and 305/308 slices byte-identical between the two binaries** with every mover
  a discharge or a loud decline, **0 stage-2b violations**, **1328 injection cells 0 MISSED / 0 DIRTY**, the
  golden audit unmoved beyond NEW-FILEs. What it leaves open is **four owner questions and one record item**
  (§5): OQ-C2-1 (the `hasOneUse` stability conjunct refusing a commit M-C makes and the pre-3qlq oracle
  discharges — `m11d`), OQ-C2-2 (`short`/`sext` is the one Q-R1-1 member the oracle got right, so `r5` is an
  oracle regression), OQ-C2-3 (widen the Q-R1-1 disclosure to a QROM-read invariant root and to `-O1`'s
  SIDEWAYS compare rewrite), OQ-C2-4 (the over-decline list gains `s20`), and the record item that notes
  §3.12's "identical on `542d588`" is true of the DEFECT and not of the TRACE for the four in-region `eqpx`
  members. **Every one is a DISCLOSED class that pre-dates this branch; none is a wrong unitary this tree
  introduced.** On that verdict **Inc 0 + Inc 1 LANDED on `main` 2026-09-06 as ONE squash commit** (hash
  filled by the orchestrator: the squash of branch `3qlq-inc1-fix-c1`, whose tip is recorded in the landing
  commit message; `git log main -1` shows the hash). **Inc 2 stays on `3qlq-inc2`, NOT landed, and owes a
  rebase onto the landed Inc 1.**
* `briefs/` — every brief of the session; `c1_reproducers/` — the load-bearing plain-C reproducers (second TU
  `tu_extf.c` for the onward ones); `full_ctest_summaries.txt`; `COMMIT_MSG_inc1.md`.

The narrative record is `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 (§3.1–§3.12) and the PRD §0 ERRATA (E2 rewritten
twice; **E10** is the five-line summary of the three rounds, the count and the landing).
