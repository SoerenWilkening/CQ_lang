# GATES — Rule-13 review, Group 1 (bd `tu9q` hoisted-template half), session 2026-09-18

Format per `$SES/PROTOCOL.md`: `<gate> | <sha256 of cq-opt, first 16> | <result verbatim> | <who> | <when>`.

**Role gates (PROTOCOL matrix): the reviewer runs NO build and NO suite.** Its one obligation —
checking every `GATES.md` hash against the binary on disk — is the first four rows. Every other
row is a SINGLE-PROBE run, so **nothing here was announceable under §6.1** and nothing was cited
or re-run. No `IN-FLIGHT` line existed for anything I ran, because I ran no multi-entry gate.

Harness: `probes/gp.sh` (a PRIVATE copy — see REVIEW.md F-4 for why that matters). It stamps the
measured binary's sha256 on every row and self-attacks before use.

## Binary verification (the reviewer's one obligation)

| gate | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| `shasum -a 256 $REPO/build/ir-pass/cq-opt` (ORACLE) | 9bd01598d574b344 | `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` — matches the brief character-for-character | reviewer | 2026-09-17 15:05 |
| `shasum -a 256 <SUBJECT>/build/ir-pass/cq-opt` | 7c1163ad94d06320 | `7c1163ad94d0632007566867a4a71bc7de9377352cddc4158425e41532594326` — matches the brief; `git log` tip `f1a7857a` | reviewer | 2026-09-17 15:05 |
| `ls .claude/worktrees/p0p3/build/ir-pass/cq-opt` at review open | — | **ABSENT** (`No such file or directory`) — recorded as an ABSENCE, not a red | reviewer | 2026-09-17 15:05 |
| `shasum -a 256 .claude/worktrees/p0p3/build/ir-pass/cq-opt` at Part C | e951d5d1bc072902 | `e951d5d1bc072902e28bc0fd8a5d2adf1468bab100c4f1164c4e8f5f5ed21a7e`, built 14:42; matches `P0P3_STATUS.md` §0; tip `30b80d7f` | reviewer | 2026-09-17 15:05 |
| `shasum -a 256 $SCRATCH/pregroup/build/ir-pass/cq-opt` (the implementer's, RE-USED not rebuilt) | 0e280fc62a91cec2 | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` — matches `IMPL_T3.md` §1 | reviewer | 2026-09-17 15:05 |
| `ls .claude/worktrees/p0p3/build/runtime/` | e951d5d1bc072902 | `cmake_install.cmake CMakeFiles CTestTestfile.cmake` — **NO archives**, so every P0P3 row is opt+2b+IR only (no link, no trace) | reviewer | 2026-09-17 15:05 |

## Harness self-attack (run BEFORE use — `CLAUDE.md` L10)

| gate | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| `gp.sh <0-byte .c> …` | 9bd01598d574b344 | `VACUOUS-EMPTY`, `rc=2` — does not score ACCEPT | reviewer | 2026-09-17 15:05 |
| `gp.sh <quantum-free .c> …` | 9bd01598d574b344 | `VACUOUS-NOQUANTUM`, `rc=2` | reviewer | 2026-09-17 15:05 |

## Per-probe pipeline (`clang -O1 -g` → `cq-opt` → STRICT `free_pairing_check.py` → link → run)

Command per row: `probes/gp.sh <probe>.c <BUILD> <TAG>`.

### PART A — bd `6n1s` + P1

| probe | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| g1_threeblock_body_rot | 9bd01598d574b344 | `opt exit=0`; warn `non-diagonal gate over a live derived record`; `3 template rail mint(s) of which 1 left dirty, 0 cqrt_free site(s)`; trace 20 | reviewer | 2026-09-17 15:05 |
| g1_threeblock_body_rot | 7c1163ad94d06320 | `opt exit=0`; same warn; `3 template rail mint(s) of which 0 left dirty, 1 cqrt_free site(s): 0 verified, 0 violation(s), 1 unproven`; trace 28, 4 `ashr_unc` + 4 `cqrt_free` | reviewer | 2026-09-17 15:05 |
| g1_threeblock_body_rot | 0e280fc62a91cec2 | `opt exit=1` `cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop` | reviewer | 2026-09-17 15:05 |
| g2_fourblock_body_rot | 9bd01598 / 7c1163ad | `1 left dirty, 0 free` → `0 left dirty, 1 free site`; trace 26 → 34, 4 `ashr_unc` + 4 free | reviewer | 2026-09-17 15:05 |
| g5_break_in_threeblock_rot | 9bd01598 / 7c1163ad | `1 left dirty, 0 free` → `0 left dirty`; trace 18 → 26, 4/4 | reviewer | 2026-09-17 15:05 |
| g6_nest_multiblock_inner_rot | 9bd01598 / 7c1163ad | `1 left dirty, 0 free` → `0 left dirty`; trace 26 → 38, 6 `ashr_unc` + 6 free; `4 !llvm.loop refs` on BOTH (still rolled) | reviewer | 2026-09-17 15:05 |
| g3_arm_mint_join_read_rot | 9bd01598 / 7c1163ad | `opt exit=1` `cq taint escape: tainted value muxed by a classical-condition select` on BOTH | reviewer | 2026-09-17 15:05 |
| g4_arm_inplace_on_rail_rot | 9bd01598 / 7c1163ad | `opt exit=0`, `0 left dirty, 6 cqrt_free site(s): 6 verified`, trace 48 on BOTH (byte-identical; `-O1` rewrote the program) | reviewer | 2026-09-17 15:05 |
| g7_inplace_carried_twoblock_rot | 9bd01598 / 7c1163ad | `opt exit=1` `cq loop lowering: loop-carried tainted value crosses iterations` on BOTH | reviewer | 2026-09-17 15:05 |
| g9_rail_read_only_in_arm_rot | 9bd01598 / 7c1163ad | `opt exit=1` `cq opcode lowering: operand predates a non-diagonal gate` on BOTH | reviewer | 2026-09-17 15:05 |
| g10_emitter_gate_on_interior_rail | 9bd01598 / 7c1163ad | `1 left dirty, 4 free` trace 45 → `0 left dirty, 6 free sites` trace 53, +4 `ashr_unc`; the 8 `cqrt_x` and 4 `cqrt_rz_i1` are on the FLAG | reviewer | 2026-09-17 15:05 |
| **g8_arm_use_derived_owned_rot** | 0e280fc62a91cec2 | `opt exit=1` `cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop` | reviewer | 2026-09-17 15:05 |
| **g8_arm_use_derived_owned_rot** | 9bd01598d574b344 | `opt exit=0`; `4 template rail mint(s) of which 2 left dirty, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven`; trace 19 | reviewer | 2026-09-17 15:05 |
| **g8_arm_use_derived_owned_rot** | 7c1163ad94d06320 | **IDENTICAL to the ORACLE** — `opt exit=0`, `2 left dirty, 0 cqrt_free site(s)`, trace 19. **F-1** | reviewer | 2026-09-17 15:05 |
| **g8_arm_use_derived_owned_rot** | e951d5d1bc072902 | **IDENTICAL** — `opt exit=0`, `4 template rail mint(s) of which 2 left dirty, 0 cqrt_free site(s)`. P0+P3 does not close it either | reviewer | 2026-09-17 15:05 |
| g8a_arm_measured_directly_control | 0e280fc62a91cec2 | `opt exit=1` `…rolled body leaks a rail entangled with a register rotated after the loop` | reviewer | 2026-09-17 15:05 |
| g8a_arm_measured_directly_control | 9bd01598d574b344 | `opt exit=0`, `3 template rail mint(s) of which 1 left dirty, 0 cqrt_free site(s)`, trace 18 | reviewer | 2026-09-17 15:05 |
| g8a_arm_measured_directly_control | 7c1163ad94d06320 | `opt exit=0`, `3 template rail mint(s) of which 0 left dirty, 2 cqrt_free site(s)`, trace 26, 4 `ashr_unc` + 4 free — **the ONE-TOKEN control moves** | reviewer | 2026-09-17 15:05 |
| g8k_arm_use_derived_unmarked_control | 9bd01598 / 7c1163ad / e951d5d1 | `opt exit=1` `cq loop lowering: rolled body leaks a rail entangled with a rotated register` on **all three** — the MARKING is the door | reviewer | 2026-09-17 15:05 |
| g8b_interior_gate_in_header_control | 9bd01598 / 7c1163ad | identical to g8 on both — `-O1` **SANK** the `add` back into the arm; degenerate control, recorded not counted | reviewer | 2026-09-17 15:05 |

### PART B — P2

| probe | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| b1_depth3_nest_hoisted | 9bd01598d574b344 | `opt exit=0`, stderr 0 bytes, `3 template rail mint(s) of which 2 left dirty, 0 cqrt_free site(s)`, trace 28, `8 !llvm.loop refs` | reviewer | 2026-09-17 15:05 |
| b1_depth3_nest_hoisted | 7c1163ad94d06320 | `0 left dirty, 2 cqrt_free site(s)`, trace 30; ONE `cq_template_mul_i32_hl_unc` + ONE `cqrt_free` at **trace line 28**, after all 8 innermost reads | reviewer | 2026-09-17 15:05 |
| b1_depth3_nest_hoisted | e951d5d1bc072902 | `opt exit=0`, `0 left dirty, 4 cqrt_free site(s)` (no link — no runtime archives) | reviewer | 2026-09-17 15:05 |
| b1b_depth3_mid_mint | 9bd01598 / 7c1163ad | `2 left dirty, 0 cqrt_free site(s)`, trace 17, **UNMOVED** on both — safe-direction leak (F-6) | reviewer | 2026-09-17 15:05 |
| b2_two_sibling_loops | 9bd01598d574b344 | `5 template rail mint(s) of which 3 left dirty, 0 cqrt_free site(s)`, trace 16 | reviewer | 2026-09-17 15:05 |
| b2_two_sibling_loops | 7c1163ad94d06320 | `2 left dirty, 2 cqrt_free site(s)`, trace 18; the `mul_unc` + free at **line 16, after BOTH loops** | reviewer | 2026-09-17 15:05 |
| b3_hoisted_read_after_loop | 9bd01598 / 7c1163ad | identical (`1 left dirty, 4 cqrt_free site(s): 2 verified`, trace 17); `mul_unc` at line 14, **after** the trailing read at line 10 — Rule 6 respected | reviewer | 2026-09-17 15:05 |
| b4_two_exit_blocks_hoisted | 9bd01598 / 7c1163ad | `2 left dirty, 0 cqrt_free site(s)`, trace 13, **UNMOVED**; `-O1` merged my two `return`s into ONE exit block `%27` (preds `%6`,`%21`) — F-5 | reviewer | 2026-09-17 15:05 |
| a1_apost | 9bd01598d574b344 | `opt exit=0`; warn `non-diagonal gate over a live derived record`; `4 template rail mint(s) of which 1 left dirty, 3 cqrt_free site(s): 3 verified`; trace 26; **0** `sqrt_f64_unc` | reviewer | 2026-09-17 15:05 |
| a1_apost | 7c1163ad94d06320 | `opt exit=0`; **stderr 0 bytes**; `0 left dirty, 4 cqrt_free site(s)`; trace 28; `sqrt_f64_unc` at line 20, **before** `cqrt_ry_i32(h0,0.7)` at line 26 | reviewer | 2026-09-17 15:05 |
| m_none_oder_none_none_none | 9bd01598 / 7c1163ad | `1 left dirty` trace 25 → `0 left dirty` trace 27, +`sqrt_f64_unc` | reviewer | 2026-09-17 15:05 |
| p2c_parent_gated_inside | 9bd01598 / 7c1163ad | identical, trace 39, `0 left dirty, 4 verified` — `-O1` fully unrolls it (no loop); confirms IMPL_T3 F-R2-1 row 3 independently | reviewer | 2026-09-17 15:05 |
| dD1_hoisted_template_cond_then_ry (Track D's) | 9bd01598 / 7c1163ad | `opt exit=1` `cq controlled lowering: condition predates a non-diagonal gate under quantum control` on BOTH — D is not merged | reviewer | 2026-09-17 15:05 |
| g6_nest_multiblock_inner_rot | e951d5d1bc072902 | `0 left dirty, 1 cqrt_free site` — no regression on P0+P3 | reviewer | 2026-09-17 15:05 |
| b2 / b3 | e951d5d1bc072902 | `2 left dirty, 2 free` / `1 left dirty, 4 free` — unchanged vs the SUBJECT | reviewer | 2026-09-17 15:05 |

### PART C — P0+P3 (fixtures run directly through `cq-opt`, no lit)

| gate | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| `loop_leak_dephase_reject_region_derivedbase_live.ll` | 7c1163ad / e951d5d1 | `exit=1` `…rolled body leaks a rail entangled with a rotated register` → `exit=0`, `3 template rail mint(s) of which 0 left dirty, 6 cqrt_free site(s): 4 verified, 0 violation(s), 2 unproven` | reviewer | 2026-09-17 15:05 |
| `control_phase_kickback_mixed_hoisted_template_leak_control.ll` | 7c1163ad / e951d5d1 | `exit=1` same string → `exit=0`, `3 template rail mint(s) of which 0 left dirty, 3 cqrt_free site(s): 2 verified, 1 unproven` | reviewer | 2026-09-17 15:05 |
| `control_phase_kickback_mixed_short_sext_leak_control.ll` | 7c1163ad / e951d5d1 | `exit=1` same string → `exit=0`, `3 template rail mint(s) of which 0 left dirty, 3 cqrt_free site(s): 2 verified, 1 unproven` | reviewer | 2026-09-17 15:05 |
| `loop_pairing_reject_round2_falsified.ll` (**mover 7**) | 7c1163ad / e951d5d1 | `exit=1` `cq loop lowering: round-1 iteration-local marking falsified by round-2 taint` → `exit=0`, `4 template rail mint(s) of which 0 left dirty`; emitted module mints `cq_template_mul_i32_hl(%out1,2)` ONCE in `entry` and adjoints it ONCE in `out:` | reviewer | 2026-09-17 15:05 |
| `control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll` (**mover 8**) | 7c1163ad / e951d5d1 | `cq controlled lowering: control flow inside a loop body under quantum control` → `cq loop lowering: hoisted invariant rail admitted for in-loop discharge was not discharged` — the postcondition IS reachable and HAS a customer | reviewer | 2026-09-17 15:05 |
| `grep -rln "round-1 iteration-local marking falsified" ir-pass/test/` | 7c1163ad94d06320 | `1` — `ir-pass/test/loop_pairing_reject_round2_falsified.ll`; the string is at `LoopLowering.cpp:4349`. ⇒ after P0+P3 that fence has **ZERO** pins (independently confirmed) | reviewer | 2026-09-17 15:05 |
| source read: `recordRound1RailGrant` adjacency | e951d5d1bc072902 | present at `lowerLoops` (`LoopLowering.cpp:5932`); **ABSENT at both `collapseFlattenedLoopRails` `markIfRailLocal` sites**, which run at `CQLoweringPass.cpp:600`, before `repropagateControlMerges` at `:616` | reviewer | 2026-09-17 15:05 |
| source read: postcondition slot | e951d5d1bc072902 | `declineUndischargedExitObligations(M)` called from `Uncomputation.cpp:2057` (inside `uncompute`, outside the per-function loop) ⇒ both entry points; ledger `.clear()` at the top of `lowerLoops` (`:5811`); `repropagateControlMerges` calls `collapseFlattenedLoopRails` but **not** `lowerLoops`, so round-1 obligations survive | reviewer | 2026-09-17 15:05 |
| source read: pipeline order | 7c1163ad94d06320 | `declineDephasingUnmarkedLoopRails` at `:817/:1280` is **after** `repropagateControlMerges` (`:616/:1198`) ⇒ the new conjunct runs at FINAL taint, no L1 window (confirms IMPL_T3 F-R3-1); `emitDeferredDephasingDecline` at `:938/:1331` is **after** `uncompute` (`:872/:1315`) | reviewer | 2026-09-17 15:05 |

## Direction check — computed, not remembered

| gate | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| sha-256 over each probe's lowered IR (`ModuleID`/`source_filename` stripped), ORACLE vs SUBJECT, all 16 accepting probes | 9bd01598 vs 7c1163ad | **MOVED=10, UNMOVED=6.** All 10 movers are `leak -> discharge`; **zero** `discharge -> leak`, zero `ACCEPT -> DECLINE`, zero `DECLINE -> ACCEPT`. Movers: `a1_apost`, `b1_depth3_nest_hoisted`, `b2_two_sibling_loops`, `g1`, `g2`, `g5`, `g6`, `g8a`, `g10`, `m_none_oder_none_none_none`. Unmoved: `b1b`, `b3`, `b4`, `g4`, `g8`, `g8b`, `p2c` | reviewer | 2026-09-17 15:06 |
| F-1 re-confirmed at IR level on the SAME stage-1 file, both binaries | 9bd01598 / 7c1163ad | both: `exit=0`, **0** `_unc`, **0** `cqrt_free`, 2 `cq_template_ashr` mint sites (rolled) | reviewer | 2026-09-17 15:06 |

## NOT RUN by me, by role

The full `ctest -j6`, `ir-pass-lit`, `^e2e-` as a layer, any twin matrix, any corpus sweep, any
injection/mutation matrix, `negative_vacuity_check.py`, the duplicate-body scan and
`cq-opt-equivalence-full`. I built nothing. **A skipped layer is a deferred cost, not a saved one.**

## PROTOCOL finding (for `MERGE_FILINGS.md`) — see REVIEW.md F-4

The session scratchpad **root** is shared and writable by every parallel agent. Another agent's
`probe.sh` (hard-coded to worktree `agent-ac2acfdde3461becc`) overwrote mine at 14:44 and one of
my batches ran on a **third binary, `96d74fe6008133b8`**, producing a well-formed but void row.
It was caught by an output-format mismatch, not by any check. **All measurements in this review
were re-run from scratch on `probes/gp.sh`, a private copy, after that.** `PROTOCOL.md` §6.1
governs gates, not shared scratch; recommend adding: *every agent works in its own scratch
subdirectory, never at the scratchpad root.*
