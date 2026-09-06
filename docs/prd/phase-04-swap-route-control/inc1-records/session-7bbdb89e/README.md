# session 7bbdb89e (2026-09-06) — bd `test_C_libtooling-eqpx` (P1) FIXED: the in-place-rail CONSUMER TRIPWIRE

Owner ruling (2026-09-06, session 82e6b530): fix eqpx now, as a DECLINE-ONLY consumer tripwire — G2 alone re-asked at
`lowerOps` for every `taint.InPlaceRailOps` member not in `PreLoopCommittedInPlaceOps`; not the full M-C fence; not the
writer-side `isa<Constant>`. This session built exactly that, plus the operand-INDEX form as argued defence-in-depth,
and landed it on `main` as **main** (hash filled by the orchestrator: the squash of branch `eqpx-fix`, whose tip is recorded in the landing commit message; `git log main -1` shows the hash).

SIX agents, in order (opus unless noted), every one with a brief in `briefs/` and a progress file here:
* `fix_eqpx` — the implementer (code tip 1333278): `OpcodeLowering.cpp` Phase-1 tripwire + `diagnoseRailOpStale`;
  `TaintSet::InPlaceRailIdx` + the single helper `LoopLowering::markInPlaceRailOp` that all four writers call, erased by
  the rollback, re-verified by the tripwire, CONSUMED by `rewriteInPlaceValueRail`; 8 decline + 8 accept-control
  fixtures (RED on `main` with `railInImm` 1–2, GREEN as the mirrored decline); record-truth docs. Measured: lit
  1707/1706/1 XFAIL; `^e2e-` 357/357 with 0 golden churn; corpus diff `main` vs fix 0/0/0 over 1691 fixtures; the
  43-program census 18 moved (all the members) / 24 unchanged byte-identical; the W1 break cells decline with exactly one
  diagnostic and no crash.
* `review_eqpx_r1` — adversarial lens, **CLEAR-WITH-ITEMS**: 43 new attack programs → 15 MORE `main` members (three
  casts, a curated intrinsic, a classical phi, two rail ops on one immediate, a break loop with the immediate in its
  condition, the commuted `add` from PLAIN C, and at i8/i16 a loud `LLVM ERROR: Broken module` instead of a silent
  miscompile), all declined by the fix; 20 boundary programs, 0 over-declines; whole-corpus sweep 8 accept→decline / 0
  decline→accept / OUTDIFF 0 over 841 accepts; `strictimm.py` 0 rail producers; mutants M-A (tripwire off → 8 RED),
  M-B (silent fallback → 8 RED), M-E (index flipped → 23 RED), M-F (unroll prepass off → n01–n03 decline). Adjudicated
  the stronger form DOC-keep (inert on the corpus, live when wrong) and the `n02` loop collapse as the Lever-B
  `unrollConstTripLoops` prepass (gate U4 = `loopHasInPlaceRailStructure`, disjoint from the writers by ORDERING —
  neither a fifth writer nor an escape past the tripwire). Items F-E1-1/2/3: stale line numbers in two comment blocks,
  vacuous `CHECK-NOT`s on a `RUN: not` fixture (the `not` inversion pins the property), the 8 accept controls missing
  28/48 injections (every one an extra `cqrt_free`).
* `fix_eqpx_b` — docs+fixtures round (beb34e0; binary `cmp`-byte-identical to 1333278): F-E1-1/2/3 closed (injection
  matrix 28 → 0 MISSED; `k01`/`k02`/`k03` got exact-count `XCNT` prefixes because their legitimate `%`-immediates are
  the very capability the fix preserves), the in-source three-fact argument for the index, notes §3.16, PRD E13,
  `eqpx_reproducers_r1/` (15 members + 20 controls).
* `review_eqpx_r2` — narrow lens, **CLEAR-WITH-ITEMS**: 80-injection superset matrix 0 MISSED (47/80 pre-edit); M2+M3
  re-measured 0 OUTDIFF over 1707, M-E 24 moved; 879 accept modules 0 rail producers; the full `ctest` READ (367/367,
  350.23 s, EXIT 0 at beb34e0); four DOC items F-E2-1..4 (a missing `tu_exth.c`, six citations shifted by the fix's own
  +40 lines, a 15/16 slip, an antecedent drift).
* `fix_eqpx_c` — docs-only round closing F-E2-1..4 (record tip e752877 + the orchestrator's landing-record commit).
* `clearance_eqpx` (Fable) — the ONE Rule-13 clearance: **CLEAR-WITH-OWNER-QUESTIONS**. Re-derived every load-bearing
  claim with programs on named binaries (corpus diff 0/0/0; census 18/24/17; its OWN M1 mutant from `git archive`: the 8
  declines RED, nothing else moves; m23 1707/1707 identical, ME 24 move; 80-injection matrix 0 MISSED). F-CL-1 (DOC,
  applied by the orchestrator in §3.16 and the two W1 fixture headers): the "no second diagnostic after the `continue`"
  disposition is true because the DRIVER EXITS AT THE FIRST `DS_Error`, so `lowerBreakReversePlay` is never reached —
  the W1 fixtures' `break reverse-play` negatives are a tripwire for a driver that continues, not a witness of the
  stage. F-CL-2 (CLEAR): two more plain-C members (`clearance_probes/p_k_cmp_zext_imm.c`, a compare of `%out` zext'd;
  `p_n_variant_plus_out.c`, a loop-variant immediate mixed with `%out`), both declined by the fix; 6 controls unchanged.

Gates run by the orchestrator: full `ctest -j6` **367/367, 350.23 s, EXIT 0** at beb34e0 (binary unchanged since 1333278;
the docs rounds after it changed no source line, verified by cmp after every build). Counts: lit 1691 → **1707**; ctest 367 / e2e 357 / slices 321 UNCHANGED; goldens 323 UNCHANGED; matrix
259 + 29 UNCHANGED; `runtime/`, `tools/opcode_table.yaml`, `include/` UNTOUCHED (owner D3).

Files here: `README.md` (this), `NEXT_SESSION_PROMPT.md`, `briefs/` (BRIEF_common + the six task briefs + the clearance
brief), `fix_eqpx.md`, `review_eqpx_r1.md`, `fix_eqpx_b.md`, `review_eqpx_r2.md`, `fix_eqpx_c.md`, `clearance_eqpx.md`,
`eqpx_reproducers_r1/` (15 members + 20 controls + README + `tu_exth.c`), `clearance_probes/` (the clearance's 8
programs + README), `citation_sweep/` (the F-E2-2 sweep script, its verdict file and before/after outputs),
`orch_full_ctest_eqpx.log` (the gate run, 367/367 at beb34e0).
Narrative record: `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3.16**; PRD §0 **E13**; `CLAUDE.md`'s C-1 bullet; `ROADMAP.md`.

OPEN after this session (owner's call): (1) keep or drop the `InPlaceRailIdx` form — kept as argued defence-in-depth,
argument in-source at the consume; (2) a one-line header note on the pre-existing (1b) template fixture
`control_phase_kickback_reject_preloop_commit_stale.ll`, whose `CHECK-NOT`s are equally vacuous (docs-only);
(3) a capability-preserving SECOND WRITER ROUND on top of the tripwire that would re-accept the 18+15 movers as
out-of-place — a later increment, never the fence; (4) the pre-existing stale `AsLowered=true` citations in notes §3.14
(`:3214`/`:3412-3413`, wrong on `main` too). Then the queue from session 82e6b530: 3qlq.13, .14, .9, .10, .11, .12, 67n5,
OQ-11/12/13/22/23; increments 3qlq.4, 3qlq.8; follow-ons .5 (UNSOUND BY DEFAULT), .6, .7.
