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
  commit message; `git log main -1` shows the hash). ⚠ **The sentence that followed — "Inc 2 stays
  on `3qlq-inc2`, NOT landed, and owes a rebase onto the landed Inc 1" — is HISTORY, dated
  2026-09-06: Inc 2 was rebased onto that landing the same day, Rule-13 round-2 reviewed,
  cleared `CLEAR-WITH-OWNER-QUESTIONS` and LANDED on `main` as its own ONE squash commit** (see
  `inc2/` below and `inc2/clearance_inc2.md`). With it the SWAP ROUTE IS FULLY RETIRED —
  `cqrt_cswap` is minted by the 7.2 `AbortParkEmit` alone.
* `inc2/` — **Inc 2's session-2 record** (the rebase onto the landed Inc 1, the round-2 lens, the
  round-2 fix, the clearance and its verdict, briefs, commit message, ctest summaries). Its
  narrative record is `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §3/§4/§5 and PRD §0 **E1a/E1b/E11/E12**.
* `briefs/` — every brief of the session; `c1_reproducers/` — the load-bearing plain-C reproducers (second TU
  `tu_extf.c` for the onward ones); `full_ctest_summaries.txt`; `COMMIT_MSG_inc1.md`.

The narrative record is `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 (§3.1–§3.12) and the PRD §0 ERRATA (E2 rewritten
twice; **E10** is the five-line summary of the three rounds, the count and the landing).

## C-1 round 4 (bd `7yd0`) — NOT LANDED at THIS session's end (owner: "stop after this agent finished"); LANDED in session `82e6b530`
* `c1-round4/fix_c1d.md` / `c1-round4/review_c1d.md` — the round (one non-comment line: the `hasOneUse` conjunct of
  `commitOutOfLoopInPlaceOps` retired under the round-3 tripwire) and its lens (**CLEAR-WITH-ITEMS**). Branch
  `c1-round4` at 59f6a95 (base a3c1513, PUSHED, full ctest 351/351 on its tree). The leak it fixes was LIVE on
  landed `main` 258d974 (F-C1D-1), so the next session's first step was the rebase + landing per
  `briefs/BRIEF_rebase_c1d.md`. `NEXT_SESSION_PROMPT.md` carries the state AS OF THIS SESSION'S END.
* ⭐ **STATUS NOW: rebased onto 258d974 in session `82e6b530` (2026-09-06) and **LANDED on `main` 2026-09-06 as ONE squash commit** (hash filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash).** That rebase MEASURED the one
  row this round could only argue — Inc 2's controlled-copy VALUE merge as a FOURTH producer of the `%out` rail:
  `q4b_preadd` is 4 mints / 0 `_unc` at 52 trace lines vs its twin's 4/4 at 60 on `main` 258d974, and **60 = 60
  byte-identical** on the rebased binary — and folded in the lens items F-C1D-2/3/4. Record:
  `inc1-records/session-82e6b530/rebase_c1d.md`, narrative `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3.15**.
* ⭐ **AND A SECOND INDEPENDENT LENS RAN ON THE REBASED TREE** (`review_c1e`, 2026-09-06, branch tip
  **aa9d702**) — budgeted because the rebase adds a NEW customer class to an already-cleared fix (the
  Inc-2 controlled-copy merge) plus 25 edited fixtures. **Verdict CLEAR-WITH-ITEMS**, items
  **F-C1E-1..4, all APPLIED** by `docs_c1e` before the landing: 0 DECLINE→ACCEPT over 610 comparable
  programs on three binaries and over all 1690 lit fixtures, 0 ACCEPT→DECLINE, 0 decline-message
  changes, STRICT 2b clean on all 26 movers, injection matrix 0 MISSED / 0 DIRTY. The **full `ctest`
  on `aa9d702` was 367/367** (0 failed, 385.89 s). F-C1E-1 corrected two in-source citations and
  added the discriminating lit accept
  `control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll`; F-C1E-2 recorded a
  PRE-EXISTING leak class byte-identical to `main` (reproducers `inc1-records/c1-round4/c1e_a*.c`);
  F-C1E-3 and F-C1E-4 are doc corrections. Records: `inc1-records/session-82e6b530/review_c1e.md`
  and `.../docs_c1e.md`.
