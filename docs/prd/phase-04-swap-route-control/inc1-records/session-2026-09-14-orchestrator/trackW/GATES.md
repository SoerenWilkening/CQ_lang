# Track W — GATES.md (bd `wx8g`, session 2026-09-14)

Format (PROTOCOL.md): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>`

ORACLE (frozen, read-only): `cq-opt` `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`,
`libCQPass.so` `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`. Verified before the
first probe.

| gate | binary | result | who | when |
|---|---|---|---|---|
| ORACLE hash verify | f7b65d8ccd7bc472 | matches PROTOCOL.md exactly (cq-opt + libCQPass.so) | impl | 2026-09-14 10:26 |
| build worktree `cmake --build build -j8` (BOTH targets) | f7b65d8ccd7bc472 | `BUILD exit=0`; **cq-opt sha256 BIT-IDENTICAL to the ORACLE** (tree is `main` 607b6fe4 = docs-only over 59ac5b7) | impl | 2026-09-14 10:33 |
| build worktree (edit batch 1: the scaffold; REMOVED before commit) | e04d9b50f4d0b9e8 | `BUILD exit=0` | impl | 2026-09-14 10:37 |
| build worktree (edit batch 2: the real clause, brace defect) | — | `BUILD exit=2` — `LoopPlan.h:464 no type named 'Instruction'` | impl | 2026-09-14 10:44 |
| build worktree (edit batch 3) | 3800759c85ecd8e9 | `BUILD exit=0` | impl | 2026-09-14 11:00 |
| build worktree (edit batch 4: conjunct-2 precondition) | 95a33b2ea04155d1 | `BUILD exit=0` | impl | 2026-09-14 11:10 |
| per-probe pipeline, 22 probes + 4 hand-IR modules | 95a33b2ea04155d1 | see IMPL_W.md §0/§1/§5 | impl | 2026-09-14 11:20 |
| `lit --filter` on each new/flipped fixture (14 files) | 95a33b2ea04155d1 | 14/14 PASS | impl | 2026-09-14 11:40 |
| `ctest -R '^e2e-…bool-loop…'` (10 slices + 5 twin gates) | 95a33b2ea04155d1 | `100% tests passed, 0 tests failed out of 15`, 146.40 s | impl | 2026-09-14 11:45 |
| **`ctest -R ir-pass-lit`** (ONCE at hand-off) | 95a33b2ea04155d1 | `1/1 Test #8: ir-pass-lit … Passed 222.72 sec`; `lit ir-pass/test` = **1937 passed / 1 XFAIL of 1938** | impl | 2026-09-14 11:50 |
| build worktree (edit batch 5: the `Esc` DebugLoc fallback + comment repairs) | daeb93a36bdc57b3 | `BUILD exit=0` — ⚠ the binary MOVED, so every `95a33b2e` line above is re-gated below | impl | 2026-09-14 11:55 |
| build worktree (comment-only edit batch, in between) | 95a33b2ea04155d1 | `BUILD exit=0`, **BIT-IDENTICAL** to the previous build — a comment edit does not move this compiler | impl | 2026-09-14 11:34 |
| ORACLE-vs-SUBJECT corpus sweep, `ir-pass/test/**.ll` COMPLETE (1983 `.ll` files) + 20 session probes | 95a33b2ea04155d1 | **3 movers, all DECLINE→ACCEPT with the ORACLE string `control flow inside a loop body`** — the three flipped fixtures. 0 CLANGERR. STOPPED before the remaining session-probe dirs on orchestrator instruction (one sweep per session belongs to the merge gate) | impl | 2026-09-14 11:48 |
| twin-matrix `i1` cells, 40/40 reconstructed from Track T's generator and run on BOTH binaries | f7b65d8c (ORACLE) vs daeb93a36bdc57b3 | **9 UNROLLED-ONLY → ACCEPT-IDENTICAL; 8 DECLINE-BOTH-DIFFERENT → DECLINE-BOTH (the passing move, ZERO ROLLED-ONLY); 9 ACCEPT-IDENTICAL unchanged md5-for-md5; 14 unchanged** | impl | 2026-09-14 12:05 |
| **`ctest -R ir-pass-lit`** (RE-RUN — the binary moved) | daeb93a36bdc57b3 | `1/1 Test #8: ir-pass-lit … Passed 169.24 sec`, `100% tests passed` | impl | 2026-09-14 12:10 |
| `ctest -R '^e2e-…bool-loop…'` (RE-RUN — the binary moved) | daeb93a36bdc57b3 | `100% tests passed, 0 tests failed out of 15`, 32.25 s | impl | 2026-09-14 12:12 |
| injection matrix over the 5 new accepts | 95a33b2ea04155d1 | `TOTAL applied 40   MISSED 0   N/A 5` (every N/A explained in IMPL_W.md §8.4) | impl | 2026-09-14 11:25 |
| vacuity over the 5 new accepts | 95a33b2ea04155d1 | `29 named negatives … 0 VACUOUS` | impl | 2026-09-14 11:28 |
| **NOT RUN** (PROTOCOL matrix, implementer row) | — | full `ctest -j6`, `^e2e-`, `cq-opt-equivalence-full`, `tools/loop_twin_matrix.py` | impl | — |

## Review round 1 — the FIX agent (2026-09-14 afternoon)

⚠ **EVERY LINE ABOVE IS VOID FOR THE NEW BINARY.** The fix moved `cq-opt` from
`daeb93a36bdc57b3` to **`40edde36678c7dd4`** (`libCQPass.so`
`e82fe15c6aae983ef397873e7c344c72730aba3f213e248ca1c52267e2d07bd0`). Everything below is
`ran:` on that binary unless the row says `cited:`.

| gate | binary | result | who | when |
|---|---|---|---|---|
| `ran:` pre-fix reproduction, 4 F-W1-1 controls + `b4`/`b5`/`b6` | daeb93a36bdc57b3 | `b1_twofn` **ACCEPT 40**, `b6_noattr` **ACCEPT 40**; `b1_twofn_rev`/`b2_norecord`/`b3_failfail`/`ctl_wj` DECLINE — the review's finding reproduced independently, on its own artefacts | fix | 2026-09-14 12:12 |
| `ran:` pre-fix reproduction, `d3`/`d4` + the 3 F-W1-3 deltas | daeb93a36bdc57b3 | `d3` **ACCEPT 30** (twin 34), `d4` ACCEPT 28 (twin 34), `od2`/`od3`/`od4` DECLINE (twins ACCEPT 16) | fix | 2026-09-14 12:13 |
| `ran:` build worktree `cmake --build build -j8` (BOTH targets, never `--target CQPass` alone) — fixes 1+2 | a01bdf7bcd42ac53 | `BUILD exit=0` | fix | 2026-09-14 12:20 |
| `ran:` `lit ir-pass/test` (full) on the fixes-1+2 binary | a01bdf7bcd42ac53 | **1 FAILED: `control_inplace_ry_inloop_offset.ll`** — a SHIPPED drbq Inc-3 accept; the (b′) half of the F-W1-2 widening needed F-W1-3's exclusion to keep it. Recorded, not hidden | fix | 2026-09-14 12:26 |
| `ran:` scratch DEBUG builds (candidate dump + `CQ_FORCE_NOCAND`), **discarded, never committed** | — | measured the candidate sets: `offset.ll` = 1 candidate, `InPlaceRailOps`=1; `d3`/`d4` = `and`+`add`, `InPlaceRailOps`=0; `od2`/`od3`/`od4` `InPlaceRailOps`=**0** | fix | 2026-09-14 12:35 |
| `ran:` forced-accept twin diff for the three claimed F-W1-3 over-declines | scratch | `od4` rolled **BYTE-IDENTICAL** to twin 16=16 (a GENUINE over-decline, filed); `od2`/`od3` **DIVERGE** (`cq_template_{add,xor}_i32_hl` fresh rail vs `cqrt_{addc,xorc}` in place) — their declines are **CORRECT**, correcting the review | fix | 2026-09-14 12:40 |
| `ran:` build worktree (fixes 1+2+3) | **40edde36678c7dd4** | `BUILD exit=0` | fix | 2026-09-14 12:45 |
| `ran:` 4 F-W1-1 controls + `b4`/`b5`/`b6` | 40edde36678c7dd4 | **ALL SEVEN DECLINE** `control flow inside a loop body` — `b1_twofn` 40→DECLINE, `b6_noattr` 40→DECLINE | fix | 2026-09-14 12:47 |
| `ran:` `d3`/`d4`/`d1`/`d2` | 40edde36678c7dd4 | `d3` 30→**DECLINE**, `d4` 28→**DECLINE**; `d1` ACCEPT 32 (twin-identical) and `d2` ACCEPT 27 UNCHANGED | fix | 2026-09-14 12:47 |
| `ran:` `od2`/`od3`/`od4`, `ctl_wi`, `a1`, `a2` | 40edde36678c7dd4 | `od*` DECLINE (unchanged; `od2`/`od3` correctly, `od4` a filed over-decline); `ctl_wi` ACCEPT 14, `a1` ACCEPT 9, `a2` ACCEPT 10 — all unchanged | fix | 2026-09-14 12:47 |
| `ran:` `lit --filter control_inplace_ry_inloop_offset` | 40edde36678c7dd4 | PASS — the regression is closed by the `InPlaceRailOps` exclusion | fix | 2026-09-14 12:46 |
| `ran:` the 18-probe implementer sweep + the **8 twin pairs** re-diffed | 40edde36678c7dd4 | 8/8 **BYTE-IDENTICAL** at 8/10/12/9/11/27/17/14 lines — identical to IMPL_W §1; `w_j` and `w_c` decline with their own strings | fix | 2026-09-14 12:50 |
| `ran:` K-independence, 5 slices, K=3 vs K=1000, no `-g` | 40edde36678c7dd4 | 81/81, 66/66, 85/85, 83/83, 105/105 — identical to IMPL_W §1.2 | fix | 2026-09-14 12:52 |
| `ran:` NEW probe `w_l_twofn_mixed_clauses` (clause (c) + clause (b′) in one module) | 40edde36678c7dd4 vs ORACLE | ORACLE **DECLINE** → SUBJECT **ACCEPT 22**, **BYTE-IDENTICAL** to its hand-unrolled twin | fix | 2026-09-14 12:55 |
| `ran:` the 3 NEW fixtures under `lit --filter` | 40edde36678c7dd4 | 3/3 PASS | fix | 2026-09-14 13:00 |
| `ran:` injection matrix over the new ACCEPT fixture | 40edde36678c7dd4 | `TOTAL applied 8   MISSED 0   N/A 1` (`unc-discharge-dropped`, the same genuine absence as IMPL_W §8.4 — no `_unc` exists, which IS the claim, pinned by the `NOMINT` prefix) | fix | 2026-09-14 13:02 |
| `ran:` vacuity over the 3 new fixtures | 40edde36678c7dd4 | `5 named negatives … 0 VACUOUS` against an 8-module universe. ⚠ A 6-module universe reported **2 false VACUOUS** — the V2 half is only as good as its universe, and that is an instrument lesson, not a fixture defect | fix | 2026-09-14 13:05 |
| `ran:` **`ctest -R ir-pass-lit`** (ONCE, as the brief directs) | 40edde36678c7dd4 | `1/1 Test #8: ir-pass-lit … Passed 170.57 sec`; `lit ir-pass/test` = **1940 passed / 1 XFAIL of 1941**, 0 failed | fix | 2026-09-14 13:10 |
| `ran:` TARGETED golden probe (NOT the `^e2e-` ctest layer): every `tests/e2e/slice_control_*.c` containing a loop, 33 slices, compiled + linked + byte-diffed against its committed golden | 40edde36678c7dd4 | **32 GOLDEN-MATCH**; 1 pre-existing expected DECLINE (`slice_control_phase_onward_perbit_loop_mixed`, `control flow under quantum control` at `:53:18`) verified BYTE-IDENTICAL on the ORACLE. 0 regressions | fix | 2026-09-14 13:15 |
| `ran:` comment-only rebuild (the H-3 / (c3)-trigger comments) | 40edde36678c7dd4 | `BUILD exit=0`, **BIT-IDENTICAL** — so every row above stands for the committed tree | fix | 2026-09-14 13:20 |
| `cited:` ORACLE-vs-SUBJECT corpus sweep (`3 movers`) | 95a33b2ea04155d1 | ⚠ **STANDS FOR THE PRE-FIX BINARY ONLY.** The fix moved the binary twice since; the sweep is the MERGE gate's (one per session) | fix | — |
| **NOT RUN** (brief, PROTOCOL matrix) | — | full `ctest -j6`, the `^e2e-` ctest layer, `cq-opt-equivalence-full`, `tools/loop_twin_matrix.py`, a second corpus sweep | fix | — |

## Review round 2 — the FIX agent (2026-09-14 afternoon)

⚠ **EVERY LINE ABOVE IS VOID FOR THE NEW BINARY.** This pass moved `cq-opt` from `40edde36678c7dd4`
to **`d47297cfe72e7fa3`** (`libCQPass.so`
`55c83c4a1c2d0ec26713c97f3714459cd96fe27238a5815349c9631dd74867c1`). ⚠ **And it moved for THREE code
reasons, not one** — the F-W2-5 anchor fallback (`declAnchor` + the shared `anchorIsLocated`), the
F-W2-4 `isa<BinaryOperator>` narrowing of the `InPlaceRailOps` exclusion, and conjunct 1's
`getDebugLoc()` → `anchorIsLocated` test. Everything below is `ran:` on `d47297cf` unless it says
`cited:`. Full record: `FIX_W_R2.md`.

| gate | binary | result | who | when |
|---|---|---|---|---|
| `ran:` binary hash verify BEFORE the first edit | 40edde36678c7dd4 | `cq-opt` + `libCQPass.so` match `REVIEW_W_R2.md` §0 exactly | fix-r2 | 2026-09-14 14:05 |
| `ran:` F-W2-5 pre-fix reproduction, two-TU `-g` recipe | 40edde36678c7dd4 | `w2i2_h1_round2` / `w2i3_h1_cmpcond` DECLINE `condition predates a non-diagonal gate` at **`<unknown>:0:0`**; ORACLE `:16:18` / `:17:15` — the review's finding reproduced independently | fix-r2 | 2026-09-14 14:10 |
| `ran:` decline-site identification, `lldb -b` breakpoint backtrace on `cq::diagnoseUnderControl` | 40edde36678c7dd4 | `classifyPhaseKickback` ← `detectControlRegions` ← **`repropagateControlMerges`** (ROUND 2), both probes. Anchor via the in-tree `CQ_CTRL_DBG` lever: `%3 = icmp sgt i32 %out, 50`, **no `!dbg`** (LICM-hoisted). MEASURED, not inferred | fix-r2 | 2026-09-14 14:15 |
| `ran:` `cmake --build build -j8` (BOTH targets, never `--target CQPass` alone) | **d47297cfe72e7fa3** | `BUILD exit=0`, 63.8 s | fix-r2 | 2026-09-14 14:35 |
| `ran:` F-W2-5 post-fix, two-TU `-g`, BOTH binaries | d47297cfe72e7fa3 vs f7b65d8c | SUBJECT `<unknown>:0:0` → **`./w2i2_h1_round2.c:18:13`** and **`./w2i3_h1_cmpcond.c:18:13`** (the `if (y > 50)` line); ORACLE unchanged | fix-r2 | 2026-09-14 14:40 |
| `ran:` `anchor_sweep.sh` — 85 `-O1 -g` probes × BOTH binaries | d47297cfe72e7fa3 vs f7b65d8c | SUBJECT **59 ACCEPT / 26 DECLINE, 1 unlocated anchor**; ORACLE **5 unlocated**. The 4 extra ORACLE ones are the SAME 2c fence (`w_c_compare_invariant`, `w_e_iterlocal_base_cmp`, `w_f_iterlocal_prep_cmp`, `w_h_iterlocal_escape`) and are now located on the SUBJECT — **the class was PRE-EXISTING at that fence**. The 1 remaining is D-3 (`kMsgCrossIter`), identical on both | fix-r2 | 2026-09-14 14:45 |
| `ran:` anchor NON-REGRESSION control — the 5 anchors `REVIEW_W_R2.md` recorded on `40edde36` | d47297cfe72e7fa3 | `:18:31` / `:8:31` / `:19:31` / `:12:20` / `:9:14` — **all unchanged character-for-character** | fix-r2 | 2026-09-14 14:45 |
| `ran:` the **8 twin pairs** (+ `w_l`) re-diffed | d47297cfe72e7fa3 | **9/9 BYTE-IDENTICAL** at 8/10/12/9/11/27/17/14/22 — identical to IMPL_W §1 and to the round-1 fix record | fix-r2 | 2026-09-14 14:50 |
| `ran:` K-independence, 5 slices, K=3 vs K=1000, no `-g` | d47297cfe72e7fa3 | **81/81, 66/66, 85/85, 83/83, 105/105** — identical to IMPL_W §1.2 | fix-r2 | 2026-09-14 14:52 |
| `ran:` **`ctest -R ir-pass-lit`** (ONCE, as the brief directs) | d47297cfe72e7fa3 | `1/1 Test #8: ir-pass-lit … Passed 54.41 sec`, `100% tests passed` | fix-r2 | 2026-09-14 14:55 |
| `ran:` `lit ir-pass/test` (full, for the count) | d47297cfe72e7fa3 | **1940 passed / 1 expectedly failed of 1941**, 0 failed | fix-r2 | 2026-09-14 14:57 |
| `ran:` `lit --filter control_inplace_ry_reject_inloop_iterlocal_twofn` after the header edit | d47297cfe72e7fa3 | PASS | fix-r2 | 2026-09-14 15:00 |
| `ran:` D-1 / D-2 disclosure re-measurement, BOTH binaries (`disclose.sh`) | d47297cfe72e7fa3 vs f7b65d8c | `w2c_inplace_rail` ORA DECLINE → SUB ACCEPT 14, DIVERGES from twin; the no-region control `w2c_noregion_inplace` diverges IDENTICALLY at 6=6 on BOTH and is SUB==ORA byte-identical (bd `a3z7` class B). `w2g_mut_d3_invread` DECLINE on both, twin ACCEPT 34 on both (an over-DECLINE); `w2g_mut_d1_no_invread` SUB ACCEPT 32 twin-identical | fix-r2 | 2026-09-14 15:05 |
| `cited:` ORACLE-vs-SUBJECT corpus sweep (`3 movers`) | 95a33b2ea04155d1 | ⚠ **STANDS FOR A BINARY THREE MOVES AGO.** The merge gate's one sweep per session **MUST run against `d47297cf`**, not cite this one | fix-r2 | — |
| **NOT RUN** (brief, PROTOCOL matrix) | — | full `ctest -j6`, the `^e2e-` ctest layer, `cq-opt-equivalence-full`, `tools/loop_twin_matrix.py`, a corpus sweep | fix-r2 | — |
