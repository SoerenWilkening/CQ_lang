# Session-level GATES.md — 2026-09-14

Format (PROTOCOL.md): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
A gate result is a fact about a BINARY, not about a moment. A cited line whose hash does not match the binary
on disk is a FINDING.

ORACLE (frozen, main checkout `build/`, from `59ac5b7`):
`cq-opt` f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc ·
`libCQPass.so` f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d

Carried from `$PREV/CLOSING_MEASUREMENTS.md` at `59ac5b7` (cite, do not re-run):

```
full ctest -j6           | f7b65d8ccd7bc472 | 420/420, 393.20 s                    | 2026-09-13 close | 2026-09-13
cq-opt-equivalence-full  | f7b65d8ccd7bc472 | 1928/0                               | 2026-09-13 close | 2026-09-13
counts                   | f7b65d8ccd7bc472 | lit 1928 · goldens 367 · ctest 420 (^e2e- 410, ^e2e-slice- 365, twin-identical 34) · twin cells 259+29=288 | 2026-09-13 close | 2026-09-13
```

## This session

### Track U (bd `z9t1`) — branch `undef-seed-zero`, tip `8865f7d5`, subject `cq-opt` `a5773be142835fb8`

```
ir-pass-lit              | a5773be142835fb8 | 100% tests passed, 0 failed out of 1 (1936 fixtures), 225.31 s | U impl  | 2026-09-14
lit RED step (pre-change)| f7b65d8ccd7bc472 | 5 new accepts RED, 2 controls green                            | U impl  | 2026-09-14
e2e slices (undef-seed)  | a5773be142835fb8 | 4/4                                                            | U impl  | 2026-09-14
e2e slices (measure-cls) | a5773be142835fb8 | 8/8, goldens byte-identical                                    | U impl  | 2026-09-14
e2e slices (cascade)     | a5773be142835fb8 | 9/9, goldens byte-identical (29 and 19)                        | U impl  | 2026-09-14
injection matrix         | a5773be142835fb8 | 10 mutations x 9 accepts: applied 67, MISSED 0, N/A 23         | U impl  | 2026-09-14
vacuity scan             | a5773be142835fb8 | 0 VACUOUS                                                      | U impl  | 2026-09-14
corpus sweep (PARTIAL)   | a5773be142835fb8 | 2793 rows, 7 movers, 1 CLANGERR (identical both binaries)      | U impl  | 2026-09-14
corpus tail sweep        | a5773be142835fb8 | 98 rows, 0 movers                                              | U impl  | 2026-09-14
e2e stage-1 scan         | (clang only)     | 391 slices: only the 3 new ones carry the trigger; 0 undef angles | U impl | 2026-09-14
```

⚠ **OWED BY THE GROUP GATE for Track U:** `cq-opt-equivalence-full` — no decline string moved, but analysis
sites did. ⚠ The corpus sweep was stopped by exact PID under load 300–440 and closed by a reasoned tail
argument, not by completion; the round-1 reviewer is auditing that closure.

## CROSS-TRACK COMPOSITIONS THE MERGE GATE MUST TEST — neither track's own sweep can see these

Both were found by adversarial review, not by any track's gates, and each is invisible to the tracks
individually **by construction**. The merge-and-gate agent MUST run each named probe on the COMBINED binary
and record the result here.

| # | probe | tracks | ORACLE | each track alone | expected on the MERGED binary |
|---|---|---|---|---|---|
| X1 | `trackF/review_r1_probes/p9_undef_seed.ll` | **F × U** | DECLINE at **F1** (before F2) | unchanged on either binary | **DECLINE(F1) → ACCEPT** — Track U normalizes the undef seed to a concrete zero *before classification*, which turns `p9` into Track F's accept fixture byte-for-byte. Found by the Track F round-1 reviewer (F-F1-3). |
| X2 | the F2 seed population as a whole | **U × F** | — | — | Track U hands F2 a seed population containing **normalized zeros F2 never saw at HEAD**, so Track F's φ-descendant conjunct must be re-run **with both changes present, not either alone**. Found by the Track U round-2 reviewer. |

⚠ X1 and X2 are the same interaction seen from both sides, and **that is the argument for the group gate**:
a per-track gate would have cleared each change and missed the composition entirely.

Also owed at the group gate, recorded here so it is not forgotten:
* **`cq-opt-equivalence-full`** — owed by Tracks U (analysis sites moved), D (decline string **and** analysis
  site moved) and F (analysis site moved).
* **One complete corpus sweep on the merged binary**, read for **diagnostic LOCATIONS as well as verdicts**
  (Track P's F-P2: a lost `!dbg` is invisible to every other gate). Two tracks' own sweeps did not finish
  under load and were closed by tail arguments; this is where that is repaid.
* **A duplicate-body scan** (sha-256 over each fixture's non-comment lines) — Tracks P and F each `git mv`'d
  or inverted fixtures, and a merge can resurrect a `git mv`'d fixture (L8).
* **The widened twin matrix** (328 cells) run over Track W's code — Track T lands first in that group.

### Added by Track F round 2 — more named probes for the merge gate

| # | probe | must be | why it exists |
|---|---|---|---|
| X3 | `trackF/review_r2_probes/r7_mbeta_base_offcone.ll`, `r12_mbeta_ifelse_rechain.ll` | **DECLINE** | the ONLY tripwires anywhere for the M-β RAUW-target invariant — had the RAUW manufactured a φ-descendancy they would accept |
| X4 | `trackF/review_r2_probes/r5_round2_phidesc.ll` + control `r5c` | `r5` ACCEPT on the subject, `r5c` DECLINE on all three | the round-2-reachability pair: proves F2's conjunct really is asked over the POST-EMISSION graph (anchor attributed to an `%out1`-named value) |

Rule 19 moments 1 and 5 both apply to this group: **`cq-opt-equivalence-full` + the full `ctest -j6`**.

---

## MERGE-AND-GATE — the ONE GROUP gate (all six branches), 2026-09-14

Merged tip `c1ee70350790381d9253e093222d383178e00bff` on branch `merge-gate-2026-09-14`
(worktree `/Users/sorenwilkening/Desktop/CQ_merge`, off `main` `28eac7d2`).
Merge order T→U→F→P→W→D, merge commits `6d6cf118` · `1ef4f4ac` · `599c8e3b` · `ab88d94f` ·
`0abcbd49` · `c1ee7035`. Full report: `$SES/MERGE_REPORT.md`. Evidence: `$SES/merge_gate_probes/`.

**SUBJECT BINARY** `cq-opt` `5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8` ·
`libCQPass.so` `5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4`
(`cmake --build build -j8`, whole tree, exit 0, no new warning).

```
build (both targets)     | 5c6f7490a81c7505 | ran: exit 0; warnings identical to main's three            | merge-gate | 2026-09-14 13:1x
duplicate-body scan (L8) | 5c6f7490a81c7505 | ran: 1993 fixtures; groups 7/9/6/8 under four normalisations (== Track F's 1938-file reconciliation); CONTRADICTORY-VERDICT groups 0; all 4 deleted fixtures confirmed absent (no resurrection) | merge-gate | 2026-09-14 13:12
FULL ctest -j6           | 5c6f7490a81c7505 | ran: RED — 99% tests passed, 3 tests failed out of 444, 497.00 s. FAILED 318 e2e-loop-twin-matrix · 406 e2e-slice-control-select-bool-round2-window · 409 e2e-slice-control-select-cmp-round2-window | merge-gate | 2026-09-14 13:24
  re-run serial -j1 (406,409) | 5c6f7490a81c7505 | ran: 0% passed, 2/2 failed, 1.82 s — CONTENTION EXCLUDED, real regression | merge-gate | 2026-09-14 13:25
  attribution of 406/409 | (7 binaries)     | ran: ORACLE/U/F/P/W all ACCEPT; **D 4394b3495c1c539f DECLINES both**; MERGED declines both => TRACK D ALONE, not a composition | merge-gate | 2026-09-14 13:27
  twin matrix 318        | 5c6f7490a81c7505 | ran: 338 cells, 41 verdict changes; TRACE-DIVERGENCE 29 == 29 quarantined; both boundary controls held. 18 attributed D, 23 attributed W. NOT regenerated | merge-gate | 2026-09-14 13:24
cq-opt-equivalence-full  | 5c6f7490a81c7505 | ran: compared 1993 fixtures, 0 mismatch(es), 2m53s          | merge-gate | 2026-09-14 13:31
corpus sweep (COMPLETE)  | 5c6f7490a81c7505 | ran: 4194 rows in 6m45s, run to completion; 290 movers, 1 CLANGERR (identical both binaries). Attribution BY MEASUREMENT on all 5 single-track binaries: D 107 · U 70 · P 47 · W 40 · F 18 · COMPOSITION 8 · **UNATTRIBUTABLE 0** | merge-gate | 2026-09-14 13:38
diagnostic-LOCATION scan | 5c6f7490a81c7505 | ran: 2060 decline rows — LOST locations 0 · GAINED 21 · new locationless declines from a .c source 0 | merge-gate | 2026-09-14 13:42
Track W 40edde36 vs d47297cf | 40edde36678c7dd4 / d47297cfe72e7fa3 | ran: 2385 modules (fixture corpus + all Track W probes + all 290 movers) — VERDICT DIFFS 0, STDERR DIFFS 1 (a GAINED location on c3_rotate_after.c). The post-clearance edits ARE diagnostic-only, as judged | merge-gate | 2026-09-14 13:47
X1 p9_undef_seed + undef spelling of every Track-F customer | 5c6f7490a81c7505 | ran: HELD — ORACLE DECLINE(F1) -> MERGED ACCEPT, lowered IR byte-identical to control_inplace_ry_stateprep_phidesc_collider_accept.ll; all four customers' undef spelling == their `= 0` twin's verdict, traces BYTE-IDENTICAL (29/35/45 lines), STRICT 2b clean | merge-gate | 2026-09-14 13:05
X2 F2 family x undef seed | 5c6f7490a81c7505 | ran: HELD — 39 F2-naming fixtures with every cq_theta SEED set to undef: 0 ACCEPT on the merged binary; 4 movers, all DECLINE->DECLINE (F1 -> a later, more specific fence) | merge-gate | 2026-09-14 13:10
X3 M-beta tripwires     | 5c6f7490a81c7505 | ran: HELD — r7_mbeta_base_offcone and r12_mbeta_ifelse_rechain both stay DECLINE(F2) | merge-gate | 2026-09-14 13:07
X4 round-2 reachability | 5c6f7490a81c7505 | ran: HELD — r5_round2_phidesc ACCEPT, control r5c_round2_nonphidesc DECLINE(F2) | merge-gate | 2026-09-14 13:07
X5 back-edge collider pair + reachability | 5c6f7490a81c7505 | ran: the TWO NAMED FIXTURES DID NOT MOVE (F2 decline, byte-identical CQ_CTRL_DBG anchor, lit 4/4). ⚠ BUT THE BACK-EDGE SHAPE IS NOW REACHABLE: three probes of the shape wx8g admits go from `control flow inside a loop body` on the ORACLE to F1-decline / ACCEPT / ACCEPT on the merged binary. ArmClassify.cpp trigger (3a)'s premise is FALSE; the re-derivation it demands is OWED | merge-gate | 2026-09-14 13:08
counts (merged tree)    | 5c6f7490a81c7505 | ran: ctest 444 (^e2e- 434, ^e2e-slice- 383, twin-identical 40) · lit 1993 · goldens 385 · twin cells 309+29=338 · equivalence 1993/0 | merge-gate | 2026-09-14 13:48
```

⚠ **The counts above are measured on a tree whose full suite is RED.** Re-measure after §3a of the
report is resolved.

### RESOLUTION PASS — same gate, same binary, 2026-09-14 (coordinator dispositions 1–5)

⚠ **THE BINARY DID NOT MOVE.** The resolution touched only `tests/e2e/` (two slices unregistered, two
goldens deleted), one new `ir-pass/test` fixture, and `tools/loop_twin_matrix.py` (a Python
instrument). Rebuilt and re-hashed: `cq-opt`
`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8` and `libCQPass.so`
`5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4` — **BIT-IDENTICAL** to the gated
build. Every `cited:` line below is therefore a fact about the binary on disk, not a memory.

```
build after conversion   | 5c6f7490a81c7505 | ran: exit 0, BOTH artefacts BIT-IDENTICAL to the gated build | merge-gate | 2026-09-14 13:51
new decline fixture      | 5c6f7490a81c7505 | ran: control_swap_reject_select_rail_round2_window.ll — lit PASS; NON-VACUITY by BINARY MUTATION: FileCheck DOES NOT MATCH on the ORACLE f7b65d8c (opt exit 0) and MATCHES on 5c6f7490 (opt exit 1) | merge-gate | 2026-09-14 13:50
duplicate-body scan (re) | 5c6f7490a81c7505 | ran: 1994 fixtures; groups 7/9/6/8 UNCHANGED; CONTRADICTORY-VERDICT groups 0 — the new fixture is in a group of size 1 | merge-gate | 2026-09-14 13:56
twin matrix --regenerate | 5c6f7490a81c7505 | ran: DELIBERATE (adjudication written first, MERGE_TWIN_ADJUDICATION.md). 309 cells written, 29 quarantined and omitted; **exactly the 41 adjudicated cells changed, set-identical, 0 extra 0 missing**; quarantine BYTE-UNTOUCHED at 29 | merge-gate | 2026-09-14 13:56
  header survival (mech.)| 5c6f7490a81c7505 | ran: `EXPECTED_HEADER is a PREFIX of the table: True`; 447 #-lines / 309 rows; all four corrected-block markers present in the written table. Track T's 54-line defect did NOT recur | merge-gate | 2026-09-14 13:57
FULL ctest -j6 (RE-RUN)  | 5c6f7490a81c7505 | ran: **GREEN — 100% tests passed, 0 tests failed out of 442. Total Test time (real) = 448.60 sec** (load 3,38 at start) | merge-gate | 2026-09-14 14:04
cq-opt-equivalence-full  | 5c6f7490a81c7505 | cited: compared 1993 fixtures, 0 mismatch(es) — the binary is bit-identical, and the one added fixture is a DECLINE, so the sweep's subject set grew by a module both binaries refuse identically | merge-gate | 2026-09-14 13:31
corpus sweep (4194 rows) | 5c6f7490a81c7505 | cited: 290 movers, D 107 · U 70 · P 47 · W 40 · F 18 · COMPOSITION 8 · UNATTRIBUTABLE 0 | merge-gate | 2026-09-14 13:38
diagnostic-LOCATION scan | 5c6f7490a81c7505 | cited: 2060 decline rows — LOST 0 · GAINED 21 · locationless-from-.c 0 | merge-gate | 2026-09-14 13:42
X1 / X2 / X3 / X4 / X5   | 5c6f7490a81c7505 | cited: X1 HELD · X2 HELD · X3 HELD · X4 HELD · X5 fixtures held, SHAPE NOW REACHABLE (filed) | merge-gate | 2026-09-14 13:05–13:08
COUNTS on the GREEN tree | 5c6f7490a81c7505 | ran: ctest **442** (^e2e- 432, ^e2e-slice- 381, twin-identical 40) · lit **1994** · goldens **383** · twin cells **309+29=338** · equivalence 1993/0 (cited) | merge-gate | 2026-09-14 14:05
```

**Records produced:** `MERGE_REPORT.md` · `MERGE_TWIN_ADJUDICATION.md` (the per-group table, written
BEFORE the regeneration) · `MERGE_FILINGS.md` (X5-owed · the F×P composition · the three `il*`×`bcar`
over-declines) · a measured ERRATUM on `PROTOCOL.md` §S1 · `merge_gate_probes/` (31 files).
