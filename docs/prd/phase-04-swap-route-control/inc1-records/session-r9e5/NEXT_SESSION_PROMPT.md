# Next session — after bd `r9e5` 1b-B.1 (the `bool` DATA SELECT) landed (2026-09-10, session close)

**Start here.** The owner's adjusted `example/grover/grover_oracle_uncompute.c` (committed snapshot
`../session-3qlq4/user_file_as_of_2026-09-10_close.c`) **COMPILES** on `main` now: 15 trace lines,
STRICT stage 2b clean, committed verbatim as `tests/e2e/slice_control_select_bool.c`. Re-run it first
(`./tools/show_pipeline.sh example/grover/grover_oracle_uncompute.c`, or the slice) — the file is
git-excluded and the owner may have adjusted it again; if it declines, name the wall against this
list before touching anything:

* `bare i1 register condition` — a `bool` driving an UNFOLDED value diamond (≥5-op arm or hand IR:
  bd `fg9k`, 1b-B.2b) or a classical-call arm (`if (b) y = f(n)`, `f` `noinline` pure: bd `54ur`,
  1b-B.2a — the half with the customer, ~35–50 lines, `SCOPE_B2.md` §2.1, MUST carry the H-3 S†
  ruling), an in-place Ry / state prep / Ry angle select on a `bool` (bd `l4x4`, 1b-C).
* `branch phase on a bare i1 condition` — a loop-CARRIED `bool` or a merge-phi `bool` (bd `boi6`,
  1b-D), a negated nest level / NOT-carrying leaf / derived `i1` (bd `r903`).
* `condition measured before the control route` — the rail (or any name on its wire: a chained
  parent, the template it rotates in place) is measured before the select/branch on some path.
  Intended; PRD §14.3 rung 2 / §14.7.
* `condition predates a non-diagonal gate` — a chained/sibling theta on the rail's wire between its
  def and the select, or in the loop body (intended); a theta AFTER the select is admitted (the S†).
* `state prep seed is proven equal to the condition register` — a `bool` STATE PREP under control
  (HANDOFF Q6, owner question) or a dead prep arm (Q4).

## What this session did (record: this directory; PRD §14 + §0 E15; lab-report entry 003)

1. Measured the shape (`select i1 %b0, i32 2, i32 5`), built 1b-B.1 = the 4.4 copy merge on a rail
   root with the flag a CNOT COPY of the register (`CondTreeEmit` `CopyRailRoot`; `BRIEF_B1.md` §1 has
   the two rejected alternatives), classifier = the §13.3 rail ladder with the SELECT as read point.
2. Found and fixed F-B1-1 (the same-block measure-after-select in a loop, plain C) before review;
   its COMPARE twin is PRE-EXISTING — bd `r10v` (P1: the 4.4 compare select has NO measured-before
   rung at all). Round 1 (CLEAR-WITH-ITEMS) found F-B1R1-1 (rung (ii) over the SSA name, rung (iii)
   over the wire — shared with the kickback) — fixed in the shared helper for both callers; the
   emitter got a real tripwire (`ControlRegion::RailLadderProven`). Round 2 BLOCKED on the round-2 TAINT
   WINDOW (F-B1R2-1, a predicate asked at round-1 taint) — fixed by `reverifyRailCondReads` (record every
   emitted rail read at four sites, re-verify under FINAL taint after the fixpoint); round 3
   CLEAR-WITH-ITEMS (54 programs, 11 more closed programs, 3 pinned). Records: `review_b1_r{1,2,3}.md`.
3. Scoped B.2 (`SCOPE_B2.md`): from plain C the short value arm IS a select at `-O1` (lowers now);
   filed `54ur` (6.5 arm) → `fg9k` (value diamond), in that order.

## Owner questions on the desk

0. **bd `9pum` (P1)** — the COMPARE select's round-2 taint window (round 2's F-B1R2-1, pre-existing on
   `main`, plain C two TUs `review_b1_r2_probes/multi/e13`): extend `TaintSet::RailCondReads` to compare
   SEEDS (each leaf's `condProvenance` + its mint template as the read point) and re-verify after the
   fixpoint. Its own probe family (the onward-classified compare must stay green) and round.
1. **bd `r10v` (P1)** — fix the compare-select measured-before gap next (mirror of §14.3 rung 2 for
   compare leaves, its own probe family + round), or hold?
2. **bd `3d8q` (P1, from entry 002)** — the theta/measure stale-reader class; `r42` in the round-1
   corpus is its bare form (`measure(b0); b = θ(b0)` with no control accepts on both binaries).
3. **The CNOT-identity form** (`¬b·F = F ⊕ b·F`: fewer gates, no ancilla, one uncontrolled copy) is
   an owner option recorded in `BRIEF_B1.md` §1 / PRD §14.2; the shipped form was chosen for the
   smaller predicate surface.
4. **H-3** (`SCOPE_B2.md` §3.2): after a VALUE region the S† on the register declines at P1; the 6.5
   path has no P1 wrapper and would accept it — decide once before `54ur` is built.
5. Entry 002's Q4/Q6 (dead state-prep arm; F2 on an `i1` seed) — unchanged.

## Instruments to run before widening anything here

* `probes/` (39 programs, README with PRE/POST verdicts), `review_b1_r1_probes/run_corpus.sh POST`
  (108, `VERDICTS_POST.txt` = round 1's record; 5 move to decline after the fix), and round 2's corpus;
  the impl's `corpus_diff.py` (pre vs post over every fixture) lives only in the session scratchpad —
  re-create it from `IMPL_B1.md` §5 if the scratch dir is gone.
* `ctest -R 'select-bool|phase-bool|twin-identical'`, `e2e-loop-twin-matrix`, `cq-opt-equivalence-full`.
