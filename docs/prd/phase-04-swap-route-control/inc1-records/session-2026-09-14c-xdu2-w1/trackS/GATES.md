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

## NOT RUN, and why (Rule 19 — report only what you ran)

`ctest -R ir-pass-lit`, the ORACLE-vs-SUBJECT corpus sweep and the injection matrix are the
hand-off gates for an IMPLEMENTATION. **There is none** — the branch tip's `cq-opt` is bit-identical to
the ORACLE, so a corpus sweep would compare a binary with itself (0 movers by construction) and an
injection matrix would have no new accept to mutate. Running them would be an instrument reporting a
pass on nothing, which is the failure mode `CLAUDE.md` L10 names. The full suite, `^e2e-`, the
equivalence sweep and the twin matrix are out of this track's matrix in every case.
