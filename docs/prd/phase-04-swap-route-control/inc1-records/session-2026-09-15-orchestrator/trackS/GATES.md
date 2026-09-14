# Track S′ — GATES.md (hash-keyed; PROTOCOL non-redundancy)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>`

A gate result is a fact about a BINARY. Before running a gate, read this file; if the
binary hash is unchanged and the gate is recorded, CITE the line instead of re-running it.

## Binaries

| label | `cq-opt` sha256 | `libCQPass.so` sha256 | what it is |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | `main` `74eabd2c`, the frozen session oracle (`/Users/sorenwilkening/Desktop/CQ_lang/build`) |
| PRE-FIX (RED baseline) | `0e280fc6…` (BIT-IDENTICAL to the ORACLE) | `94602c78…` | this worktree's first build; my source edits were not yet compiled, so it IS the oracle — verified by `shasum`, not assumed |

⚠ The pre-fix build coming out BIT-IDENTICAL to the oracle is itself the check
PROTOCOL asks for: the worktree reproduces `main`'s binary byte for byte, so every
RED/GREEN delta below is attributable to my edit and to nothing else.

## Gate lines

lit --filter loop_leak_dephase (RED, Rule-12 red-green) | 0e280fc62a91cec2 | Failed Tests (5): loop_leak_dephase_accept_inplace_volatile.ll, loop_leak_dephase_reject_cmp_rail_data.ll, loop_leak_dephase_reject_inloop_rotation.ll, loop_leak_dephase_reject_noregion_live.ll, loop_leak_dephase_reject_region_derivedbase_live.ll — Passed 2 (the two accept fixtures, which must NOT move) | impl | 2026-09-15 00:04
per-probe ORACLE reproduction of the three beads | 0e280fc62a91cec2 | c767 (b7b_w2k_interfered) ACCEPT exit 0 + kMsgLiveRecord warning; 7845 (b11_cmp_rail_data) ACCEPT exit 0 + kMsgLiveRecord warning; 2g52 (b10_inplace_volatile) DECLINE "…rotated after the loop" at :6:11 — all three reproduce exactly as round 1β reported | impl | 2026-09-15 00:02
| SUBJECT (pre-cede) | `f667cf90436bd31da241d3ff6dec0c5775a57d319c6f7658edec5647f66532a8` | `630d959d5c12a22d52730c06bc0872e7b1413920d1c7864da13ab8da06a6c458` | conjuncts (2)+(3) widened, BEFORE the §4 stale-marking cede |
| SUBJECT (final) | `15f6a75a50faba7a2c99a969497044ca6211293ea00ad6388510c6cc17bff96d` | `e39dba218d4ba6988fedb66ace582c82af2e9214963ad07f3501a90367579ef2` | + the stale-marking cede; the binary every gate below cites |

lit --filter loop_leak_dephase (GREEN, pre-cede) | f667cf90436bd31d | Passed 6 of 7 — Failed Tests (1): loop_leak_dephase_accept_inplace_volatile.ll (my CHECK block assumed source order; `-O1` lays the loop EXIT block before the BODY block) | impl | 2026-09-15 00:34
ctest -R ir-pass-lit (pre-cede) | f667cf90436bd31d | Passed 2040 (99.90%) / Expectedly Failed 1 / **Failed 1: lowering_reject_inplace_rail_stale_w2_add_derived.ll** — a decline->decline STRING MOVE, this fence preempting the bd eqpx tripwire. THE FINDING OF THE SESSION; no probe of mine or of round 1beta has that shape | impl | 2026-09-15 00:41
ctest -R ir-pass-lit (FINAL) | 15f6a75a50faba7a | Passed 2041 (99.95%) / Expectedly Failed 1 / Discovered 2042 / Failed 0 — 93.88 s | impl | 2026-09-15 00:58
lit --filter loop_leak_dephase (FINAL) | 15f6a75a50faba7a | Passed 7 of 7 (4 reject + 3 accept) | impl | 2026-09-15 01:05
ps.sh over the bead subjects + twins | 15f6a75a50faba7a | b7b 20->DECLINE (twin 24 unmoved); b7c 34->DECLINE (twin 42 unmoved); b11 10->DECLINE (twin 14 unmoved); b10 DECLINE->ACCEPT 7 (twin 7), rolled trace `cmp`-CLEAN against the twin | impl | 2026-09-15 01:02
ps.sh over the controls | 15f6a75a50faba7a | ALL UNMOVED: s3 22/22 (positive control), w2k 16, w2h 30, w2h3 44 (the three D4-BENIGN) + twins 20/38/48, s1+s2 still DECLINE, b5 8/8, b7 18/18, b4_fpcast 10/10, s4 still `cq taint escape` | impl | 2026-09-15 01:02
ps.sh harness self-attack (L10) | 15f6a75a50faba7a | i0_empty -> VACUOUS-NO-QUANTUM; i1_noquantum -> VACUOUS-NO-QUANTUM (both would score ACCEPT through the passthrough early-out without the guard) | impl | 2026-09-15 00:59
injection matrix (FIRST run) | 15f6a75a50faba7a | applied 11, **MISSED 1** (`d_stray_ry` on loop_leak_dephase_accept_inplace_volatile.ll — an uncontrolled cqrt_ry on the user register, caught by nothing), N/A 13 | impl | 2026-09-15 01:10
injection matrix (after the RY prefix + the i_add_discharge_inplace mutation) | 15f6a75a50faba7a | applied 12, MISSED 0, N/A 15 | impl | 2026-09-15 01:14
warnLiveRecordRotations correlation (bd bbu0) | 0e280fc62a91cec2 + 15f6a75a50faba7a | ORACLE warns on all three newly-closed members (b7b 1, b7c 1, b11 2) and is silent on every accepting control; SUBJECT counts are 0 BY PREEMPTION for every declining row (diagnose EXITS on the first DS_Error, bd br4a) | impl | 2026-09-15 01:20
