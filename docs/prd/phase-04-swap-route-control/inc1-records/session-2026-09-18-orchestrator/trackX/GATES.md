# Track X — GATES (hash-keyed; PROTOCOL.md §"The non-redundancy protocol" + §6.1)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`

## Binaries

| hash16 | what | built |
|---|---|---|
| `9bd01598d574b344` | the session ORACLE, and my worktree's pre-edit build (`cmake --build build -j2`, BOTH targets) — the two are byte-identical | 2026-09-17 12:2x |

`shasum -a 256 build/ir-pass/cq-opt` in the worktree returned
`9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` and
`shasum -a 256 build/ir-pass/libCQPass.so` returned
`3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d` before the first edit — equal to
PROTOCOL.md's ORACLE block.

## Gate lines

| gate | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| per-probe pipeline, `x01_owner_scalar.c` | `9bd01598d574b344` | `exit=1 \| …x01_owner_scalar.c:10:23: in function main i32 (): cq controlled lowering: arm rewrites a condition operand under quantum control` | trackX | 2026-09-17 12:3x |
| per-probe pipeline, `x02_classical_carrier_value.c` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=107 trace=42 \| 2b: 3 rail mint(s) of which 3 left allocated, 2 template rail mint(s) of which 1 left dirty, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` | trackX | 2026-09-17 12:3x |
| per-probe pipeline, `x03_no_clobber_control.c` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=109 trace=42` | trackX | 2026-09-17 12:3x |
| per-probe pipeline, `x04_flat_value_arm_control.c` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=81 trace=15` | trackX | 2026-09-17 12:3x |
| per-probe pipeline, `x05_flat_backedge_free_clobber.c` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=72 trace=12` | trackX | 2026-09-17 12:3x |
| per-probe pipeline, `x06_inloop_value_noclobber_minimal.c` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=109 trace=42` | trackX | 2026-09-17 12:3x |
| per-probe pipeline, `x07_flat_diamond_chain_clobber.c` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=90 trace=17` | trackX | 2026-09-17 12:4x |
| per-probe pipeline, `x08_inloop_chain_backedge_clobber.c` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=126 trace=69` | trackX | 2026-09-17 12:4x |
| per-probe pipeline, `x09_inloop_chain_no_backedge.c` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=128 trace=69` | trackX | 2026-09-17 12:4x |
| per-probe pipeline, `h1_inloop_diamond_value_backedge.ll` | `9bd01598d574b344` | `exit=1 \| cq controlled lowering: arm rewrites a condition operand under quantum control`; `CQ_CTRL_DBG` anchor `%r1 = add nsw i32 %r, 3` | trackX | 2026-09-17 12:5x |
| per-probe pipeline, `h2_inloop_diamond_value_nobackedge.ll` | `9bd01598d574b344` | `exit=1 \| cq controlled lowering: control flow inside a loop body under quantum control`; `CQ_CTRL_DBG` anchor `br i1 %c, label %arm, label %merge` | trackX | 2026-09-17 12:5x |
| per-probe pipeline, `h2b_inloop_diamond_value_onecond_control.ll` | `9bd01598d574b344` | `exit=1 \| cq controlled lowering: control flow inside a loop body under quantum control` | trackX | 2026-09-17 13:0x |
| per-probe pipeline, `h3_flat_diamond_value_clobber.ll` | `9bd01598d574b344` | `exit=1 \| cq controlled lowering: arm rewrites a condition operand under quantum control` | trackX | 2026-09-17 12:5x |
| per-probe pipeline, `h4_flat_diamond_value_noclobber.ll` | `9bd01598d574b344` | `exit=0 ACCEPT \| ir=41 trace=15 \| 2b: 3 rail mint(s) of which 3 left allocated, 2 template rail mint(s) of which 1 left dirty, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` | trackX | 2026-09-17 12:5x |
| per-probe pipeline, `h5_inloop_i1_carried_theta_arm.ll` | `9bd01598d574b344` | `exit=1 \| cq controlled lowering: condition predates a non-diagonal gate under quantum control` | trackX | 2026-09-17 13:0x |
| `CQ_CTRL_DBG` anchor, `x01_owner_scalar` | `9bd01598d574b344` | `CQ_CTRL_DBG: decline [arm rewrites a condition operand] at:   %15 = zext i1 %14 to i8, !dbg !34` | trackX | 2026-09-17 12:5x |

Subject-binary rows are appended in the sections below as they are run.

## SUBJECT BINARIES — rows are appended ONLY after the gate is actually run

| hash16 | what | built |
|---|---|---|
| `33bba13b5886e28b` | SUBJECT 1 — the per-activation §3c narrowing (`ArmClassify.cpp` only) | 2026-09-17 12:5x |
| `e2bee9a8ca4a7e7e` | MUTANT — SUBJECT 1 + a `getenv` lever that returns before the (P3) rail loop. Built, measured, REMOVED; the restored tree rebuilt to `33bba13b5886e28b` again, byte for byte | 2026-09-17 13:2x |
| `677472eb67a0b2ea` | SUBJECT 2 (FINAL) — + the `!Region.Condition` null guard and the round-1/round-2 source comments | 2026-09-17 13:4x |

### SUBJECT 1 — `33bba13b5886e28b`

| gate | result verbatim | who | when |
|---|---|---|---|
| per-probe, all 15 probes | `h1` → `control flow inside a loop body` (MOVED from `arm rewrites a condition operand`); `x01_owner_scalar.c:10:23` → `value-arm swap-route` (MOVED, same anchor); `h2`/`h2b`/`h3`/`h4`/`h5`/`h6` and `x02…x09` ALL UNCHANGED (7 accepts with identical `ir=`/`trace=`) | trackX | 2026-09-17 12:5x |
| `lit ir-pass/test --filter '…clobber…'` (4 new fixtures) | `Total Discovered Tests: 2086 … Passed: 4` | trackX | 2026-09-17 13:0x |
| `ctest -R ir-pass-lit` | `1/1 Test #8: ir-pass-lit Passed 65.44 sec — 100% tests passed, 0 tests failed out of 1` ⚠ **SUPERSEDED** by the SUBJECT 2 line — the source changed after it | trackX | 2026-09-17 13:1x |

### MUTANT — `e2bee9a8ca4a7e7e` (the (P3) conjunct's mutation validation)

| gate | result verbatim | who | when |
|---|---|---|---|
| per-probe, (P3) OFF | `h6_inloop_dtzb_same_rail_backedge` → `control flow inside a loop body` (**MOVED — the sole discriminator**); `h1`, `h3`, `x01` all UNCHANGED | trackX | 2026-09-17 13:3x |

### SUBJECT 2 (FINAL) — `677472eb67a0b2ea`

| gate | result verbatim | who | when |
|---|---|---|---|
| per-probe, all 16 probes (`h7` added) | identical to SUBJECT 1 on all 15; `h7_inloop_mixed_evidence` → `arm rewrites a condition operand` on **both** this and the ORACLE (the mixed-evidence attack is repelled) | trackX | 2026-09-17 13:5x |
| `lit ir-pass/test --filter` (5 new fixtures) | `Total Discovered Tests: 2087 … Passed: 5` | trackX | 2026-09-17 13:5x |
| `ctest -R ir-pass-lit` | `1/1 Test #8: ir-pass-lit Passed 82.53 sec — 100% tests passed, 0 tests failed out of 1` (2087 fixtures = main 2082 + trackX 5) | trackX | 2026-09-17 14:0x |
| `python3 tools/negative_vacuity_check.py` over the 5-fixture batch | `5 fixture(s), 0 directive(s) evaluated, 0 VACUOUS, … 5 declining module(s)`, exit 2 — **N/A, not a pass and not a red**: the batch is five DECLINE fixtures with no `CHECK-NOT`, pinned by the `not` inversion (Rule 12(b)). Reported, not worked around | trackX | 2026-09-17 14:0x |
| corpus sweep ORACLE-vs-SUBJECT, SERIAL run, read at 564 of 6446 rows before it was superseded | **7 movers, ALL `D:arm rewrites a condition operand` → `D:value-arm swap-route`**, every one a member of the S-1 peel-ladder family: `trackL/probes/s_loop_n{2,3,8}.c`, `trackL/probes/t_loop_n{2,3,8}.c`, `session-2026-09-11-orchestrator/review_integration_probes/N7_loop.c`. **0 `A→D`, 0 `D→A`, 0 `A→A` md5 changes.** ⚠ PARTIAL — an ABSENCE for the other 5882 rows, not a green | trackX | 2026-09-17 14:2x |
| corpus sweep, PARALLEL re-run (fixtures first) — STOPPED at hand-off, `probes/corpus_677472eb.partial.txt` | **1744 of 6446 rows, ALL of them `ir-pass/test/*.ll` (1744 of the 2087 shipped fixtures, 84%). 2 movers, BOTH of them this track's OWN NEW fixtures** — `control_swap_reject_value_bool_loop_hoisted_clobber.ll` `D:arm rewrites a condition operand` → `D:value-arm swap-route`, and `control_swap_reject_value_inloop_backedge_clobber.ll` → `D:control flow inside a loop body`. **ZERO PRE-EXISTING FIXTURES MOVED**, 0 `A→D`, 0 `D→A`, 0 `A→A` md5 changes. 15 rows in the sample carry the §3c string. ⚠ **PARTIAL — an ABSENCE for the remaining 343 fixtures and all 4359 probe files, not a green** (PROTOCOL.md: *"record an unfinished gate as an ABSENCE, never a green or a red"*). Throughput ~37 rows/min and NOT improved by `xargs -P 6`, because `uptime` reported **load averages 639 / 692 / 351 / 197** from the session's other tracks while it ran | trackX | 2026-09-17 14:3x |

⚠ **THE SHIPPED-FIXTURE HALF OF THE CORPUS IS COVERED BY A STRONGER INSTRUMENT, so the absence above
is bounded.** `ctest -R ir-pass-lit` green at this hash runs all **2087** fixtures and checks each
against the verdict its own RUN line pins — including all 22 that pin `arm rewrites a condition
operand`. A sweep would say a verdict CHANGED; lit says it did not change away from what is pinned.
What the sweep alone can see is the UNPINNED probe corpus, and that is what the 564-row sample
above covers. **The definitive sweep is the GROUP GATE's, on the merged binary** (PROTOCOL.md's
matrix). This track's two expected mover strings for attribution are
`arm rewrites a condition operand` → `value-arm swap-route` and
`arm rewrites a condition operand` → `control flow inside a loop body`; **any other mover
attributable to this branch is a FINDING.**

⚠ **PROTOCOL INCIDENT, recorded rather than buried.** A corpus sweep announced at `33bba13b` was
still running when the SUBJECT-2 rebuild relinked `cq-opt` under it (CLAUDE.md: *"never relink a
binary under a running measurement"*). It was stopped by TASK ID — not by a `pkill` pattern, the
2026-09-15 F-1 lesson — its partial 220-row output was DELETED rather than reported, and the sweep
was re-run from scratch at `677472eb` with no build in flight. A sweep split across two binaries is
not a slow result; it is a wrong one.

## §6.1 redundancy check

No `IN-FLIGHT` line existed in `$SES/GATES_INFLIGHT.md` for any gate this track ran, at the hash it
ran it on, when it started. No gate in this file was run twice at one hash. Nothing was cited from
another track: the only shared binary is the pre-edit ORACLE `9bd01598`, and the rows recorded
against it are per-probe pipeline runs on THIS track's own probes, which no other track owns.
