# Track S — GATES (PROTOCOL format: `<gate> | <sha256 cq-opt, first 16> | <result verbatim> | <who> | <when>`)

⚠ The clean PRE-EDIT build of this worktree is **BIT-IDENTICAL to the ORACLE**
(`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8` /
libCQPass.so `5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4`),
so every "before" number below is an ORACLE number by construction.

```
oracle-hash-verify | 5c6f7490a81c7505 | /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt sha256 == 5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8 (matches BRIEF_S §7) | impl | 2026-09-14
build worktree (cmake --build build -j8) | 5c6f7490a81c7505 | exit 0; cq-opt 5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8, libCQPass.so 5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4 — BIT-IDENTICAL TO ORACLE | impl | 2026-09-14
```
```
per-probe pipeline (3 bead programs + twins, SUBJECT=bit-identical-to-ORACLE) | 5c6f7490a81c7505 | w2k 16 / un 20; w2h 30 / un 38; w2h3 44 / un 48 — all 6 ACCEPT, opt exit 0, STRICT 2b "0 violation(s), 0 unproven" — reproduces F-W2-3 exactly | impl | 2026-09-14
per-probe pipeline (s1/s2/s3 + twins, SUBJECT) | 5c6f7490a81c7505 | s1 10 / un 14 DIVERGE; s2 19 / un 25 DIVERGE; s3 22 / un 22 BYTE-IDENTICAL — all 6 ACCEPT, opt exit 0, STRICT 2b "0 violation(s), 0 unproven" | impl | 2026-09-14
per-probe pipeline (s1/s1_un/s2/s3, ORACLE /Users/sorenwilkening/Desktop/CQ_lang) | 5c6f7490a81c7505 | s1 10, s1_un 14, s2 19, s3 22 — identical to SUBJECT; the class is PRE-EXISTING | impl | 2026-09-14
rolled-ness verification (lowered IR back edge, s1/s2/s3) | 5c6f7490a81c7505 | all three carry `br i1 %N, label %1, label %M, !llvm.loop` + a header phi; s1_un is straight-line — the subjects are genuinely ROLLED | impl | 2026-09-14
```
```
L10 instrument selftest (4 attacks on rs.sh, inherited rv2.sh spelling) | 5c6f7490a81c7505 | 3 LIES MEASURED in the PASS direction: stale trace reported "ACCEPT|lines=8" for a run that never linked; 0-byte .c reported "ACCEPT" + 2b "0 violation(s)"; empty count printed as a result. All 3 closed and re-attacked GREEN (LINKFAIL / VACUOUS-S1 / NOTRACE). 4th attack (perturb s3 twin angle 0.3->0.31) fires the diff => the 22==22 identity is LIVE, not vacuous | impl | 2026-09-14
per-probe pipeline, all 12 probes RE-RUN on the HARDENED harness | 5c6f7490a81c7505 | every line count unchanged (16/20, 30/38, 44/48, 10/14, 19/25, 22/22) — the hardened harness is not a weaker command | impl | 2026-09-14
rebuild after comment-only scoping edits (3 sites) | 5c6f7490a81c7505 | cq-opt 5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8, libCQPass.so 5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4 — STILL BIT-IDENTICAL TO ORACLE; no gate result moves | impl | 2026-09-14
lit --filter control_inplace_ry_reject_rail_inloop_carried_invariant_read | 5c6f7490a81c7505 | Total Discovered Tests: 1994, Excluded 1993, Passed 1 | impl | 2026-09-14
```

## PART II — the D4 implementation

⚠ TWO SUBJECT BINARIES EXIST AND ONLY THE SECOND IS CITED FOR ANY FINAL GATE. `00b84dc1facb1c9f…` was
the first build of the decline; a self-review then found its cheap-skip DEREFERENCED `taint.Tainted`
(the first post-flatten consumer to do so), so it was made deref-free and rebuilt to
`09694fb88985df25…`. A sweep already running against `00b84dc1` was **STOPPED and its partial output
DELETED** rather than cited, because a gate result is a fact about a BINARY (PROTOCOL) and that binary
no longer exists on disk. Nothing below cites `00b84dc1`.

```
build worktree, decline v1 | 00b84dc1facb1c9f | exit 0; cq-opt 00b84dc1facb1c9ff66979c70cf490cfa7aeb26f9a8184fdd1290b0e92b5fb9d, libCQPass.so 9db27ca282aa95d70b24a8df67aea7b2bfc0120b8cd54e96e9fcece71c93fe92 | impl | 2026-09-14
build worktree, decline v2 (deref-free prescan) | 09694fb88985df25 | exit 0; cq-opt 09694fb88985df25639993d4f162f13ff7057a8452458634ad87d45a8f31d1c3, libCQPass.so b476f7b41eaba62b6e582c3572caaf7786c462e30c97096a2bcfc649d0a9e952 | impl | 2026-09-14
lit --filter loop_leak_dephase (RED-GREEN: run BEFORE the implementation) | 5c6f7490a81c7505 | Total Discovered 1996, Excluded 1994, Failed 2 — both decline fixtures RED, as Rule 12 requires | impl | 2026-09-14
lit --filter loop_leak_dephase | 09694fb88985df25 | Total Discovered 1998, Excluded 1994, Passed 4 | impl | 2026-09-14
per-probe pipeline (s1/s2/s3 + the 3 bead programs) | 09694fb88985df25 | s1 DECLINE @ s1_live_shift.c:11:14, s2 DECLINE @ s2_live_derived_region.c:11:22 (both the new string, both source-located); s3 ACCEPT 22, w2k ACCEPT 16, w2h ACCEPT 30, w2h3 ACCEPT 44 — the positive control and all three bead programs UNMOVED | impl | 2026-09-14
injection matrix, FIRST DRAFT of the accept fixtures | 00b84dc1facb1c9f | applied 7, MISSED 7, N/A 3 — the matrix earned its keep | impl | 2026-09-14
injection matrix, final | 09694fb88985df25 | applied 8, MISSED 0, N/A 4 (every prefix incl. the pure-negative LEAK exercised by >=1 mutation) | impl | 2026-09-14
L10 attack on the injection harness | 09694fb88985df25 | no-fixture invocation exits 2 with a message, not "MISSED 0"; every mutation bounded by the enclosing define; N/A printed as a HOLE | impl | 2026-09-14
```

## NOT RUN, and why (Rule 19 — report only what you ran)

⚠ THIS PARAGRAPH IS PART I's AND IS SUPERSEDED BY PART II. It was true while the branch carried only
the determination (a bit-identical binary, nothing to sweep or mutate). With the D4 decline landed the
implementation row of the PROTOCOL matrix applies in full and all three gates are real: the injection
matrix and the targeted lit runs are above; `ctest -R ir-pass-lit` and the corpus sweep are recorded
below when they complete.

The full suite, `^e2e-`, `cq-opt-equivalence-full` and the twin matrices remain OUT of this track's
matrix in every case (the merge-and-gate agent's).
