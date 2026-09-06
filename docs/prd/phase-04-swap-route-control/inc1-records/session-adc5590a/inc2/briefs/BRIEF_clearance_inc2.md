# BRIEF_clearance_inc2 — Rule-13 CLEARANCE of Inc 2 (value arms by controlled-copy merge; the value-arm cswap route retired); the VERDICT decides the landing on main
Read `$SP/briefs/BRIEF_common.md` (MAIN = `main` at a3c1513, Inc 0 + Inc 1 landed, built), the PRD §7 + §0 ERRATA
(E1 = the dirty chain-final), `bd show test_C_libtooling-3qlq.3`, then from `inc1-records/session-0a61aa31/`:
`briefs/BRIEF_impl_inc2.md`, `impl_inc2.md`, `review_inc2_V1.md`, `review_inc2_V2.md`, `fix_inc2_r1.md`; then on the
branch: `RETIRE_SWAP_ROUTE_INC2_NOTES.md` (§1, §2/§3 the rebase, §4 round 2); then `$SP/progress/rebase_inc2.md`,
`$SP/progress/review_inc2_r2.md` and `$SP/progress/fix_inc2_r2.md` (round-2 fix: record + fixtures only; the notes round-2 section is §4). Agent name: `clearance_inc2`.
READ-ONLY (write only under `$SP/progress/clearance_inc2_work/`).

## Subject
`$SP0/wt/inc2` at 72974d5 (build current — verify; the round-2 fix changed no behaviour, binary byte-identical to 6ee3ea3). INC-1-ONLY = the main checkout at a3c1513. ORACLE =
`$SP0/wt/pre-3qlq` (52d7764). The orchestrator's FULL `ctest -j6` on the subject will be in
`$SP/progress/orch_full_ctest_inc2.log` — wait for it before your §1 table; do not run it yourself.

## The three questions (unchanged in form)
1. **Is there any path on which the emitted circuit is a different unitary from the source's, at `opt` exit 0?**
   Re-attack: speculation totality (a `sdiv`/`srem`/shift by a tainted operand that is zero/oversized on the
   INACTIVE branch — the hoisted chain executes on both), §3c clobber under the hoist (an arm that value-rewrites a
   register the condition reads), the XOR-delta overlap in V3, the two-distinct-copy-sources property vs the C-1
   rounds' `InPlaceRailOps` writers (a preheader commit on the value-arm BASE), the kickback-phased operand class,
   the dirty chain-final rail vs every discharge path (Inc-1 in-loop, C-1 clause (ii-b), `ClaimedRailRoots`,
   `FreePoint`), the OQ-22 HandleWidth widening (a downstream cast / Q+Q compare on the merged register), the F-V1-2
   pre-mutation fence (i128 condition), value arms with DERIVED bases (the reviewer flag), polarity (`ArmNegated`
   slot), and the shapes no lens owned: a value arm whose chain contains a curated `llvm.*` intrinsic; a value arm
   on a tape-written register; a value arm on a QRAM-loaded register; a value diamond whose merge feeds a Phase-6
   clone; a value arm + `cq_invert`; two value diamonds in sequence sharing the base; a value diamond under an
   ONWARD condition (round 2). Every twin gate byte-identical; every accept rolled/flat as claimed.
2. **Does anything free a rail that is not provably |0⟩, or leave a rail dirty where the oracle discharged it?**
   STRICT 2b on every reproducer; the golden audit (`--epic 3qlq --rev a3c1513` if the tool supports it, else the
   per-golden byte diff vs INC-1-ONLY: the ONLY moved goldens are the value-arm ones Inc 2 regenerated + NEW files);
   the dirty chain-final: confirm no path frees it (it is entangled) and that `free_pairing_check.py` classifies
   `cqrt_copy_<W>_controlled` correctly; the void loop twin matrix green with no new quarantine cell; V2's
   basis-state evaluator (OQ-23) — run it as an INSTRUMENT over every value fixture and slice if it exists on the
   branch, and report, without treating it as a gate.
3. **Is every accept pinned and every decline mirrored, and does the record tell the truth?** The injection
   matrix over every value-path accept fixture (0 MISSED / 0 DIRTY, controls); the `value-arm swap-route` decline
   string question (OQ-13: it names a retired mechanism — was it renamed? if not, is every use still a loud
   decline?); `cqrt_cswap` minted by `AbortParkEmit` ONLY (grep + full-corpus sweep); `#cqrt_rz_i1 ==
   #!cq.branchphase` tree-wide; PRD §7 + E1 true of the binary; the counts (`ctest -N`, lit, goldens) re-measured;
   D6/D7 honoured; 3qlq.5's "UNSOUND BY DEFAULT" note still true; OQ-11/12/13/22/23 each either pinned, filed, or open.

## Verdict (last line, exactly one of)
`CLEAR` · `CLEAR-WITH-OWNER-QUESTIONS` (list them) · `BLOCK` (the finding, the reproducer, the two traces).
Write `$SP/progress/clearance_inc2.md`; return it.
