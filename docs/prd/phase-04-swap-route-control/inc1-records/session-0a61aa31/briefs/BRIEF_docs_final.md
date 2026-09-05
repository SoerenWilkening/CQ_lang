# BRIEF_docs_final — the post-merge docs pass for Inc 0 + Inc 1 (before the commit)
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_docs_inc1.md`, `$SP/progress/docs_inc1.md`,
`$SP/progress/OWNER_QUESTIONS.md` (whole file), `docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC1_NOTES.md`
(§1, §2), the hand-backs `$SP/progress/{fix_r1,fix_r2,prep_a2,prep_b2,prep_d2}.md`, and `$SP/progress/clearance.md`
if it exists. Agent name: `docs_final`. DOCS ONLY: `CLAUDE.md`, `ROADMAP.md`, `docs/**/*.md`, `README.md`,
`include/CQ.h` COMMENTS only, fixture/slice HEADER COMMENTS only where a count is stated. No pass source, no
CHECK lines, no goldens, no CMake.

## Where you work
The MAIN checkout at be4e2ea (everything merged; build current). Measure every number you write with the
command that measures it (`ls ir-pass/test/*.ll | wc -l`; `ctest -N | tail -1`; `ctest -N -R '^e2e-' | tail -1`;
`grep -c '^m_' tools/loop_twin_matrix.expected.txt`; `wc -l tools/loop_twin_matrix.quarantine.txt`;
`grep -l 'allow-unproven' tests/e2e/CMakeLists.txt`…).

## Job
1. **CLAUDE.md** — (a) the ctest-count paragraph in "Build & Test": a new dated entry with the measured entry
   count and what moved (entries added/removed by prep-b2 and prep-d2; the 14 enabled; the 4 removed; the twin
   gates); (b) `ir-pass-lit` fixture count: the measured corpus + the XFAIL; the sentence "the emitted Rz set …";
   (c) the quarantine description (now the VOID file, 29 cells, three classes, `.register.txt` history);
   (d) "the five `e2e-slice-loop-break*` entries pass `--allow-unproven`" → measured; (e) the CORRECTNESS-RISK
   paragraph Inc 0 added: append the Inc-1 record in the house style — the three confirmed miscompile classes
   found by the rounds (spine adjoint of the kickback on the shared flag; global-phase deletion before the
   round-2 control claim; the stale-header retired-family third path) + F-R1-1 (once-only rail collapse vs
   round-2 claim) + the in-loop discharge for invariant registers, each with its fix mechanism
   (`!cq.branchphase` membership; P7 after the fixpoint; reserved-name decline + survivor assert;
   `invariantRegisterRoots`) and the standing lesson ("a stage that runs once has a round-2-false premise";
   "when a set is narrowed, ask what other predicate names the same gate"); (f) Rule 7's phase-arm sentences:
   the FLAT/nest/switch phase arm is now a kickback on the flag (`cqrt_rz_i1`), the route and the
   `cqrt_rz_<W>_controlled` sentences become history with a date; (g) the "Where Things Live" table: add
   `CondTreeEmit.{h,cpp}`, note `NestedRouteEmit` DELETED, `AngleSelectEmit` both stems, the `!cq.branchphase`
   record in `ChainWalk`; (h) the docs row for `tools/golden_multiset_audit.py --epic 3qlq` and the DELETED status.
2. **ROADMAP.md** — Phase 4 status: the swap route retired for PHASE arms (Inc 1 shipped) with the commit; value
   arms pending Inc 2; the freeze list: `cqrt_rz_<W>` (W>1) and `cqrt_rz_<W>_controlled[_inv]` declared-unemitted;
   `cqrt_cswap` minted by AbortParkEmit + the value path until Inc 2.
3. **frontend.md / backend.md** — the docs_inc1 "row 3 written to be deleted" (the retired family now declines
   when declared — F-L6-1 fix); "must not be defined by user code" → what shipped (check fix_r1.md for the
   defined-`@cq_phi` disposition); the §6.1a stream description vs the real traces (read three goldens).
4. **PRD errata block** at the top of `retire-swap-route-PRD.md`: the §3/§7.1 "freed clean" correction (Inc 2
   lens), the §9 per-bit row correction, §6.3's N-per-arm row (accepted for the diamond spelling), P5's
   plain-C fold (no C customer), P6's angle-select-in-loop status, the D4 rolled idiom disposition, dated and
   pointing at the notes.
5. `bd remember` NOTHING (the orchestrator writes the memories). Commit on main's branch with a `docs(control):`
   message listing the files. Hand back per BRIEF_common with every measured number and its command.
