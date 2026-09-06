# session 82e6b530 (2026-09-06) — the C-1 round-4 REBASE onto the landed Increment 2, and the landing

FOUR agents: `rebase_c1d` (the rebase and its gates), `review_c1e` (an independent Rule-13 lens ON
the rebased tree — verdict **CLEAR-WITH-ITEMS**, items F-C1E-1..4), `investigate_eqpx` (a READ-ONLY
investigation of the pre-existing bd `test_C_libtooling-eqpx`, nothing edited or committed) and
`docs_c1e` (folding F-C1E-1..4 in before the landing). Branch `c1-round4` (bd `test_C_libtooling-7yd0`, base a3c1513) was rebased
onto `main` = **b99b853** (docs) over **258d974** (Inc 2, value arms by the controlled-copy merge),
its gates re-run there, the round-4 lens items **F-C1D-2/3/4** folded in, and **`q4b`** — the one
row round 4 could only ARGUE, the Inc-2 value merge as a FOURTH producer of the `%out` rail — was
MEASURED: 4 mints / 0 `_unc` at 52 trace lines vs a hand-unrolled twin's 4/4 at 60 on `main`, and
**60 = 60 byte-identical** on the rebased binary.

* `rebase_c1d.md` — the rebase agent's full progress file and hand-back (every command and its
  measured result), with F-C1E-4's correction applied in place at its "0 hits" grep.
* `review_c1e.md` — the independent Rule-13 lens on the REBASED tree (`aa9d702`): verdict
  **CLEAR-WITH-ITEMS**. 0 DECLINE→ACCEPT over 610 comparable programs and all 1690 lit fixtures;
  0 ACCEPT→DECLINE; 0 decline-message changes; a G6/G7-disabled mutant built by the lens itself;
  a global immediate-slot audit over 668 programs; two of its own harness bugs recorded rather than
  hidden. Items **F-C1E-1** (which fixture measures what — a coverage correction), **F-C1E-2** (a
  PRE-EXISTING leak class, byte-identical to `main`), **F-C1E-3** (four unfaithful attack twins) and
  **F-C1E-4** (a self-invalidated grep in `rebase_c1d.md`).
* `docs_c1e.md` — the agent that applied F-C1E-1..4: the two in-source citations corrected
  (COMMENTS ONLY), the discriminating lit accept
  `control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll` added and red-greened, the
  leak class re-measured and committed as reproducers, and the records copied here.
* `investigate_eqpx.md` — READ-ONLY, and NOT this branch's business: bd `test_C_libtooling-eqpx`
  (P1) is a PRE-EXISTING confirmed miscompile of the "classical immediate turns tainted at round 2"
  class through the LOOP writers, reproducing byte-for-byte on the pre-3qlq ORACLE 52d7764. The
  record locates the `add`/`xor` asymmetry in `clang -O1` (IndVarSimplify closed-forms the affine
  add-recurrence, so the `add` stem is never an in-loop rail op), censuses reachability over 43
  programs on four binaries, and proposes a fix WITHOUT implementing it. Nothing in it is applied
  on this branch.
* `briefs/` — `BRIEF_common.md` and the four task briefs
  (`BRIEF_rebase_c1d.md`, `BRIEF_review_c1e.md`, `BRIEF_investigate_eqpx.md`, `BRIEF_docs_c1e.md`).
* Narrative record: `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3.15** (its last subsection is the lens on
  the rebased tree); status flips in PRD §0 **E2/E10/E11/E12**, `CLAUDE.md`'s C-1 bullet and
  `ROADMAP.md`. The round itself is `session-adc5590a/c1-round4/`; the F-C1E-2 reproducers are
  `inc1-records/c1-round4/c1e_a*.c`.
