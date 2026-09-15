# Track T — `GATES.md` (hash-keyed; PROTOCOL's non-redundancy rule)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

A gate result is a fact about a BINARY, not about a moment. A cited line whose hash
does not match the binary on disk is a FINDING.

## Binaries

| tag | `cq-opt` sha256 (first 16) | what it is |
|---|---|---|
| ORACLE | `0e280fc62a91cec2` | `main` `74eabd2c`, `/Users/sorenwilkening/Desktop/CQ_lang/build` — READ-ONLY, never rebuilt by this track. Verified at session open and again at every use. |
| S1 | `b942977e0833ae84` | + the round-1 ROOT-MINT escape at `markIfIterationLocal`'s slot, + the L1 record and re-ask (stale-roots spelling) |
| S2 | `9337c21095d0afdb` | + `invariantRegisterRootsImpl` clause (ii-c), the MEASURE-OWNED invariant rail |
| S3 | (below) | + the re-ask RE-DERIVES its roots under FINAL taint by calling `invariantRegisterRoots` (closes an over-decline S1/S2 had) |

Full `libCQPass.so` / `cq-opt` sha256, for the record:
```
ORACLE  cq-opt       0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d
ORACLE  libCQPass.so 94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b
S1      cq-opt       b942977e0833ae8459453e78052b39df0be899414230f77075950a399770e9bd
S1      libCQPass.so 0e9af5f998bbc68474510b7578283a96170fbbb57368764e3e59fe802cd114f5
S2      cq-opt       9337c21095d0afdba8bff8598ff5ba7511a8838c507397ae9742da0ed3ff6656
S2      libCQPass.so 8142d82041855d3f11c72a8c9f2a6854843d6d342537c029fad491283891550c
```

## Gate lines

```
build the worktree (cmake --build build -j8, BOTH targets) | b942977e0833ae84 | exit=0, 2 warnings, both PRE-EXISTING in RegionTreeDetect.cpp (OuterNeg/InnerNeg unused) | impl | 2026-09-15
per-probe pipeline (18 probes, s1/s2/s3/t1/t2/t3/w2h/w2h3/w2k + twins) | 0e280fc62a91cec2 | ORACLE baseline recorded in probes/out/*.ora.* | impl | 2026-09-15
per-probe pipeline (same 18) | b942977e0833ae84 | s1 DECLINE->ACCEPT 14==14 BYTE-IDENTICAL; t2 9->13==13 BYTE-IDENTICAL; t3 DECLINE->ACCEPT 20; s3 UNMOVED 22==22; s2/t1 still DECLINE; w2k/w2h/w2h3 UNMOVED (leak) | impl | 2026-09-15
lit ir-pass/test --filter loop | b942977e0833ae84 | 2 failed of 2039 discovered: loop_leak_dephase_reject_noregion_live.ll (its own L8 retirement trigger, expected), lowering_uncompute_interior_leak_loop_rail.ll (bd 6uqc leak probe, expected) | impl | 2026-09-15
build the worktree | 9337c21095d0afdb | exit=0, same 2 pre-existing warnings | impl | 2026-09-15
per-probe pipeline (18 probes + 18 adversarial) | 9337c21095d0afdb | w2k 16->20==20, w2h 30->38==38, w2h3 44->48==48 (gate SYMBOL MULTISET identical to twin in all three); a1 16==16 IDENTICAL; a2 18==18 IDENTICAL; a6 9==9 IDENTICAL unmoved; a7 36==36 IDENTICAL; a8 9==9 IDENTICAL unmoved; a9 24 vs 20 (twin CSE artefact, T-2); a3/a4/a5 DECLINE unmoved; b1/b2 ACCEPT-and-leak unmoved | impl | 2026-09-15
lit ir-pass/test (whole, unfiltered) | 9337c21095d0afdb | Failed: 1 of 2039 — loop_leak_dephase_accept_pertrip_dead.ll (its own L8 retirement trigger: "If a _unc or a cqrt_free ever appears here, either bd tu9q landed ... or something started freeing a dirty rail") | impl | 2026-09-15
lit ir-pass/test --filter loop_leak_dephase_reject_noregion_live | 9337c21095d0afdb | PASS (converted to ACCEPT) | impl | 2026-09-15
lit ir-pass/test --filter interior_leak_loop_rail | 9337c21095d0afdb | PASS (converted to ACCEPT) | impl | 2026-09-15
lit ir-pass/test --filter pertrip_dead | 9337c21095d0afdb | PASS (LEAK prefix retired to PAIR) | impl | 2026-09-15
lit ir-pass/test --filter loop_pairing_reject | 9337c21095d0afdb | PASS 2/2 (the two new (ii-c) boundary fixtures) | impl | 2026-09-15
L1 reachability, hand-written l1_round2_grow_65arm.ll | 9337c21095d0afdb | ORACLE prints bd s82e's string; SUBJECT prints "cq loop lowering: round-1 iteration-local marking falsified by round-2 taint" — the window is REACHABLE (finding T-1) | impl | 2026-09-15
```

## ⚠ THE CLEAN-REBUILD LINE (see `IMPL_T2.md` §13)

Every line ABOVE was taken on an INCREMENTALLY-built `cq-opt`. On `cfb00187163c3254` that binary was
measured **SEGFAULTING on a four-instruction module** while `libCQPass.so`, built from the same
sources in the same `cmake --build`, lowered it correctly — a `TaintSet` layout divergence between the
two targets, with `make` reporting the tree UP TO DATE. The lines above are kept as the record of what
was measured and when; **they are not quoted as facts about the shipped binary.** The fix was
`rm -rf build/ir-pass/CMakeFiles/cq-opt.dir` + reconfigure (deleting the dir removes `build.make`) +
rebuild.

| tag | `cq-opt` sha256 | note |
|---|---|---|
| S3/S4 | `cfb00187163c3254…` | ⚠ **BROKEN** — segfaults. Never used for a reported number. |
| **CLEAN** | **`f972906e961c7e55be581ae18550f12da4535946b831e5c63434c0f089e33951`** | `libCQPass.so` `592d54940fe06a8f2cc381d76e2249132f919c4d202ec288506420da2570f272` |

```
build the worktree (clean cq-opt.dir + reconfigure + cmake --build build -j6, BOTH targets) | f972906e961c7e55 | exit=0, 0 errors, only the 2 PRE-EXISTING RegionTreeDetect.cpp warnings | impl | 2026-09-15
discriminator: same module through cq-opt vs opt -load-pass-plugin | f972906e961c7e55 | AGREE (before the clean rebuild they DISAGREED — that disagreement is a BUILD fact, never a lowering one) | impl | 2026-09-15
per-probe pipeline, all 30 probes + 2 hand-written L1 modules | f972906e961c7e55 | verdicts in IMPL_T2.md §2(b); every one as designed | impl | 2026-09-15
e2e goldens generated + ctest -R '^e2e-(slice-)?loop-pairing' | f972906e961c7e55 | 4/4 Passed, 13.01 s. rootmint 14 lines, twin 14, `diff` BYTE-IDENTICAL; measure_owned 20 lines; STRICT 2b 0 violation(s), 0 unproven on all three | impl | 2026-09-15
ctest -R ir-pass-lit | f972906e961c7e55 | 1/1 Passed, 104.84 s (2042 fixtures, 1 XFAIL) | impl | 2026-09-15
lit --filter 'loop_leak_dephase|interior_leak_loop_rail|loop_pairing' (after the T-4 fixture fix; FIXTURE-only edits, binary unchanged) | f972906e961c7e55 | 8/8 PASS | impl | 2026-09-15
injection (mutation) matrix over the 5 accept fixtures | f972906e961c7e55 | **30 mutations applied, MISSED 0, N/A 10** (first run: MISSED 1 — finding T-4, a real hole, fixed) | impl | 2026-09-15
x1_xorc_inplace_in_body (Track S′'s hazard) | f972906e961c7e55 | ACCEPT; `grep -c 'cqrt_free|_unc'` over the lowered IR = **0**. The in-place relabel is neither adjointed nor freed | impl | 2026-09-15
l1_round2_grow_65arm.ll | f972906e961c7e55 | ACCEPT (the re-ask re-derives its roots and does not over-decline — finding T-1) | impl | 2026-09-15
l2_round2_grow_derived.ll | f972906e961c7e55 | DECLINE: `cq loop lowering: round-1 iteration-local marking falsified by round-2 taint` — the L1 window is REACHABLE, so the fence has a witness and is not a prediction | impl | 2026-09-15
```

## ABSENCES — gates NOT run, with the reason (an absence is not a green and not a failure)

* **`e2e-loop-twin-matrix` / `tools/loop_twin_matrix.py` — NEVER STARTED BY THIS TRACK.** Handed to the
  merge-and-gate agent. Two reasons: the box was at load average **170–391** throughout this track's
  work (measured with `uptime` at every gate), and Track I landed a BANK axis on
  `twinmatrix-bank-axis` that moves the matrix 338 → 359 cells, so a run from this worktree would
  report **21 `MISSING`** as pure version skew. ⚠ **This track ran the matrix ZERO times**, so it is
  not among the runs the cross-track `pkill -f 'loop_twin_matrix.py --clang'` could have killed.
  What this track ran INSTEAD, as the matrix's own mechanism on the shapes it touches: **15
  rolled-vs-hand-unrolled pairs (30 programs)** on both binaries — `probes/src` (9 pairs) and
  `probes/adv` (11 pairs incl. the boundary controls) — plus a committed `*-twin-identical` ctest gate.
* **Two of this track's own background runs were stopped BY ME, deliberately**, and neither is a
  vanished gate: the first `twin.sh` pass (superseded by the faster `twin2.sh`) and the first corpus
  sweep (stopped because a rebuild was about to relink the binary underneath it — `CLAUDE.md`'s
  "never relink under a running measurement"). Recorded so they are not mistaken later for runs that
  disappeared.
* **The full `ctest -j6`, `^e2e-` and `cq-opt-equivalence-full`**: PROTOCOL reserves all three for the
  merge-and-gate agent. Not run.

## THE CORPUS SWEEP — STARTED, STOPPED BY ME, HANDED TO THE MERGE-AND-GATE AGENT

`probes/corpus_T.sh` was started on the CLEAN binary and produced **14 rows with 0 movers** before I
stopped it deliberately. It was progressing at roughly one row per 20–30 s of wall clock against a
~2400-row list — hours, not minutes — with the box at load average **319** and host time visibly
dilated (the system clock advanced ~2 minutes across several minutes of my own wall time). Per the
orchestrator's instruction, a gate too expensive to finish under this load goes to the merge-and-gate
agent with the reason rather than being fought or half-reported.

⚠ **I stopped it; it did not vanish.** The reason was CPU contention with the twin measurement, which
is the higher-value gate for this class (it is the ONLY instrument that can see it). Recorded
explicitly because a cross-track `pkill -f 'loop_twin_matrix.py --clang'` ran today and the
orchestrator has asked every track not to mis-attribute a lost run — **this one was not lost.**

**What the 14 rows say, as far as they go:** every row is `A:<md5> == A:<md5>` or
`D:<sha1> == D:<sha1>` — ORACLE and subject agree on all 14. Among them is
`c1-round3/z21_preadd_volatile_imm.c`, which is the shape §11 names as the one plausible
stream-change surface of this increment (a PREHEADER dtzb chain with a `volatile` immediate, where the
new round-1 `invariantRegisterRoots` call could newly commit an in-place op). It is **UNMOVED**. That
is one data point, not the sweep.

**What still has full coverage without it:** `ir-pass/test/*.ll` is covered completely and more
strongly by `ctest -R ir-pass-lit` (2042 fixtures, PASSED at `f972906e961c7e55`), which checks each
fixture's own CHECK lines rather than an md5. **The genuine gap is `tests/e2e/*.c`** — 381 shipped
streams that only the sweep (or the `^e2e-` layer the merge agent owns) can compare. That gap is what
is being handed over, and `probes/corpus_T.sh` is committed and ready to run as-is: it already
includes `tests/e2e/*.c` in its list, deliberately, for exactly this reason.

## The twin re-measurement COMPLETED after the first close

```
twin re-measurement, 20 rolled-vs-hand-unrolled pairs (40 programs), probes/src + probes/adv | f972906e961c7e55 | COMPLETE. Every pair reproduces its earlier number exactly. BYTE-IDENTICAL: s1 14==14, s3 22==22, t2 13==13, a1 16==16, a2 18==18, a6 9==9, a7 36==36, a8 9==9, r3 24==24, r5 28==28. Adjudicated divergences: t3/w2h/w2h3/w2k (stage-1 -O1 position or canonicalisation, gate-symbol multiset identical), a9 (T-2), b1/b2 (the (ii-c) boundary controls, UNMOVED from the ORACLE), x1 (0 _unc / 0 free), r2 (T-6, gap isolated to the non-qualifying function). Declines unmoved: s2, t1, a3, a4, a5, r4, x2 | impl | 2026-09-15
round-2 probes r1..r5, ORACLE vs subject, lowered-IR md5 compared within each row | f972906e961c7e55 | r1 DECLINE->ACCEPT (T-5, NO TWIN WITNESS — filed); r2 DECLINE->ACCEPT (T-6, adjudicated clean); r3 DECLINE->ACCEPT, twin IDENTICAL; r4 DECLINE both, twin IR md5-SAME as ORACLE; r5 ACCEPT both, IR md5-SAME as ORACLE on BOTH halves | impl | 2026-09-15
```
