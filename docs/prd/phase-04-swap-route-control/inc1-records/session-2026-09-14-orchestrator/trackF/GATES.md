# Track F (IMPLEMENTATION) — GATES

Format (PROTOCOL.md): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
Worktree `/Users/sorenwilkening/Desktop/CQ_f2phi`, branch `f2-phi-descendant`.
The ORACLE (`/Users/sorenwilkening/Desktop/CQ_lang/build`) is READ-ONLY and was re-hashed before
every use: `cq-opt` `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`,
`libCQPass.so` `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`.

## Builds (every rebuild's hash, PROTOCOL §7)

| # | what | `build/ir-pass/cq-opt` sha256 | note |
|---|---|---|---|
| B0 | configure + `cmake --build build -j8` (BOTH targets — never `--target CQPass` alone) | `147cb3d69afd816d15eaea84e3d802f3a5b4105431508886583b442bfa7736e4` | the conjunct + helper |
| B1 | `cmake --build build -j8` after registering the e2e slice | `147cb3d69afd816d…` (unchanged — CMake-only edit) | |
| B2 | `cmake --build build -j8` after a COMMENT-ONLY edit to `ArmClassify.cpp` made post-gating | `147cb3d69afd816d…` — **BYTE-IDENTICAL** | the `.o` was genuinely recompiled (source 11:13:51 -> object 11:30:53) and the binary did not change, so every gate line below remains a fact about the binary on disk and none was re-run |

## Builds (fix round, review F-F1-1)

| # | what | `build/ir-pass/cq-opt` sha256 | note |
|---|---|---|---|
| B3 | `cmake --build build -j8` after the back-edge-φ narrowing + the header rewrite (BOTH targets; `--target CQPass` alone is the false-green trap) | `96fdd3a9d2c1cd36deb607f0440db0157280a7784a7766bdce04044cd3234cd1` | `libCQPass.so` `9537a0ce0c56548e3cc27f273a15a84995ce21dd7754d608d160e064fd9ad68e`. The PRE-FIX pair was snapshotted to `build/prefix_147cb3d6/` (gitignored) BEFORE this build, so every before/after row below is a re-run and not a memory. |

## ⚠ EVERY LINE IN THE `147cb3d6` TABLE BELOW IS **VOID** FOR `96fdd3a9`

A gate result is a fact about a BINARY (PROTOCOL). `96fdd3a9` is a different binary, so nothing from the
pre-fix table carries forward. The table is kept, relabelled `cited:` — it is still a true statement
about `147cb3d6` and about the ORACLE, and about nothing else. What was re-run on `96fdd3a9` is in the
fix-round table.

## Gate lines — FIX ROUND, all on `96fdd3a9` (`ran:`)

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| `p8` / `p8c` / `p8b` / `p9`, three binaries, `fix_r1_probes/run3.sh` (byte size printed, 0 aborts) | 96fdd3a9d2c1cd36 | ran: `p8` ORACLE **F2** · PRE-FIX `control flow inside a loop body` (**the mover**) · POST-FIX **F2** — restored. `p8c` **F2 on all three** (the isolating control, unmoved). `p8b` loop fence PRE and POST (deliberate — `%carry` is a non-φ user and its exclusion is licensed). `p9` **F1 on all three** (Track U's, untouched) | trackF-fix | 2026-09-14 |
| the new fixture PAIR, validated by MUTATION OF THE BINARY | 96fdd3a9d2c1cd36 | ran: `FileCheck` of each fixture against each binary's own stderr — PRE-FIX: phidesc **RED**, nonphidesc GREEN; POST-FIX: both GREEN. The tripwire is non-vacuous and the control is inert, which is the pair's contract | trackF-fix | 2026-09-14 |
| `lit --filter backedge` | 96fdd3a9d2c1cd36 | ran: **4 of 1932 discovered, 4 PASS** (the two new fixtures + the two pre-existing `lowering_uncompute_loop_backedge*`), 0.68 s | trackF-fix | 2026-09-14 |
| the four customers, three binaries | 96fdd3a9d2c1cd36 | ran: `owner_file_base` · `vd_base` · `w3_runtime_a_base` · `n4_cascade_base` — ORACLE **F2**, PRE-FIX **exit 0**, POST-FIX **exit 0 with the lowered IR BYTE-IDENTICAL to PRE-FIX** (md5 `9a61bf46…` / `e452f94b…` / `6833ef12…` / `bcfc14de…`, equal pre and post). `w2_base` DECLINE `control flow` on both (the pre-existing wall, unchanged). **Cost of the fix on the customers: zero, measured** | trackF-fix | 2026-09-14 |
| 4 named e2e slices, `ctest -R '^(e2e-slice-control-cascade-three-bools\|e2e-slice-control-cascade-two-bools\|e2e-slice-control-inplace-ry-stateprep-bool\|e2e-slice-control-stateprep-bool-under-int-compare-fused)$' -j4` | 96fdd3a9d2c1cd36 | ran: **100% tests passed, 0 tests failed out of 4** (3.73 s) | trackF-fix | 2026-09-14 |
| injection matrix over the new ACCEPT fixture | 96fdd3a9d2c1cd36 | ran: **12 mutations, MISSED 0, N/A 0** | trackF-fix | 2026-09-14 |
| duplicate-body scan, BOTH normalisations (F-F1-6) | 96fdd3a9d2c1cd36 | ran: 1932 fixtures — **N1 (blanks kept) 7 groups**, **N2 (blanks dropped) 9 groups**; identical at 1930 with the two new files excluded. Both new fixtures are in groups of **size 1** under all four normalisations tried | trackF-fix | 2026-09-14 |
| `ctest -R ir-pass-lit` (ONCE, pass source changed) | 96fdd3a9d2c1cd36 | ran: **Passed 162.21 sec**, 100% — 1932 fixtures | trackF-fix | 2026-09-14 |

**Why `ir-pass-lit` alone is a COMPLETE fixture-corpus gate for this particular edit** (and why no second
sweep was run): the narrowing removes members from an EXCLUSION set, so the TEST can only succeed sooner.
The only possible transitions are ACCEPT→DECLINE and DECLINE(truncated)→DECLINE(test); a DECLINE can never
become an ACCEPT. Every accept fixture is pinned green by lit and every decline fixture mirrors its string
character-for-character, so green == nothing moved.

## NOT run in the fix round, deliberately

**NO corpus sweep** — one per session, and it belongs to the merge gate. The `147cb3d6` sweep line below
stands **for that binary only** and is labelled `cited:`. Also not run, per the PROTOCOL matrix and the
fix brief: the full `ctest -j6` · `ctest -j6 -R '^e2e-'` · `cq-opt-equivalence-full` · the twin matrices.

## Instrument fix made this round

`probes/injection_matrix.py` printed `0 mutations, MISSED 0, N/A 0` — a line that **reads as a pass** —
when invoked with no fixture argument. Measured by hitting it. It now exits non-zero with a message. This
is PROTOCOL S3's "a named negative can be VACUOUS" in a runner's spelling: a runner that reports green on
an empty run.

## Gate lines — PRE-FIX ROUND, all on `147cb3d6` (`cited:` — VOID for `96fdd3a9`)

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| the 29 F2-declining fixtures, SUBJECT | 147cb3d69afd816d | cited: **still F2: 29 · MOVED: 0** | trackF-impl | 2026-09-14 |
| the 3 F2-naming ACCEPT fixtures, SUBJECT | 147cb3d69afd816d | cited: 3/3 ACCEPT | trackF-impl | 2026-09-14 |
| customers C1/C2, SUBJECT | 147cb3d69afd816d | cited: owner_file ACCEPT · vd ACCEPT (both F2 on the ORACLE) | trackF-impl | 2026-09-14 |
| customers C3'/N=4, SUBJECT | 147cb3d69afd816d | cited: w3_runtime_a ACCEPT · n4_cascade ACCEPT (both F2 on the ORACLE) | trackF-impl | 2026-09-14 |
| `lit --filter phidesc_collider_accept` | 147cb3d69afd816d | cited: **PASS** (1 of 1930) | trackF-impl | 2026-09-14 |
| `lit --filter nonphidesc_collider` | 147cb3d69afd816d | cited: **PASS** (1 of 1930) | trackF-impl | 2026-09-14 |
| `ctest -R '^e2e-slice-control-cascade-three-bools$'` | 147cb3d69afd816d | cited: **Passed 5.16 sec** | trackF-impl | 2026-09-14 |
| the 3 named must-not-move e2e slices | 147cb3d69afd816d | cited: **100% tests passed, 0 failed out of 3** | trackF-impl | 2026-09-14 |
| injection matrix over the new accept | 147cb3d69afd816d | cited: **12 mutations, MISSED 0, N/A 0** | trackF-impl | 2026-09-14 |
| duplicate-body fixture scan (L8) | 147cb3d69afd816d | cited: 1930 fixtures, 9 duplicate-body groups — **all pre-existing, none is a new fixture** | trackF-impl | 2026-09-14 |
| corpus sweep ORACLE-vs-SUBJECT | 147cb3d69afd816d | cited: **2086 modules, 7 mover(s), 0 unattributable** — 5 `F2 -> ACCEPT` (the new accept fixture + owner/vd/w3_runtime_a/n4_cascade) and 2 `F2 -> control flow` (w2_base, w2_testW — the pre-existing wall, still a DECLINE). `probes/corpus_147cb3d69afd816d.txt` | trackF-impl | 2026-09-14 |
| `ctest -R ir-pass-lit` (ONCE at hand-off) | 147cb3d69afd816d | cited: **Passed 217.94 sec**, 100% — 1930 fixtures (duration load-inflated, see below) | trackF-impl | 2026-09-14 |

## NOT run, deliberately (PROTOCOL matrix — the implementer runs none of these)

full `ctest -j6` · `ctest -j6 -R '^e2e-'` · `cq-opt-equivalence-full` · the twin matrices.
They belong to the merge-and-gate agent for this merge GROUP (Track F + Track P).

## ⚠ TIMINGS HERE ARE LOAD-INFLATED AND ARE NOT COMPARABLE

MEASURED at 11:22 while my own sweep was running: another worktree
(`/Users/sorenwilkening/Desktop/CQ_twinbool`) was running `tools/loop_twin_matrix.py`
on this box, forking its own `cq-opt` children. `CLAUDE.md` Build & Test: under
concurrent agent load figures are "not comparable ... only ever compare two runs
taken under the same load". So `ir-pass-lit`'s 217.94 s (against a quiet-box
60-105 s) and the corpus sweep's wall time are LOAD artefacts, not regressions.
Contention causes false FAILURES, never false passes — both gates PASSED, so
neither verdict is in doubt; only the durations are.

⚠ **THE FIX ROUND'S `ir-pass-lit` (162.21 s) IS LOAD-INFLATED TOO, AND FOR THE SAME REASON.** Measured
at 11:48 immediately before it: `load averages: 6,78 15,46 96,97` with **4 foreign `cq-opt` processes**
running from another agent's worktree. 162 s against a quiet-box 60–105 s is that, not a regression, and
it is **not** comparable with the pre-fix round's 217.94 s either — different load, different run.
Verdict PASSED, which is the part that is a fact; the duration is not.

⚠ **No binary was relinked under a running measurement** (`CLAUDE.md` Build & Test): the fix build
finished before any gate in the fix table started, and the PRE-FIX pair was snapshotted to
`build/prefix_147cb3d6/` first precisely so no gate would have to re-derive the old binary later.

## Builds (ROUND-2 DOC/FIXTURE round — COMMENTS, FIXTURES AND PROBES ONLY)

| # | what | `build/ir-pass/cq-opt` sha256 | note |
|---|---|---|---|
| B4 | `cmake --build build -j8` (BOTH targets) after the F-F2-1 L1 rewrite + the `SwapRouteEmit` pointer + the F-F2-2 trigger split | `96fdd3a9d2c1cd36deb607f0440db0157280a7784a7766bdce04044cd3234cd1` — **BIT-IDENTICAL to B3** | `libCQPass.so` `9537a0ce0c56548e3cc27f273a15a84995ce21dd7754d608d160e064fd9ad68e`, also bit-identical. The build log shows `ArmClassify.cpp.o` and `SwapRouteEmit.cpp.o` recompiled for BOTH targets, so this is a measurement and not a no-op build |
| B5 | `cmake --build build -j8` after the line-rewrap pass (comments only) | `96fdd3a9d2c1cd36…` — **BIT-IDENTICAL again** | same for `libCQPass.so` |

**Consequence, stated so nobody re-runs anything for the wrong reason:** no predicate changed and the
binary did not move, so **every gate line in the B3 table above remains a fact about the binary on
disk** and is cited, not re-run. The only layer that can witness this round's edits is the fixture
corpus.

## Gate lines — ROUND-2 DOC/FIXTURE round, all on `96fdd3a9` (`ran:` unless marked)

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| the six round-2 probes, three binaries each, byte size printed first (none 0 B) | 96fdd3a9d2c1cd36 | ran: `r5` **ORACLE D-F2 / PRE-FIX exit 0 / SUBJECT exit 0**; `r5c` **D-F2 on all three**; `r6` **D-F2 / exit 0 / exit 0**; `r7` **D-F2 on all three**; `r12` **D-F2 on all three**; `r20` **ORACLE D-F2 / PRE-FIX `cq taint escape: tainted value muxed by a classical-condition phi` / SUBJECT D-F2 — A MOVER, on an ACYCLIC module** | trackF-fix-r2 | 2026-09-14 |
| the four peel probes (`r10`,`r10c`,`r11`,`r11c`), three binaries each | 96fdd3a9d2c1cd36 | ran: each probe gives the SAME verdict on all three binaries; **none is a mover and none accepts** (`r10` stale-rail-record, `r10c` 2c, `r11`/`r11c` F2) | trackF-fix-r2 | 2026-09-14 |
| `CQ_CTRL_DBG=1` attribution of the round-2 decline | 96fdd3a9d2c1cd36 | ran: `r5c` -> `decline [state prep seed is proven equal to the condition register] at:   %c2 = icmp eq i32 %out1, 13` — the operand is the ROUND-1-EMITTED out-rail, so the F2 call is the round-2 one | trackF-fix-r2 | 2026-09-14 |
| every file:line the new comments cite, verified BY READING (Rule 11) | n/a (source + LLVM headers) | ran: `ArmClassify.cpp:823` · `SwapRouteEmit.cpp:752-758`,`:917`,`:930`,`:948`,`:1105`,`:536`,`:1295`,`:1534` · `RegionFlatten.cpp:176` · `SelectMergeEmit.cpp:386`(+`:329`) · `SwitchValueEmit.cpp:376`(+`:291`) · `SwitchDataMuxEmit.cpp:230`(+`:142`,`:112`) · `MergePhiPeel.cpp:559` · LLVM 19 `GenericDomTree.h:937-947` -> `:430-442`. **One correction made to the drafted text:** the DataMux alloc takes a `ConstantInt` operand, so the row is "only operand is a CONSTANT", not "no operands" | trackF-fix-r2 | 2026-09-14 |
| the six new fixtures, direct `cq-opt` + `FileCheck` per prefix | 96fdd3a9d2c1cd36 | ran: 4 declines **OK (declines, checks match)**; 2 accepts **MAIN/RYCNT/FCNT/ACNT/XCNT/MCNT/NEG all OK** | trackF-fix-r2 | 2026-09-14 |
| injection (mutation) matrix over the two NEW ACCEPT fixtures | 96fdd3a9d2c1cd36 | ran: FIRST **24 mutations, MISSED 8, N/A 2** — a REAL DEFECT IN THE NEW FIXTURE (`…_mbeta_base_oncone_accept.ll`'s CHECK-NEXT chain started at the prep, so pre-prep injections were outside every window). After adding ACNT/XCNT/MCNT/NEG and starting the chain at the first alloc: **24 mutations, MISSED 0, N/A 2**, both `n/a-shape` | trackF-fix-r2 | 2026-09-14 |
| injection matrix re-run on the ROUND-1 accept fixture, to prove the instrument generalisation did not weaken it | 96fdd3a9d2c1cd36 | ran: **12 mutations, MISSED 0, N/A 0** (was 12/0/0 — unchanged) | trackF-fix-r2 | 2026-09-14 |
| duplicate-body scan, FOUR normalisations (F-F2-3) | 96fdd3a9d2c1cd36 | ran: **1938 fixtures — lstrip/KEPT 7, lstrip/DROPPED 9, col0/KEPT 6, col0/DROPPED 8.** All three numbers on record (7/8/9) RECONCILE — **F-F2-3 SETTLED**. Counts unchanged from the reviewer's 1932-file run; targeted check: **collisions involving the 6 new fixtures: 0** under all four | trackF-fix-r2 | 2026-09-14 |
| `lit --filter 'stateprep_(mbeta\|round2\|acyclic\|backedge\|phidesc\|nonphidesc)'` | 96fdd3a9d2c1cd36 | ran: **10 of 1938 discovered, 10 PASS**, 0.66 s (run twice — before and after the prefix strengthening) | trackF-fix-r2 | 2026-09-14 |
| `ctest -R ir-pass-lit` — run TWICE this round because the tree changed after the first (fixtures gained RUN lines) | 96fdd3a9d2c1cd36 | ran: **Passed 76.62 sec** (6 fixtures added) and **Passed 50.58 sec** (final tree). `lit ir-pass/test`: **1938 discovered, 1937 Passed, 1 Expectedly Failed** | trackF-fix-r2 | 2026-09-14 |

## NOT run in the round-2 doc round, and WHY it is sound not to

No corpus sweep (one per session, the merge gate's) · no full `ctest -j6` · no `ctest -R '^e2e-'` ·
no `cq-opt-equivalence-full` · no twin matrix · no e2e slice. **The justification is the bit-identity
above**, not a budget: no predicate changed and the binary did not move, so every one of those layers
would be re-answering a question about a binary that is byte-for-byte the one they already answered it
about. The fixture corpus is the only layer whose input changed, and it was run to green.

## Instrument fix made this round

`probes/injection_matrix.py` M9/M10 were spelled for the i1 bool fixture (`icmp_sgt_i32_hl_unc`,
`cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h6`) and read **N/A — i.e. HOLE** on every i32 accept fixture.
Made width-generic via a new `mut_resub()`; M11 (the negated-rail cancelling Ry) is now declared
`SHAPE_SPECIFIC` and prints `n/a-shape`, so a genuine harness hole can no longer hide behind a benign
inapplicability. This is PROTOCOL S3's "a mutator reading N/A is a hole" — the same class as the
round-1 fix's empty-argv defect, in the same file, found the same way (by hitting it).

---

# APPENDED AT THE MERGE GATE (2026-09-14): Track F's SCOPING GATES.md

> Merge note: Track F branched from `607b6fe4`, before the orchestrator's scaffolding commit `28eac7d2` added the SCOPING agent's `trackF/GATES.md` at the same path. The two files record DIFFERENT gates on the SAME (ORACLE) binary and neither supersedes the other, so the merge-and-gate agent resolved the add/add by UNION, implementation first. No gate line was edited.


Format (PROTOCOL.md): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
Track F runs **no build and no suite** (PROTOCOL matrix, row "scoping"). Its only gate is the
per-probe pipeline on the frozen ORACLE.

ORACLE verified before first use:
```
shasum -a 256 build/ir-pass/cq-opt        f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  == BRIEF
shasum -a 256 build/ir-pass/libCQPass.so  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  == BRIEF
```

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| oracle hash check | f7b65d8ccd7bc472 | both hashes == BRIEF | trackF-scope | 2026-09-14 |
| per-probe pipeline, F2 corpus baseline (32 fixtures naming the string) | f7b65d8ccd7bc472 | 29 DECLINE F2 · 3 ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, TEST S (seed -> wild) x 26 valid | f7b65d8ccd7bc472 | 22 ACCEPT (PIN) · 4 F2 (TRUNCATED) | trackF-scope | 2026-09-14 |
| per-probe pipeline, TEST A (seed -> other-edge value) x 11 valid (1 mis-substitution repaired as A2) | f7b65d8ccd7bc472 | 10 F2 · 1 ACCEPT (fcmp_oeq_derived) | trackF-scope | 2026-09-14 |
| per-probe pipeline, TEST B (collider neutralised) x 25 (1 repaired as B2) | f7b65d8ccd7bc472 | 25 ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, TEST W (move the pinning edge's fact) x 19 (16 fixtures + 3 customers) | f7b65d8ccd7bc472 | 19 ACCEPT => ONE-EDGE, 0 exceptions | trackF-scope | 2026-09-14 |
| per-probe pipeline, BOTH-EDGE positive controls C1/C2 + their W | f7b65d8ccd7bc472 | 4 F2 (W does NOT flip them) — the instrument discriminates | trackF-scope | 2026-09-14 |
| per-probe pipeline, RIVAL audit x 25 | f7b65d8ccd7bc472 | 20 `control flow` (R3) · 5 `state prep merged with a quantum register` (F1) · 0 ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, BOTHSLOT in-place reading x 20 | f7b65d8ccd7bc472 | 18 R6 · 2 R4 · 0 ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, R3 isolation pair (off-wire base) | f7b65d8ccd7bc472 | literal pred slot -> `control flow`; register pred slot -> ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, customers (owner file / vd.c / w2.c) | f7b65d8ccd7bc472 | 3 DECLINE F2; TEST W on each -> ACCEPT; sole-collider S1 -> ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, C probes be1/be2 (is a both-edge pin reachable from C?) | f7b65d8ccd7bc472 | 2 ACCEPT — `-O1` deleted the collider in both | trackF-scope | 2026-09-14 |
| per-probe pipeline, HOLE-1 quartet (fp anchor) | f7b65d8ccd7bc472 | subject F2 · its TEST-W twin **still F2** · BOTHSLOT_nomeasure **ACCEPT exit 0** | trackF-scope | 2026-09-14 |
| mechanical: does any fixture collider descend from the region's merge phi? | f7b65d8ccd7bc472 | 32/32 NO (all three customers: YES) | trackF-scope | 2026-09-14 |

Probe files: `trackF/probes/` (147 .ll modules + 5 .c + 3 generator scripts + run1.sh).
Generators are re-runnable and re-check nothing about the tree: `gen_pin.py`, `gen_pin2.py`, `gen_rival.py`.
