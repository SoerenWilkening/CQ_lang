# Track D2 — GATES (hash-keyed; `$SES/PROTOCOL.md` non-redundancy protocol §6.1)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <time>`

⚠ **Binaries in play.** ORACLE `9bd01598d574b344…` (frozen, the primary `build/`).
SUBJECT `5ee9d14420c3533a…` with `libCQPass.so 3bcc2cd76f24df65…`. ⚠ The subject's
`cq-opt` hash is UNCHANGED by the final comment-only edits (verified: same
`5ee9d144…` after the L1-note rebuild), so every line below stays citable.

⚠ **Two MUTANT binaries were built and discarded.** They are recorded because their
results are evidence, not because they ship: (a) "dtzb arm deleted" — which turned
out to be byte-identical to the shipped binary, since deleting the `add` arm and
falling through to `return false` for a non-`CallInst` compile to the same code; (b)
"gap scan removed" (`crossBlockCompareMintable` returns `true` after the DT check) and
(c) "`condRailMembers` BackwardOnly" and (d) "`R.ShareCondFlag ||` conjunct deleted".
Each was reverted and the tree rebuilt to `5ee9d144…` before the next gate.

## Baseline

worktree-build-reproduces-oracle | 9bd01598d574b344 | `cmake --build build -j2` exit=0; `cq-opt` = 9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3 and `libCQPass.so` = 3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d — BOTH equal PROTOCOL.md's ORACLE block | impl | 2026-09-17 12:0x

## Customer measurement on the ORACLE (STEP 1)

probe-rowW-16cells-x2-halves | 9bd01598d574b344 | 32/32 exit=1, all `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | impl | 12:1x
probe-binv-cell | 9bd01598d574b344 | rolled exit=1 `cq controlled lowering: control flow under quantum control`; unrolled exit=0 ACCEPT | impl | 12:1x
probe-target-stream-oeq-rolled | 9bd01598d574b344 | exit=0; STRICT 2b `2 rail mint(s) of which 2 left allocated, 1 template rail mint(s) of which 0 left dirty, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`; 14 trace lines | impl | 12:1x

## On the SUBJECT

probe-customer-simplest-c | 5ee9d14420c3533a | `d2a1_customer_simplest.c` exit=0; STRICT 2b `2 rail mint(s) of which 2 left allocated, 1 template rail mint(s) of which 0 left dirty, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`; 14 trace lines, IDENTICAL to the `oeq` target stream with `5` for `3` | impl | 12:5x
probe-rowW-16cells-x2-halves | 5ee9d14420c3533a | 32/32 exit=0 ACCEPT | impl | 13:0x
lit --filter (10-fixture batch) | 5ee9d14420c3533a | 18 of 2090 run (filter), 18 PASS 0 FAIL | impl | 13:2x
ctest -R '^e2e-.*inloop-hoisted-cond' | 5ee9d14420c3533a | 3/3 Passed (slice 5.08s, twin 2.42s, twin-identical 0.04s) — 100% tests passed, 0 failed out of 3 | impl | 13:0x
ctest -R ir-pass-lit (1st) | 5ee9d14420c3533a | FAILED — 2 pre-existing decline fixtures flipped: `control_phase_kickback_reject_tree_cross_block_leaf.ll`, `control_swap_reject_seq_shared_cond.ll`. ⚠ RECORDED AS A RED, not as noise; both were then converted deliberately (each names this round in its own header) | impl | 13:1x
ctest -R ir-pass-lit (2nd, after the 2 conversions) | 5ee9d14420c3533a | 1/1 Test #8 Passed 59.42 sec — 100% tests passed, 0 failed out of 1 | impl | 13:13
ctest -R ir-pass-lit (3rd, RE-RUN: same binary, fixture batch CHANGED by the mutation-matrix hardening) | 5ee9d14420c3533a | 1/1 Test #8 Passed 110.66 sec — 100% tests passed, 0 failed out of 1 (2090 fixtures; under concurrent agent load, not comparable with the 59 s figure) | impl | 13:32
negative_vacuity_check.py (10-fixture batch) | 5ee9d14420c3533a | 10 fixture(s), 42 directive(s) evaluated, 0 VACUOUS, 0 decline-stdout note(s), 0 latent header collision(s), 3 declining module(s), 0 unparsed, 6 front-end-intrinsic exemption(s), 9 resolved by the universe, 0 undecidable, universe 7 module(s); rc=0 | impl | 13:0x
inject_D2 matrix (1st) | 5ee9d14420c3533a | 9 fixture(s), 108 mutation(s), 67 caught, **MISSED 21**, n/a-HOLE 20 | impl | 13:2x
inject_D2 matrix (2nd, after hardening) | 5ee9d14420c3533a | 9 fixture(s), 108 mutation(s), 88 caught, **MISSED 0**, n/a-HOLE 20 (every hole is a gate the module legitimately does not contain) | impl | 13:33
inject_D2 self-check (no argument) | 5ee9d14420c3533a | exits rc=2 with "refusing to report '0 mutations, MISSED 0'" | impl | 13:2x
corpus sweep ORACLE-vs-SUBJECT, `ir-pass/test/*.ll` | 5ee9d14420c3533a | 2090 rows, 2081 unchanged, **9 movers ALL D→A** (5 are trackD2's own NEW fixtures, 4 pre-existing conversions), **0 A→D**, **0 A→A md5 change** | impl | 13:2x
corpus sweep ORACLE-vs-SUBJECT, session probe `.ll` corpus | 5ee9d14420c3533a | 2464 rows, 2459 unchanged, **5 movers ALL D→A**, 0 A→D, 0 A→A md5 change | impl | 13:27

## Mutant measurements (evidence, discarded binaries)

mutant-dtzb-arm-deleted → `dtzb_flat_red.ll` | (byte-identical to 5ee9d144) | exit=0, emits `%h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 1)` — OUT of place. This is what made the dtzb fence a measured OVER-DECLINE and got it removed | impl | 13:0x
mutant-gap-scan-removed → `r1c_flat_behind_add.ll` | mutant | **exit=0 ACCEPT** (the shipped binary DECLINES) — the ONE probe that individually pins the gap scan | impl | 13:4x
mutant-gap-scan-removed → `r1a_alias.ll` / `r1b_behind_add.ll` / `..._wire_gate_in_gap.ll` | mutant | all three STILL DECLINE (caught by `wireGainsNonDiagonalGate` or by bd `3d8q`) — recorded because it means those three do NOT pin the scan | impl | 13:4x
mutant-condRailMembers-BackwardOnly → `r1a_alias.ll`, `n1base.ll` | mutant | both still DECLINE — the `BothWays` choice is not individually pinned by these two probes (bd `e1gr` class) | impl | 13:4x
mutant-ShareCondFlag-conjunct-deleted → `share_phase.ll` | mutant | **exit=0 ACCEPT**, emitting TWO flag rails from ONE source compare, neither stripped nor freed → the conjunct IS load-bearing; pinned by `control_phase_kickback_reject_crossblock_shared_cond_flag.ll` | impl | 13:1x

## Not run (an ABSENCE, never a green)

* full `ctest -j6` — the GROUP-2 merge-and-gate agent's, once, on the merged binary (PROTOCOL §S1/§6.1).
* `ctest -j6 -R '^e2e-'` beyond the three entries this track adds — same owner.
* `cq-opt-equivalence-full` — same owner; this track moved an ANALYSIS site (no decline string was added or renamed), so the merge agent should run it.
* the twin matrices — Track V owns `tools/loop_twin_matrix.*`; this track did not read or write them beyond a READ-ONLY `sources()` import, and did not run the matrix. **Expected on the merged binary: the 16 row-W `DECLINE-BOTH` cells become `ACCEPT-IDENTICAL`** (both halves lower and, measured on the e2e twin pair, rolled == unrolled byte-for-byte); `m_none_ablphi_none_none_binv` stays `UNROLLED-ONLY`.
* the duplicate-body fixture scan — merge-gate owner, after any merge that renames fixtures. This track renamed NONE (bd `gahu` precedent).
