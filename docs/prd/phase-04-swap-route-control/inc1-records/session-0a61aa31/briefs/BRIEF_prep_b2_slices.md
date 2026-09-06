# BRIEF_prep_b2_slices — Inc 1 prep (b2): resolve the 15 keep-alive, 8 loop, 2 unspellable and 1 mixed-nest slices on the Inc-1 binary; regenerate goldens under the audit
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_prep_b_slices.md`, `$SP/progress/prep_b.md`,
`docs/prd/phase-04-swap-route-control/inc1-records/PRE_DISPOSITIONS.md` §5 (on your branch),
`$SP/progress/OWNER_QUESTIONS.md` (OQ-2..OQ-8 carry the dispositions you execute),
`$SP/progress/impl_inc1a.md` and the audit's header (`tools/golden_multiset_audit.py`, the
`--epic 3qlq` section). Agent name: `prep_b2`. Model: opus.

## Where you work
Worktree `$SP/wt/prep-b`, branch `3qlq-inc1-slices`, REBASED by the orchestrator onto
c4bd888 (Inc 1a + round-1 fixes + Inc 1b, MERGED) (new header + pass) and with the audit branch merged. Build in the background
first. SUBJECT = your build; ORACLE = `$SP/wt/pre-3qlq`. Touch only `tests/e2e/*.c`,
`tests/e2e/*.expected.log`, `tests/e2e/CMakeLists.txt`, the inc1-records.

## Job, in order
1. **Run every one of the 74 slices** (63 migrated + 11 new) through the full pipeline on the
   SUBJECT (stage 1 → 2 → STRICT 2b → 3 → 4). Table: accept/decline + string. Compare with
   `PRE_DISPOSITIONS.md`'s "expected post-increment class": every mismatch is a FINDING for the
   reviewers (write it under `## FINDINGS`), not something to paper over.
2. **The 15 keep-alive slices (OQ-2):** rewrite each keep-alive site as a kickback under a
   DERIVED condition on that value (`if (y == <k>) cq_phi(0.2);` — choose k so the compare is
   at the value's width; for fp values use an `==` against a constant), run on the subject, and
   confirm the trace shows the forward chain, the mint, `cqrt_rz_i1`, the strip, the chain's
   `_unc` and the frees. Where the region DECLINES (say why — width, fence), fall back to
   `cq_measure` of the terminal and record the lost `_unc` coverage. Header of each: "REWRITTEN
   PROGRAM (3qlq Inc 1, OQ-2): <old idiom> → <new>; the golden is a new program, not an audit
   substitution".
3. **The 8 inplace-Ry loop slices (OQ-3):** add `q = cq_theta(q, 0.05);` as the LAST statement of
   the loop body (the condition register becomes loop-variant, the Inc-3 Grover shape); do the
   same in the hand-unrolled twins; run rolled vs unrolled on the subject — BYTE-IDENTITY via
   `cmp` is the witness; the 4 cmp gates stay.
4. **OQ-5:** delete `slice_loop_break_qq_phase.{c,expected.log}` + its CMake entry (record);
   `slice_select_rail_alias_cond.c`: keep the two surviving alias cases, retire three with the
   reason in the header. **OQ-7:** `slice_control_phase_nest_deep.c` leaves CMake (delete the
   entry and the file; the mixed-nest decline is pinned in lit by Inc 1b).
5. **Goldens.** For every slice that ACCEPTS on the subject: generate the trace, then run
   `python3 tools/golden_multiset_audit.py --epic 3qlq --rev 52d7764` (read its `--help`) —
   every diff must be one of the four substitutions OR a slice listed as a REWRITTEN PROGRAM in
   `inc1-records/GOLDEN_REGEN.md` (write it: slice | class (a/b/c/d/REWRITTEN) | one-line diff
   summary). Any OTHER diff is a FINDING. Then enable the 14 disabled entries.
6. Run `ctest --test-dir build -j6 -R '^e2e-'` in the background (~4 min) and report the
   count; list every red with its reason. Commit; hand back per BRIEF_common.
