# Track D — `GATES.md` (bd `3d8q`, the stale-reader fence)

Format (PROTOCOL): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
A gate result is a fact about a BINARY. Read this file before running anything; cite, do not re-run.

## Binaries built in this track (worktree `/Users/sorenwilkening/Desktop/CQ_3d8q`)

| # | `cq-opt` sha256 (16) | what changed |
|---|---|---|
| B0 | `f7b65d8ccd7bc472` | baseline build of the worktree at `607b6fe4`, no edits — **BIT-IDENTICAL to the frozen session ORACLE** (`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`); `libCQPass.so` also identical (`f9e898ba…`). Recorded because it makes every ORACLE-vs-SUBJECT row below a statement about MY EDITS and nothing else. |
| B1 | `aeac68944b489a6b` | reader policy folded into `declineStaleRecordOps` at the EARLY slot |
| B2 | `979f93eb546aaec3` | + a local mutual-exclusion filter (later retired for the policy bit) |
| B3 | `08ca9cc06a13908f` | + `RequireEmitDominance` threaded through `WireWalk` (the local filter removed) |
| B4 | `99c947d75b9e4d8f` | + readers scoped out of the post-lift re-sweep |
| B5 | `82d76e6f39cef365` | reader half split into its own LATE stage (pre-`declineClassicalMuxes`) |
| B6 | `08bd940154dadce6` | analysis moved back EARLY, diagnostic DEFERRED to the late stage |
| B7 | `8e508cacc950975d` | emit moved to the last slot before `lowerRotations` |
| B8 | `7fe2bcbfb6c97126` | the branch tip `e7d6efe2` AS REVIEWED in round 1 — + the DELTA-SCOPED round-2 re-ask, and 5 shipped fixtures adjudicated. Full: `7fe2bcbfb6c9712613952e6db33ab36dc3525275af99109cf0edfe4ea112fb23`; `libCQPass.so` `4f73e1c8cb5f59244a6e0cfad17682c75c5b60926223ba5fc9e252d6b0b9e4c0`. ⚠ **EVERY GATE LINE BELOW THAT NAMES B8 IS VOID FOR THE CURRENT TIP.** |
| B9 | `33af613009b823e8` | B8 + the round-1 reviewer's **TRACED** F-D1-1 fix (`gateIsHarmless(I, I, …)` as the self-exemption condition). **REJECTED BY MEASUREMENT** — 12 shipped ACCEPT fixtures decline. Full: `33af613009b823e80ac1588a380fc12c32a230bf9395d50ea6de10cc8b94c758`. |
| B10 | `0f3d512529c5d106` | B8 + the **CORRECTED** F-D1-1 fix (`WireWalk::readerStalesItself`). This is what `HELD_F-D1-1.patch` contains; it is **HELD, not landed**, pending the owner ruling. Full: `0f3d512529c5d1066fc82b38f21444efbe17088fe344a4c83f67cd2eee93c672`. |
| **B11** | **`abe3e0ecfdad3961`** | **THE NEW BRANCH TIP** — B8 + F-D1-2 (the `WeakVH` drain) + F-D1-3 + F-D1-4 + F-D1-5 + the in-loop self-assign ACCEPT fixture; F-D1-1 reverted to B8's behaviour. Full: `abe3e0ecfdad39612e39940ce12195b3f1d2157b9b274d792a4a358efc8fc123`; `libCQPass.so` `00aa785c956db86d0cc2245a5fb4ed848449c4b19afdae40253b46681eb212cc`. |

## Gate lines

```
build (cmake --build build -j8, BOTH targets)   | f7b65d8ccd7bc472 | exit=0                                   | impl | 2026-09-14 10:11
lit ir-pass/test (whole dir, assessment)        | aeac68944b489a6b | 1811 pass / 116 FAIL (25 accept, 91 reject) | impl | 2026-09-14 10:31
lit ir-pass/test (whole dir, assessment)        | 979f93eb546aaec3 | 1812 pass / 102 FAIL (19 accept, 83 reject) | impl | 2026-09-14 10:38
lit ir-pass/test (whole dir, assessment)        | 08ca9cc06a13908f | 1840 pass /  74 FAIL ( 6 accept, 68 reject) | impl | 2026-09-14 10:44
lit ir-pass/test (whole dir, assessment)        | 99c947d75b9e4d8f | 1842 pass /  72 FAIL ( 4 accept, 68 reject) | impl | 2026-09-14 10:47
lit ir-pass/test (whole dir, assessment)        | 82d76e6f39cef365 | 1851 pass /  16 FAIL (13 accept,  3 reject) | impl | 2026-09-14 10:51
lit ir-pass/test (whole dir, assessment)        | 08bd940154dadce6 | 1861 pass /   6 FAIL ( 3 accept,  3 reject) | impl | 2026-09-14 10:53
lit ir-pass/test (whole dir, assessment)        | 8e508cacc950975d | 1863 pass /   4 FAIL ( 3 accept,  1 reject) | impl | 2026-09-14 10:55
lit ir-pass/test (whole dir, assessment)        | 7fe2bcbfb6c97126 | 1935 pass / 1 XFAIL / 0 FAIL (1937 discovered) | impl | 2026-09-14 12:05
lit --filter (per fixture, as written)          | 7fe2bcbfb6c97126 | 9/9 new stale_reader fixtures PASS        | impl | 2026-09-14 12:00
injection matrix (3 NEW accept fixtures)        | 7fe2bcbfb6c97126 | 36 mutations, **0 MISSED**                | impl | 2026-09-14 11:58
injection matrix (2 EDITED accept fixtures)     | 8e508cacc950975d | 24 mutations, 8 MISSED                    | impl | 2026-09-14 11:52
injection matrix (same 2, ORIGINAL text)        | f7b65d8ccd7bc472 | 24 mutations, 8 MISSED — IDENTICAL, so PRE-EXISTING debt | impl | 2026-09-14 11:53
vacuity.py (5 accept fixtures)                  | 8e508cacc950975d | 0 named negatives checked -> N/A, NOT a pass (IMPL_D §7) | impl | 2026-09-14 11:50
duplicate-body fixture scan (sha-256/1937)      | 7fe2bcbfb6c97126 | 9 duplicate-body groups, ALL pre-existing, none involves a new fixture | impl | 2026-09-14 12:10
!dbg anchor check (7 -g probes, Track P lesson) | 7fe2bcbfb6c97126 | 7/7 real file:line:col, 0 `<unknown>:0:0`, every column on the offending READER (IMPL_D §7b) | impl | 2026-09-14 13:05
```

> The eight `lit ir-pass/test` assessment rows are the inner loop, each on a DIFFERENT binary, so
> none is redundant with another (PROTOCOL: a gate result is a fact about a binary). They are the
> measurement that drove the design: **116 → 0** is not tuning, it is FIVE separate structural
> findings plus five written fixture dispositions, each recorded in `IMPL_D.md` §4 and §8.

## Hand-off gates (B8, the branch tip, only)

```
ctest -R ir-pass-lit                            | 7fe2bcbfb6c97126 | 1/1 Test #8 ir-pass-lit Passed 95.80 sec; 100% tests passed, 0 failed out of 1 | impl | 2026-09-14 12:05
corpus sweep ORACLE-vs-SUBJECT                  | 7fe2bcbfb6c97126 | 3093 rows (1937 lit + 369 e2e + 787 probes, 1 CLANGERR); 43 movers, ALL this track's string, **0 in e2e/** | impl | 2026-09-14 12:40
ctest -R '^e2e-loop-twin-matrix$'               | 7fe2bcbfb6c97126 | TWIN_RESULT | impl | 2026-09-14
```

## NOT run by this agent, deliberately (PROTOCOL matrix for an implementer)

`ctest -j6 -R '^e2e-'`, the full `ctest -j6`, and `cq-opt-equivalence-full` are the
merge-and-gate agent's. ⚠ **This track MOVED A DECLINE STRING and ADDED AN ANALYSIS SITE, so
`cq-opt-equivalence-full` is REQUIRED of the group gate** (PROTOCOL S1's "iff any track in the group
moved a decline string or an analysis site").

## Round-1 FIX round gate lines (2026-09-14) — `ran:` vs `cited:`

⚠ **Every line in the two blocks ABOVE is a fact about B8 `7fe2bcbf` and is VOID for the tip B11.**
They are retained as `cited(B8 only)`; they were NOT re-run.

```
ran: cmake --build build -j8 (BOTH targets)     | 33af613009b823e8 | exit=0                                                    | fix | 2026-09-14
ran: ctest -R ir-pass-lit                       | 33af613009b823e8 | 1924 pass / 1 XFAIL / 14 FAIL (of 1939) — the REVIEWER'S TRACED F-D1-1 fix; 12 of the 14 are shipped ACCEPT fixtures. REJECTED. | fix | 2026-09-14
ran: cmake --build build -j8 (BOTH targets)     | 0f3d512529c5d106 | exit=0                                                    | fix | 2026-09-14
ran: ctest -R ir-pass-lit                       | 0f3d512529c5d106 | 1934 pass / 1 XFAIL /  4 FAIL (of 1939) — the CORRECTED F-D1-1 fix; all 4 failures are programs containing the r5 shape, 2 of which already decline on the ORACLE | fix | 2026-09-14
ran: lit --filter 'stale_reader'                | 0f3d512529c5d106 | 11/11 PASS (incl. both new fixtures)                      | fix | 2026-09-14
ran: fix_r1_probes/m3.sh, r5 family (11 probes) | O + 7fe2bcbf + 0f3d5125 | r5/r5a/r5b/r5d/r5h A→A→D; r5c/r5e D on both; r5f/r5g/r5i/r5t A on all three | fix | 2026-09-14
ran: cmake --build build -j8 (BOTH targets)     | abe3e0ecfdad3961 | exit=0 — THE TIP                                          | fix | 2026-09-14
ran: ctest -R ir-pass-lit                       | abe3e0ecfdad3961 | 1/1 Test #8 ir-pass-lit Passed 82.19 sec; 100% tests passed, 0 failed out of 1 (1938 fixtures on disk) | fix | 2026-09-14
```

Three `ir-pass-lit` runs, three DIFFERENT binaries, three different questions — not redundant under
PROTOCOL ("a gate result is a fact about a binary").

**NOT run by this agent, deliberately** (FIX brief): no corpus sweep (one per session, the merge
gate's — ⚠ the B8 sweep above stands **for B8 only** and must be labelled so wherever it is quoted),
no full `ctest`, no `^e2e-`, no `cq-opt-equivalence-full`, no twin matrix. ⚠ The group gate still owes
`cq-opt-equivalence-full`: this track moved an analysis site.

### The landed tip's PARITY gate (the one that matters for B11)

The landed delta is a handle-type change in the drain, so the question is whether it moves ANY verdict
or ANY stream. Measured directly, both binaries on the SAME stage-1 module, comparing exit code,
**full stderr** and the lowered IR:

```
ran: B8 7fe2bcbf vs B11 abe3e0ec over all 60 cached probe modules (fix_r1_probes/s1/*.ll)
     compared=60  differing=0      # identical exit code, identical stderr, identical lowered IR
```

Every module was checked NON-ZERO before it was measured. Together with `ctest -R ir-pass-lit` PASSED
on B11 (1938 fixtures), that is the evidence for "the landed change moves nothing".
⚠ It is NOT the corpus sweep (lit + e2e + every session probe dir), which remains the merge gate's.

⚠ **ONE MEASUREMENT WAS INVALIDATED BY THIS AGENT AND IS NOT REPORTED.** A second sweep
(`m1.sh LANDED`, all 60 probes end-to-end on B11) was running when its output directory was deleted
during a commit tidy-up; its last ~10 rows read `D[]` / `A[0]` because the harness could not write or
read its own files, which is a HARNESS artifact and not a verdict. It is discarded whole, not
partially quoted. The 60/60 parity gate above was run afterwards, cleanly, and answers the same
question more directly (exit code + full stderr + lowered IR, both binaries, same input).
This is the CLAUDE.md lesson "never relink/disturb a binary or its outputs under a running
measurement", earned again: a failed gate that is actually an artefact is worse than a slow gate.

## OWNER-RULING landing gate lines (2026-09-14, DECLINE) — `ran:` vs `cited:`

⚠ **Every line above that names B11 `abe3e0ec` is VOID for the tip below.** The tip is B10's binary:
applying `HELD_F-D1-1.patch` plus a comment-only addition at `gateIsHarmless`' leg 1 reproduced
`0f3d512529c5d106…` **BIT-IDENTICALLY** (comments do not reach codegen), so the B10 lines are facts
about this exact binary and are marked `ran:` rather than `cited:`.

| # | `cq-opt` sha256 (16) | what |
|---|---|---|
| **B12 = B10** | **`0f3d512529c5d106`** | **THE TIP.** B11 + the landed `readerStalesItself`. Full: `0f3d512529c5d1066fc82b38f21444efbe17088fe344a4c83f67cd2eee93c672`; `libCQPass.so` `4dc93cff90b658f2721b1c3fb1c5da6f6bf3575c360cba17bc26b9bb44a5964a`. |

```
ran: cmake --build build -j8 (BOTH targets)   | 0f3d512529c5d106 | exit=0; BIT-IDENTICAL to B10        | fix | 2026-09-14
ran: ctest -R ir-pass-lit (after the 4 fixture conversions + the 2 new pins)
                                              | 0f3d512529c5d106 | 1/1 Test #8 ir-pass-lit Passed 162.35 sec; 100% tests passed, 0 failed out of 1 (1940 fixtures on disk) | fix | 2026-09-14
ran: lit --filter 'stale_reader'              | 0f3d512529c5d106 | 12/12 PASS (4 accepts, 8 declines)   | fix | 2026-09-14
ran: verdict sweep over all 60 probe modules  | 0f3d512529c5d106 | 14/14 reproducers DECLINE; the 8 hand-built well-formed programs (r1,r2,r3,r4,r6,r7,r8,r11) ALL ACCEPT — no over-decline; r5/r5a/r5b/r5c/r5d/r5e/r5h DECLINE; r5f/r5g/r5i/r5t ACCEPT; every must-not-move row keeps its own string | fix | 2026-09-14
```

⚠ **The 162.35 s is NOT comparable to the 82.19 s recorded for B11**: three agents were running
`ir-pass-lit` concurrently (`CQ_3d8q`, `CQ_wx8g`, `CQ_lang`), measured by `lsof` on the live PIDs.
Contention causes false FAILURES, never false passes (CLAUDE.md), so the PASS stands; only the timing
is void.

**NOT run, deliberately** (brief, unchanged): no corpus sweep, no full `ctest`, no `^e2e-`, no
`cq-opt-equivalence-full`, no twin matrix. ⚠ The group gate still owes `cq-opt-equivalence-full` —
this track moved an analysis site AND now moves four fixture verdicts.

## ROUND-2 FIX gates (binary B13 — the ONLY binary these rows are about)

| # | `cq-opt` sha256 (16) | what |
|---|---|---|
| B13a | `6480de5f7a82084d` | an INTERMEDIATE of this round, kept only so its rows can be marked VOID: the F-D2-2 leg WITHOUT clause (C1) (the classical-guard fence). Its gate lines are superseded and are NOT reproduced here. |
| **B13** | **`4394b3495c1c539f`** | **THE NEW TIP.** B12 + the F-D2-2 fix: `readerStalesItself` leg 1b (`readerRunsAtMostOncePerActivation` + `guardValueOnLatchEdge`, file-local in `WireWalk.cpp`), `LoopInfo`/`AssumptionCache`/`TargetLibraryInfo`/`ScalarEvolution` built at `recordStaleQuantumReaders`' existing lazy point, clause (C1) refusing a TAINTED guard, + 3 new fixtures + 1 reworded retirement trigger. Full: `4394b3495c1c539fd88b03a08144feed1d723a604feb3f02e3e931f67ced54ef`; `libCQPass.so` `7f7ff051d12b51123f4dac85d81bda13386791c00a72b4897377feec951011b5`. |

⚠ **EVERY ROW ABOVE THIS HEADING — `0f3d5125…`, `abe3e0ec…`, `7fe2bcbf…`, and B13a's `6480de5f…` —
IS VOID FOR B13.** A gate result is a fact about a binary (PROTOCOL). The rows below are the ones
re-taken on B13 itself, after the (C1) clause landed; nothing measured on B13a is cited.

```
ran: cmake --build build -j8 (BOTH targets)        | 4394b3495c1c539f | exit=0                                                  | fix-r2 | 2026-09-14
ran: ctest --test-dir build -R ir-pass-lit         | 4394b3495c1c539f | 1/1 Test #8 ir-pass-lit Passed 49.36 s; 100% tests passed, 0 failed out of 1 | fix-r2 | 2026-09-14
ran: lit ir-pass/test (count)                      | 4394b3495c1c539f | 1942 pass / 1 Expectedly Failed of 1943 discovered (1943 .ll on disk) | fix-r2 | 2026-09-14
ran: lit --filter 'stale_reader'                   | 4394b3495c1c539f | 15/15 PASS (was 12/12 at B12; +2 accepts, +1 decline)    | fix-r2 | 2026-09-14
ran: lit --filter 'control_inplace_ry'             | 4394b3495c1c539f | 246/246 PASS                                            | fix-r2 | 2026-09-14
ran: lit --filter 'inloop|loop'                    | 4394b3495c1c539f | 184/184 PASS                                            | fix-r2 | 2026-09-14
ran: fix_r2_probes/m.sh, all 78 round-2 probes (73 .c + 5 hand .ll), BEFORE = the REAL B12 binary
                                                   | 0f3d512529c5d106 vs 4394b3495c1c539f | EXACTLY 2 movers: ob1_reader_runs_once_in_loop D->A[4], ob1b_first_iteration_flag D->A[4]. Both traces BYTE-IDENTICAL to the ORACLE's. | fix-r2 | 2026-09-14
ran: fix_r2_probes/m27.sh, the 27 ROUND-1 probes (the 14 reproducers + the must-not-move table), BEFORE = the
     B12 `cq-opt` + runtime archives SAVED ASIDE across the rebuild (hash re-verified `0f3d512529c5d106`)
                                                   | 0f3d512529c5d106 vs 4394b3495c1c539f | `diff BEFORE27.txt AFTER27.txt` EMPTY — all 27 unmoved in BOTH verdict and trace count; the 8 must-not-move accepts keep their recorded counts (a10=10, f1w2=6, oc1=11, oc3=10, m3=4, l2=18, l3=39, trackM_s04=16) | fix-r2 | 2026-09-14
ran: lowered-IR byte-compare (ModuleID stripped), every probe accepting on both
                                                   | 0f3d512529c5d106 vs 4394b3495c1c539f | 47 identical, 0 differing (78-probe set + the 27 round-1 probes) | fix-r2 | 2026-09-14
ran: stderr byte-compare, every probe declining    | 0f3d512529c5d106 vs 4394b3495c1c539f | 78-probe set: 2 differing (ob1, ob1b — the intended movers), 0 others. ⚠ the 8 p27_* ACCEPT rows also differ, and it is NOT a compiler difference: BEFORE27 linked against the SAVED `/tmp/B12/runtime/*.a`, so the `ld:` warnings name different PATHS; 0 `cq ` diagnostics on either side, measured | fix-r2 | 2026-09-14
ran: fix_r2_probes/adv, 6 one-token mutants of the new accept fixture
                                                   | 4394b3495c1c539f | a1 A(2 ry) / a2 A(2 ry) / a3 D (residual over-decline, filed) / a4 D (correct) / a5 D (SOUNDNESS control) / a6 A (polarity) | fix-r2 | 2026-09-14
ran: fix_r2_probes/oa1_shape_scan.py over ir-pass/test/*.ll (self-tested on the known positives)
                                                   | n/a (static)     | 1938 fixtures scanned; 1 holds the F-D2-1 shape and it declines at an unrelated earlier fence => NEITHER disposition of oa1/oa1t is pinned | fix-r2 | 2026-09-14
ran: F-D2-5 recount (gateIsHarmless / walker faces) | n/a (static)    | gateIsHarmless: 1 call site (WireWalk.cpp:812). Public faces: 18 lines, 1 prose => 17 code sites, 1 of them this increment's => 16 pre-existing | fix-r2 | 2026-09-14
ran: rebuild REPRODUCIBILITY (stash -> B12 -> stash pop -> rebuild)
                                                   | 6480de5f7a82084d | the second build of the same tree was BIT-IDENTICAL to the first (`cq-opt` and `libCQPass.so`); measured on B13a, and it is a fact about the BUILD, not about the lowering | fix-r2 | 2026-09-14
```

**NOT run, deliberately (brief):** no corpus sweep (one per session, the merge gate's), no full
`ctest`, no `^e2e-`, no `cq-opt-equivalence-full`, no twin matrix. ⚠ The group gate still owes
`cq-opt-equivalence-full`; this track moved an analysis site, four fixture verdicts, and now adds
three fixtures and an ACCEPT-direction leg.
