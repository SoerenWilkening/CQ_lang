# MERGE_R1_1 — `rb9x-f2-clones` × `main` 9361826, landing 2 (Track R increment R-1, bd `rb9x`)

Merge-and-gate record, 2026-09-13. Worktree `/Users/sorenwilkening/Desktop/CQ_rb9x`, branch
`rb9x-f2-clones` from `main` **81956a2**, merged with **`main` 9361826** (= landing 1's squash
`23b0cd1`, Track C bd `21mg` + Track L's L-0 H-10 pins, plus the docs-only commit that added my own
merge brief). Review verdict **CLEAR-WITH-ITEMS** (`review_R1_r1.md`, 5 items, none a miscompile,
none an over-accept). Committed on the branch, **not pushed**; the squash is the orchestrator's.
Instance of `../MERGE_BRIEF_TEMPLATE.md` + `MERGE_BRIEF_R1.md`.

**The last commit carrying CODE, FIXTURES or GOLDENS is `44dc7d9`**, and every gate below was run on
the tree at that commit; the branch tip is the docs-only commit that adds THIS record and its
corpora on top of it (`git log --oneline -1` in the worktree is the hash the squash message should
cite). Four commits, in order:

```
<tip>   docs(rb9x): merge-and-gate record MERGE_R1_1.md + GATES.md lines + the merged-binary corpora
44dc7d9 docs(rb9x): review items R1r1-1 and R1r1-3 (comment-only)   <- the gated tree
24063e7 Merge branch 'main' into rb9x-f2-clones
3b0251a wip(rb9x): R-1 + records            (git status --porcelain | wc -l = 23 before it)
```

Three binaries:

| label | `cq-opt` sha256 (16) | `libCQPass.so` (16) | what it is |
|---|---|---|---|
| ORACLE | `fbbe0820ef4b176a` | `40e9c7a51e8120bb` | `/Users/sorenwilkening/Desktop/CQ_lang/build`, e96f89c — **re-hashed before first use, matches PROTOCOL.md**, never built, never written |
| SUBJECT (pre-merge) | `221c1caa465db61e` | `818becd47c9a0650` | the implementer's build, `GATES.md` |
| **MERGED** | **`2563baa4125bfd5f`** | **`885b8e119207b3c2`** | this tree after the merge + the two comment-only review items + reconfigure + `cmake --build build -j8` (BOTH targets, 53.8 s) |

The MERGED hash is NEW — it carries landing 1's `MeasureLowering` source as well as R-1's — so
**nothing was citable**: every gate below was RUN on `2563baa4125bfd5f`.

---

## §0 FINDINGS

**ONE, and like landing 1's it is a finding about an INSTRUMENT, not about the compiler.**

**F-R1 — the corpus recipe renders the whole `cq_measure_<sfx>` diagnostic family as an EMPTY
`D:`, so a DECLINE→DECLINE string change inside that family is INVISIBLE to the sweep — not merely
unnamed.** The shared recipe (`review_integration_probes/corpus.sh`, inherited verbatim by this
track's `probes/impl/corpus.sh` and by my `probes/merge/corpus_merge.sh`) tags a decline with

```
grep -oE 'cq [a-z0-9 ]+: [^"]+' … | cut -c1-80
```

which requires a literal `cq ` + space and therefore matches **nothing** in
`cq_measure_<sfx> operand not recognized; …`. Landing 1's `corpusC.sh:11-17` already documents the
lossiness and grades it *"Mover DETECTION is unaffected either way (D: vs A:md5 still differs); only
the NAMING was lossy"*. **That grading is correct for D→A and FALSE for D→D**: two different
diagnostics in the lossy family both render `D:`, compare equal, and the row drops out of the mover
set with no trace. Over my corpus, **107 rows carry an empty `D:` on at least one side and 84 of
them read `D:`/`D:` on both** — i.e. 84 rows the string comparison could not see through.

Closed, not noted: `probes/merge/decline_stderr_delta.sh` re-runs BOTH binaries over **every row
either side declined (1537)** and byte-compares the FULL stderr plus the exit code. Result: **38
rows differ, of which 35 are the visible movers and 3 were invisible** — all three landing 1's
declared new `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a
defined value` (`trackC/probes/c6_undef_bool.c`, `trackC/probes/i0_poison_operand.ll`,
`ir-pass/test/lowering_reject_measure_undef_operand.ll`), each still a loud `DS_Error` at exit 1.
**No row moved on any R-1 string that the string sweep had hidden.** The 35 + 3 arithmetic closing
exactly against the 35 movers of §3 is the cross-check that the delta instrument itself is sound.

⚠ One parallelism artefact of my own, reported because it changes how the raw file reads (Rule 19):
`decline_stderr_delta.sh` runs `-P6` and writes the `### <rel>` header and the diff body as two
separate appends, so **two rows' output can interleave** — `i0_poison_operand.ll`'s diff body landed
inside a neighbour's block. Each of the 3 invisible rows was therefore **re-run SERIALLY** (table
above) before being named. The parallel file is the detector; the serial re-run is the evidence.

The four questions that could have produced a compiler finding, each answered by measurement:

1. **Did the merge move anything?** No `ir-pass/src` conflict existed to mis-resolve (§1), and the
   two review items are mechanically comment-only: `git diff -U0 | …` over the item-A commit yields
   **0 added or removed lines that are not `;`/`//` comments**.
2. **Did anything the ORACLE accepts stop compiling?** **0** ACCEPT→DECLINE over 3051 rows (§3).
3. **Did any program both binaries accept get a DIFFERENT circuit?** **0** md5 differences over the
   1513 ORACLE accepts (§3).
4. **Is every new accept Rule-6 clean?** All **33** accepting movers re-lowered through STRICT
   stage 2b: `0 violation(s), 0 unproven`, 33/33 (`probes/merge/stage2b_movers_2563baa4.txt`).

---

## §1 CONFLICTS — zero, and the brief's predicted one did not materialise

```
$ git -C /Users/sorenwilkening/Desktop/CQ_rb9x status --porcelain | wc -l   # before
      23
$ git add -A && git commit -m "wip(rb9x): R-1 + records"      -> 3b0251a
$ git merge main                                              -> 24063e7, NO conflict
$ git status --porcelain                                      -> (empty)
```

`MERGE_BRIEF_R1.md` predicted an **add/add conflict in `tests/e2e/CMakeLists.txt`** (both sides
appended registrations) and a possible one in `trackR/GATES.md`. **Neither fired**, and the reason
is worth recording rather than celebrating: the two sides appended at **different anchors**, so git's
three-way merge saw disjoint hunks. R-1 registers its slice at line **4845**, immediately after the
last `slice_control_inplace_ry_*` group; landing 1's seven entries are at **5211/5227** (Track L's
carried-theta pins, after `e2e-phase-bool-loop-twin-identical`) and **5490/5511** (the 21mg measure
slices, at the end). In `GATES.md`, main inserted one scoping row at line 6 and the branch appended
its implementation rows at the bottom.

**A clean auto-merge is not evidence that the result is the UNION, so the union was checked three
ways** (this is the step the brief's "resolve by KEEPING BOTH blocks in order" exists to guarantee):

| check | result |
|---|---|
| `git diff 9361826 HEAD -- tests/e2e/CMakeLists.txt` | ONE hunk, `@@ -4829,6 +4829,27 @@`, adding only `e2e-slice-control-stateprep-bool-under-int-compare-fused` |
| `git diff 3b0251a HEAD -- tests/e2e/CMakeLists.txt` | TWO hunks, adding only landing 1's seven entries |
| `grep -c '^add_test'` at base / branch / main / merged | **393 / 394 / 400 / 401** — 393+1+7 = 401 exactly |

Also verified by reading: the `get_property(_E2E_ALL_TESTS DIRECTORY PROPERTY TESTS)` +
`set_tests_properties(...)` sweep is still the **LAST** statement in the file (its own comment says
it must be, or the `CQ_PYTHON`/`CQ_LD`/`CQ_S1CACHE` environment would not reach every test — a
merge that appended after it would have been green here and wrong in CI-less ways).

`GATES.md` is the union in order: the two scoping rows, then main's R-2 rival-audit row, then the
scoping "not run by this agent" block, then the eleven implementation rows, then this landing's.

**No `ir-pass/src` conflict appeared, as the brief expected** — the two tracks are disjoint by file
(`C`: `MeasureLowering.{h,cpp}`; `R`: `TaintPropagation.h`, `MergePhiPeel.cpp`, `ArmClassify.cpp`).
`git diff --name-status 9361826 HEAD` outside `docs/` is exactly R-1's 16 paths and nothing else.

### The two review items (step 8, applied BEFORE the full suite)

* **R1r1-1** — `control_peel_reject_stateprep_two_region_foreign_clone.ll`: the `35t0` retirement
  trigger KEEPS *"the day bd `35t0` is closed THIS FILE BECOMES AN ACCEPT"* and now explicitly
  **refuses** the reading that the preimage-vs-wire distinction becomes load-bearing for soundness
  that day (L6: a structural guard read as a semantic one — this file must not be quoted as a reason
  to block the `35t0` widening). The reviewer's **second, independent argument** is written beside
  the preimage one, not instead of it: a foreign clone's ORIGINAL is tainted, is a user of the same
  operands, and folds identically (`f2Refine` passes `CxtI = nullptr` at all four call sites, so it
  is position-insensitive) — hence either the original still collides and F2 declines with or
  without R-1, or the original is in `CondWire` and the value is already blessed on that very edge.
  The same paragraph is added to `TaintPropagation.h`'s preimage block, which is where the review
  asked for it. The "UNREACHABLE AT HEAD" paragraph is corrected to say what `td2_pad.ll` /
  `td3_valueB.ll` measure: `sequentialChainAlias` is consulted only when two regions ALIAS blocks, so
  a PADDED two-diamond composition is reachable past `reorderable()` (and accepts byte-identically on
  both binaries) — it is simply not an F2 instance.
* **R1r1-3** — `control_peel_stateprep_datamux_peeled_control.ll`: the `CPCNT`/`UCNT` counts are
  RELABELLED and neither the number nor the prefix is touched. Measured on the lowered IR:
  `@cqrt_copy_` occurs 3× = **2 calls + 1 `declare`**, `_unc(` occurs 3× = **2 calls + 1 `declare`**.
  The `-NOT` halves are still live (a 4th trips, a 2nd fails the COUNT); the comment now says so and
  points a new fixture at the call-qualified spelling R-1's own accepts use.

---

## §2 RESURRECTIONS — the trigger did not fire; the scan was run anyway and is clean

`git diff --name-status -M` over `ir-pass/test` + `tests/e2e`, base→main and base→merged: **0
renames on either side**, so the bd memory `merge-resurrects-git-mv-fixture` trigger is inapplicable.
Run regardless, because a clean scan is only worth its baseline:

```
$ python3 <sha-256 over each ir-pass/test/*.ll's NON-COMMENT lines>
files=1908  same-body groups=9
```

**All 9 groups are the ones `MERGE_C_1.md` §2 enumerated** — the eight deliberate
same-module/different-prefix pairs plus landing 1's declared
`lowering_measure_round2_sixfive_handle.ll` / `control_classical_call_arm_accept.ll` pair. **R-1's
seven new fixtures create no group**, i.e. no two of them share a body and none duplicates a shipped
module. Nothing to dispose of.

---

## §3 CORPORA — 3051 rows RUN on the merged binary, 38 movers, every one explained

`probes/merge/corpus_merge.sh` → `probes/merge/corpus_2563baa4.txt`. Corpora = the template's step 5
(`ir-pass/test/*.ll` 1908, `$SES/probes`, every `$SES/track*/probes` **recursively**, so
`probes/impl` and `probes/r2` are included, and the seven 2026-09-11 session dirs' `probes/` +
`review_*_probes/`) **plus item C's additions** (`trackR/review_R1_r1_probes`, `trackC/probes`,
`trackC/review_C_r1_probes`, `trackL/probes`). Row = `<rel>|<oracle>|<merged>`, verdict `A:<md5-8 of
the lowered IR>` or `D:<diagnostic>`, both binaries on the SAME stage-1 file. `-P6`; each row has its
own `mktemp -d`, and the body is sorted before it is written.

```
# corpus: 3062 files | oracle=fbbe0820ef4b176a merged=2563baa4125bfd5f
rows=3051   oracle_accepts=1513   merged_accepts=1546   movers=35 (+3 invisible, §0) = 38
ACCEPT -> DECLINE                                  = 0
both-accept rows with a DIFFERENT lowered IR       = 0
```

**The two zeros are the statement to read first**: not one module the ORACLE accepts stopped
compiling, and not one module both binaries accept emits a different circuit. Both tracks are
accept-monotone by construction (R-1 only REMOVES a collider from F2; 21mg only adds a classical
disposition to an operand class that previously declined), and the sweep measures that the
construction holds over 3051 modules.

### The 38 movers, by string

| # | ORACLE | MERGED | owner |
|---|---|---|---|
| **10** | `D: state prep seed is proven equal to the condition register` | **ACCEPT** | **R-1** (this landing) |
| **2** | same F2 string | a DIFFERENT, LATER DECLINE | **R-1** — F2 was in front of a second fence |
| **23** | `D: cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` | **ACCEPT** | landing 1 (21mg) |
| **3** | same 21mg string | `D: cq_measure_<sfx> operand is an undef/poison literal; …` | landing 1 (declared new string) |

The **10 R-1 accepts** are exactly the implementer's 10 (`corpus_221c1caa.txt`), unchanged by the
merge: the two new fixtures `control_peel_stateprep_bool_seed_{int_cond,true}.ll`; `b_A`/`b_P2`/`b_P2t`
and their three 2026-09-11 duplicates `A_intb0_boolb1`/`P2_intcmp_i1seed_peeled`/`P2t_seed_true_peeled`
(IMPL §7.8: 12 movers = 9 distinct programs; here 10 = **7 distinct**); plus the two the corpus found
and the scope did not — `O3_mux_quantum_incomings.c` and `R1_p80_bool.c`, the **round-2** peel.
The **2 later declines** are `R2_p80_window.c` → `control flow` and `R4_p80_measured.c` →
`condition measured before the control route` — both still loud, both exit 1, both predicted by the
brief. The **23 + 3** are landing 1's, whose ORACLE string I verified individually by re-running the
ORACLE serially on each (all 23 print `cq_measure_<sfx> operand not recognized; …`).

**Every accepting mover re-lowered through STRICT stage 2b on the merged binary** —
`probes/merge/stage2b_movers_2563baa4.txt`, 33 rows, **0 violation(s), 0 unproven, 33/33**. The
`rb9x` family reads `5 rail mint(s) of which 5 left allocated, 2 cqrt_free site(s): 2 verified`
(Rule 6: `Ry(.5)|0⟩ ≠ |0⟩`, so the prepped rail and the mux rails are LEFT ALLOCATED, never freed);
`R1_p80_bool` reads 8/8/3; the purely-classical 21mg rows read `0 rail mint(s) … 0 cqrt_free` — the
measure sink minting nothing at all, which is the property that landing's whole argument turns on.

---

## §4 CUSTOMERS on the MERGED binary — 3 accept byte-identically, 2 decline as scoped

Four-stage pipeline per PROTOCOL.md (`clang -O1 -g` → `cq-opt` → `free_pairing_check.py` → link →
run), all on `2563baa4125bfd5f`.

| customer | verdict | trace | against |
|---|---|---|---|
| `trackR/probes/b_A_intb0_boolb1.c` — **bd `rb9x`'s own program** | ACCEPT, exit 0, STRICT 2b `2 verified, 0 violation(s), 0 unproven` | **22 lines** | **BYTE-IDENTICAL** to the committed golden `tests/e2e/slice_control_stateprep_bool_under_int_compare_fused.expected.log` |
| `$SES/probes/va.c` | ACCEPT, STRICT 2b `1 verified, 0/0` | **19 lines** | **BYTE-IDENTICAL** to `$SES/probes/va.trace` |
| `trackC/probes/owner_2026-09-11_2218.c` (landing 1's customer) | ACCEPT, STRICT 2b `1 verified, 0/0` | **15 lines** | **BYTE-IDENTICAL** to `tests/e2e/slice_measure_classical_bool.expected.log` |
| `$SES/probes/owner_file_2026-09-13.c` | **DECLINE** `cq controlled lowering: control flow under quantum control`, exit 1 | — | as expected — Track M's target, not built |
| `$SES/probes/vd.c` (and `trackR/probes/v_vd.c`) | **DECLINE** `state prep seed is proven equal to the condition register`, exit 1 | — | as expected — R-2 not folded in (IMPL §7.6) |

The b_A identity is the increment's cleanest statement: the probe and the harness slice are the same
program in two shapes and produce the same 22 lines, so the golden the suite now pins is the one the
bd's own reproducer emits.

---

## §5 GATES, verbatim

```
build (cmake --build build -j8, BOTH targets, after the merge + items A)
  cq-opt 2563baa4125bfd5f08a88ace5956a037ca8ff5024e5c40b90f5f194d4f9df8ae
  libCQPass.so 885b8e119207b3c24069cea2eeec68c5d409e5894ba0bfd9e7ab306053ac769e
  53.838 s wall; 2 pre-existing -Wunused-parameter warnings, no new one

FULL ctest --test-dir build -j6 --output-on-failure      (ONCE, this landing's only full run)
  100% tests passed, 0 tests failed out of 411
  Total Test time (real) = 417.79 sec     [wall 6:57.85; the box also carried one other
                                           worktree's light lit/slice jobs]
  ir-pass-lit Passed 68.49 sec · frontend-lit Passed 5.07 sec ·
  e2e-loop-twin-matrix Passed 231.52 sec (the long pole, as CLAUDE.md says) ·
  e2e-free-pairing-selftest Passed · e2e-census-slice-sync Passed
  NO failure, so nothing had to be re-run serially.

cmake --build build --target cq-opt-equivalence-full     (OWED: an analysis site changed)
  cq_opt_equivalence: compared 1908 fixtures, 0 mismatch(es)      93.82 s

corpus sweep ORACLE-vs-MERGED       rows=3051, movers=35 visible (+3 invisible, §0) = 38;
                                    0 ACCEPT->DECLINE; 0 both-accept md5 differences
decline-side full-stderr delta      1537 rows, 38 differ, 3 invisible to the string recipe
stage 2b over the 33 accepting movers   0 violation(s), 0 unproven, 33/33
duplicate-body fixture scan         files=1908, same-body groups=9, 0 merge artefacts
```

---

## §6 COUNTS, by command

| command | e96f89c | after landing 1 | **merged (landing 2)** |
|---|---|---|---|
| `ls ir-pass/test/*.ll \| wc -l` | 1893 | 1901 | **1908** (+7: R-1's 2 accepts + 5 declines) |
| `ls tests/e2e/*.expected.log \| wc -l` | 355 | 360 | **361** (+1) |
| `ctest --test-dir build -N \| tail -1` | 403 | 410 | **411** (+1) |
| `ctest -N -R '^e2e-'` | 393 | 400 | **401** |
| `ctest -N -R '^e2e-slice-'` | 353 | 358 | **359** |
| `ctest -N -R twin-identical` | 30 | 32 | **32** (unchanged — R-1 ships no twin gate, by design: the `int` twin differs by a stated width reduction, so byte-identity would be a false assertion) |
| `grep -c '^add_test' tests/e2e/CMakeLists.txt` | — | 400 | **401** |
| twin matrix cells (`grep -c '^m_'` + `grep -c '^cell '`) | 288 | 288 | **259 + 29 = 288** |
| `cq-opt-equivalence-full` | 1893/0 | 1901/0 | **1908/0** |

---

## §7 WHAT I DID NOT DO

* **No squash, no push, no bd write.** The squash message is the orchestrator's; the gated tree is
  **`44dc7d9`** and the tip to cite is this record's own commit on top of it.
* **Nothing outside this worktree was written.** The ORACLE checkout was only ever *read* (its two
  binaries re-hashed before first use, then executed); it was never built and never written.
* **No second full suite**, and no full suite before the merge — PROTOCOL.md's merge-and-gate row
  allows exactly one, and it ran on the MERGED tree so it covers both landings' code together.
* **No injection matrix** (implementation row; `fixtures=2 mutations=10 MISSED=0 DIRTY=0 @ 221c1caa`
  is the implementer's and is a fact about the PRE-merge binary — *not* re-run and *not* cited as a
  fact about `2563baa4`, because the hash moved. The new-accept fixtures are covered on the merged
  binary by `ir-pass-lit` inside the full run, and their streams' md5s are in the corpus).
* **No twin-matrix run of my own** — `e2e-loop-twin-matrix` ran inside the full suite (231.52 s,
  Passed), which is the only instrument that can see a leaked TEMPLATE-minted rail.
* **I did not re-open the review's items 2/5/9 or re-derive its verdict.** Items R1r1-2 (the `zext`
  of a peeled select — an OVER-DECLINE with no bd) and R1r1-5 (three pre-existing over-declines) are
  **not filed**: an implementation/merge worktree does not open issues. They belong to the
  orchestrator's session close, and R1r1-2 in particular is the one the owner's 2026-09-11 ruling
  turns into a defect to track rather than a safety margin.
* **The two unmeasured cells the review names remain unmeasured** (a peeled `i1` SELECT as the
  deciding collider; the §3b hazard as an actual F2 instance rather than as the dominance argument).
  Nothing in this landing changed them, and neither is an over-accept direction.
