# MERGE 2 — `main` 3a3a2b9 (Track A.1 + bd `b6ap`) into `f2-condwire-narrowing`

**Merge record, SECOND pass.** Worktree `/Users/sorenwilkening/Desktop/CQ_f2`,
branch `f2-condwire-narrowing`, from **6d06e51** (merge 1 + its record). Merge
commit **8e1de9a**. Not pushed; the squash is the orchestrator's (LANDING_PLAN
step 3). This pass runs the FULL gate set that merge 1 deliberately deferred
(§6 of `MERGE_f2_1.md`): the full `ctest -j6` and `cq-opt-equivalence-full`.

Nothing under `/Users/sorenwilkening/Desktop/CQ_lang/`, `/CQ_b6ap/`,
`/CQ_trackA/` or `/CQ_l4x4/` was written. Their `build/ir-pass/cq-opt` binaries
were used **read-only** as reference revisions and each was identified by symbol
before use (§4).

---

## §0 FINDINGS

**NONE.** No probe verdict moved across this merge on any of the eight corpora
re-run (481 rows, §4). On A.1's and b6ap's corpora (359 rows) the merged binary
is verdict-identical to the **pre-merge `main` side**, row for row. The only
rows where the merged binary differs from `main` are F2's own **14** documented
narrowing movers, all inside F2's two corpora.

Two things are **reported here rather than filed**, because neither is a mover:

* **R-1 (an ATTRIBUTED mover vs the pre-merge F2 side, not a finding).**
  `probes/V0.c` — the owner's `grover_oracle_uncompute.c` verbatim — was
  `control flow` on the F2 side at merge 1 (`MERGE_f2_1.md` §4.1) and is
  **`bare i1 register condition`** here. `main` 3a3a2b9 gives the identical
  string, so the move belongs to **b6ap's peel**, and b6ap's own landing message
  predicts it in those words ("as written it now stops at `bare i1 register
  condition` (l4x4.b, next)"). F2 is unchanged underneath it.
* **R-2 (a DEPARTURE from this pass's stated expectation, measured, not a
  merge effect).** The orchestrator expected the `int b0` / `bool b1` spelling
  of the owner's file to "pass F2 and compile, or stop at the prep arm". It does
  **neither**: it stops **at F2**, `state prep seed is proven equal to the
  condition register` — **byte-identically on `main` 3a3a2b9**, i.e. F2's
  narrowing neither helps nor hurts it. The ground is the drbq Inc-4 `i1`-width
  residual, not this merge; see §5.

---

## §1 CONFLICTS

**NONE — `git merge main` applied cleanly (exit 0, no `UU`/`AA` paths).**

Conflict-free is not interaction-free, so every file either side touched was
checked by hand rather than trusted to the three-way merge.

### 1a. The two sides' pass-source sets are DISJOINT

F2's own delta (`git diff --name-status 0c7380c 1419b5e -- ir-pass/src
ir-pass/include tools tests/e2e/CMakeLists.txt`) is exactly **two** files:

```
M  ir-pass/src/ArmClassify.cpp
M  tests/e2e/CMakeLists.txt
```

b6ap's delta (`git diff --name-status 7203d1c 3a3a2b9`, excluding its record and
`ir-pass/test`) is:

```
M  ir-pass/CMakeLists.txt          A  ir-pass/include/MergePhiPeel.h
M  ir-pass/include/PredMuxFlatten.h   M  ir-pass/src/PredMuxFlatten.cpp
M  ir-pass/include/TaintPropagation.h M  ir-pass/src/TaintPropagation.cpp
M  ir-pass/src/CQLoweringPass.cpp     A  ir-pass/src/MergePhiPeel.cpp
M  tests/e2e/CMakeLists.txt           M  tools/loop_twin_matrix.expected.txt
+ 2 new slices and their goldens
```

`ArmClassify.cpp` is **not** in b6ap's set, so F2's only lowering edit is
untouched by this merge. Verified by content, not by the file list — sha-256 of
each merged file against the side that owns it:

| file | merged content equals |
|---|---|
| `ir-pass/src/CQLoweringPass.cpp` | **main** |
| `ir-pass/src/TaintPropagation.cpp` | **main** |
| `ir-pass/include/TaintPropagation.h` | **main** |
| `ir-pass/src/PredMuxFlatten.cpp` | **main** |
| `ir-pass/include/PredMuxFlatten.h` | **main** |
| `ir-pass/CMakeLists.txt` | **main** |
| `ir-pass/src/MergePhiPeel.cpp` | **main** |
| `tools/loop_twin_matrix.expected.txt` | **main** |
| `ir-pass/src/ArmClassify.cpp` | **F2 (6d06e51)** |

### 1b. `tests/e2e/CMakeLists.txt` — the one file BOTH sides append to

The only file with a change on each side. Inspected hunk by hunk (`diff` against
each parent), because a silently dropped `add_test` is invisible to every gate
except a name count:

* merged **vs main** = exactly F2's 42-line block at lines **4695-4736** —
  `e2e-slice-control-inplace-ry-stateprep-{bool,bool-negated,seed-eq-k}` with its
  "no `compare_files` twin gate, and the omission is deliberate" comment intact;
* merged **vs the F2 side** = exactly b6ap's 23-line block at lines
  **5109-5131** — `e2e-slice-control-fused-regions-{int,phase-bool}`.

A.1's five registrations came through the ancestor and are present:
`e2e-slice-control-select-cmp-{measure-after,round2-window}`,
`e2e-slice-control-phase-bool-loop-iterlocal{,-unrolled}` and
`e2e-phase-bool-loop-iterlocal-twin-identical`. **All three groups coexist**;
`grep -c '^add_test'` → **387**.

### 1c. The merge is an EXACT content union — measured

`git diff --numstat` over `ir-pass include tests`:

```
merged vs 3a3a2b9 :  5305 added / 1118 removed   ==  F2 standalone  (7203d1c..6d06e51)
merged vs 6d06e51 :  4656 added /    9 removed   ==  b6ap standalone (7203d1c..3a3a2b9)
```

Both equalities hold exactly, so applying the merge to either parent reproduces
the other side byte-for-byte. There is no third delta.

### 1d. F2's I-3 retirement trigger is still untripped

`IMPL_f2.md` §1c-bis: *if `railWireClosure` as called by F2 and R4's `CondRails`
ever DIVERGE, the narrowing must be re-derived from scratch.* b6ap touches
neither call site nor `railWireClosure` itself (it is in `ArmClassify.cpp`,
which b6ap does not modify), and `ArmClassify.cpp`'s merged content is
byte-identical to the F2 side's. The set equality the narrowing rests on is
carried through unchanged, for the second time.

---

## §2 BUILD

```
$ cmake --build build -j8
… [ 86%] Linking CXX shared module libCQPass.so
  [ 86%] Linking CXX executable cq-opt
  [ 92%] Built target CQPass
  [100%] Built target cq-opt
```

BOTH targets, per the CLAUDE.md trap (a `CQPass`-only rebuild leaves `%cq-opt`
stale and lit reports false green). The only warnings are the two pre-existing
`-Wunused-parameter` in `TaintPropagation.cpp` (`resolveSources`' `PhiFns`,
`deleteGlobalPhases`' `M`), present on both parents.

---

## §3 GATES — the full set, in order, verbatim

```
$ ctest --test-dir build -R ir-pass-lit --output-on-failure
1/1 Test #8: ir-pass-lit ......................   Passed   54.22 sec
100% tests passed, 0 tests failed out of 1

$ ctest --test-dir build -j6 -R '^e2e-' --output-on-failure
387/387 Test #318: e2e-loop-twin-matrix ........   Passed  440.94 sec
100% tests passed, 0 tests failed out of 387
Total Test time (real) = 440.98 sec

$ git status --porcelain tests/
(empty)

$ ctest --test-dir build -j6 --output-on-failure
397/397 Test #318: e2e-loop-twin-matrix ........   Passed  421.26 sec
100% tests passed, 0 tests failed out of 397
Total Test time (real) = 421.28 sec

$ cmake --build build --target cq-opt-equivalence-full
cq_opt_equivalence: compared 1859 fixtures, 0 mismatch(es)
```

```
$ cd build && lit -s ir-pass/test
Total Discovered Tests: 1859
  Passed           : 1858 (99.95%)
  Expectedly Failed:    1 (0.05%)
```

The 1 expected failure is `lowering_invert_add_i32.ll` (the standing Phase-7
XFAIL); **0 unexpected failures**. ⚠ `lit` must be run from `build/` — invoked
from the source root it resolves no substitutions and reports 1858 *failures*,
which reads exactly like a catastrophic regression and is a harness artefact.
Noted because it cost a minute here and will cost the next reader the same.

Both `-j6` runs were taken with nothing else on the box; **no relink happened
under either measurement**.

---

## §4 PROBE CORPORA — 481 rows, three binaries

Three binaries, so a mover can be **attributed** rather than argued. Each was
identified by SYMBOL before use, never by directory name:

| label | binary | revision | `reverifyCmpCondReads` | `peelIndependentMergePhis` | `f2SeedPinnedByLiveRegister` arity |
|---|---|---|---|---|---|
| `MRG` | `CQ_f2/build/ir-pass/cq-opt` | this merge, 8e1de9a | 1 | 1 | **+`SmallPtrSetImpl<Value*>`** (F2) |
| `B6P` | `CQ_b6ap/build/ir-pass/cq-opt` | 505a405, built at cc77815 == **main 3a3a2b9** | 1 | 1 | without (pre-F2) |
| `ORC` | `CQ_lang/build/ir-pass/cq-opt` | the frozen **0c7380c** oracle (read-only) | 0 | 0 | without |

`B6P` is the decisive column this pass gains over merge 1: it is the **pre-merge
`main` side**, so a merge-induced mover on A.1's or b6ap's corpus shows directly
as `MRG != B6P`. (The pre-merge *F2* side, 6d06e51, is not built; for F2's own
corpora the reference is `MERGE_f2_1.md` §4's recorded column.)

| corpus | rows | `MRG != B6P` | `MRG != ORC` |
|---|---:|---:|---:|
| `session-f2-i1/probes/` (29 `.c` + 21 `alt/` + 30 `mut/`) | 80 | **5** (F2's own) | 6 |
| `session-f2-i1/review_f2_r1_probes/` (`c/` + `ll/` + `rival/`) | 42 | **9** (F2's own) | 9 |
| `session-9pum/probes/` | 21 | **0** | 8 |
| `session-9pum/review_a1_r1_probes/run.sh` | 23 | **0** | — |
| `session-9pum/review_a1_r2_probes/run.sh` | 68 | **0** | — |
| `session-b6ap/probes/` (`.c` + `.s1.ll` + `z*.ll`) | 75 | **0** | 32 |
| `session-b6ap/review_b6ap_r1_probes/` (every `*.s1.ll`) | 38 | **0** | 21 |
| `session-b6ap/review_b6ap_r2_probes/` (every `*.s1.ll`, incl. `auto/`) | 134 | **0** | 70 |
| **total** | **481** | **14** | |

**All 14 `MRG != B6P` rows are F2's own, and every one is documented:**

| corpus | rows | direction |
|---|---|---|
| `probes/` | `a_prep`, `a_self`, `bc1`, `M2`, `u2` | DECLINE(F2) → **ACCEPT** |
| `review_f2_r1_probes/` | `c/k1_compound_prep`, `c/k3_ifelse_prep`, `c/n3_seed_eq_k_then_arith`, `c/o3_switch_prep`, `c/z3_flagarm_nomeas`, `ll/beta_post_add`, `ll/beta_post_xor`, `ll/onwire_folded` | DECLINE(F2) → **ACCEPT** |
| `review_f2_r1_probes/` | `c/n4_two_regions` | DECLINE(F2) → DECLINE(`value-arm swap-route`) — a decline-to-decline restring, the expected shape of a narrowing that removes one fence and leaves the program stopping at the next |

The five `probes/` rows are exactly the set `MERGE_f2_1.md` §4.1 recorded, and
the eight accept-flips in `review_f2_r1_probes/` are exactly the ones its §4.2
narrative names (`z3` NEW-accept, the `beta_post_{add,xor}` pair, `onwire_folded`
as "the ruling's new accept", `k1` accepting because it is not compound after
`-O1`).

**A.1's recorded SUBJECT column is reproduced row for row** on `MRG`: `r10v`,
`r903b`, `d1`–`d4` ACCEPT→DECLINE `condition measured before the control route`;
`9pum_{caller,lib}` ACCEPT→DECLINE `condition predates a non-diagonal gate`;
`d5_*` `control flow` on both; `a1`–`a7`, `k10`, `sw1` accept; `sw2` declines
(F-A1-4); `ip1`/`ip3` `rail record read past an in-place gate on the same rail`
on all three. In `review_a1_r1_probes`: `k7`/`k8`/`k9`/`o3_kick` decline
`predates a non-diagonal gate`, `b1`/`b2` oracle-DECLINE → subject-ACCEPT,
`o7a` decline / `o7c` accept, `c1`/`c3`/`c4`/`c7`/`c8`/`c10` accept and
`c2`/`c9` decline, `g2`/`g3` decline, `k6`/`sp1`/`sp2` decline on both.

`review_a1_r2_probes` reproduces its README except the same **three** rows
`MERGE_f2_1.md` §4.5 already explained — `io3.c`, `gs1.c`, `multi/io3m.c`, all
now DECLINE. That README was written against the pre-round-2-fix checkpoint
`b439944`; A.1's landed commit says outright that it closes the 7.6 I/O-sink /
7.5 guarded-store hole (bd `61k6`). **Those three should be folded into that
README by whoever writes A.1's landing record** — it still reads as if the
miscompile ships. (This is the second pass in a row that has had to say so.)

b6ap's own capability is unmoved: all 75 + 38 + 134 rows verdict-identical to
`main`, including the whole `control_peel_*` accept family (`p09_owner_int`,
`p22`/`p23`, `p31_three_phi`, `p50_fp_extra_phi`, `p71_call_arm_opaque`,
`p80_round2_out_cond`, `p90_qq_mux`, `z03`, `z08`, `z15`–`z23`) and its decline
partition (`p60_phase_arm`, `p88_two_preps`, `z05_inloop`, `z06_nonmuxable`,
`z07_condtree`, `z09_undef_incoming`, `z10_identity_phi`, `z13_threepred_external`,
`h30b_armdefined_speculatable`).

---

## §5 THE ONE SEMANTIC INTERACTION — a PEELED region reaching F2

The question this pass exists to answer: b6ap's peel can now hand a state-prep
region to `classifyArms` that previously never got there (`soleMergePhi` refused
>1 phi and the program died at `control flow`), so **F2's narrowing now runs on
peeled regions**. Measured on all three binaries, four spellings of the owner's
file (`b0` is the register the middle `if` compares, `b1` the one the second
`if` preps):

| spelling | `MRG` (the merge) | `B6P` (main 3a3a2b9) | `ORC` (0c7380c) |
|---|---|---|---|
| **as written** — `bool b0` / `bool b1` | `bare i1 register condition` | `bare i1 register condition` | `control flow` |
| **A** — `int b0` / `bool b1` | **`state prep seed is proven equal to the condition register`** | same | `control flow` |
| **B** — `bool b0` / `int b1` | `bare i1 register condition` | same | `control flow` |
| **control** — `int b0` / `int b1` | **ACCEPT**, 22 trace lines | ACCEPT | `control flow` |

* **The owner's file as written stops at `bare i1 register condition`** — the
  expected string, and `l4x4.b`'s wall.
* **B** stops at the same string, as expected: `b0` is a bare rail, so the
  middle `if (b0 == 1)` is a rail-root condition before the prep arm is reached.
* **A departs from the stated expectation (R-2).** It was expected to pass F2;
  it stops **at** F2. `main` gives the identical string, so **F2's narrowing is
  not what refuses it and the merge changed nothing**. The `-O1` image is one
  fused diamond on `%2 = icmp eq i32 %1, 1` with two merge phis; the peel turns
  the `i32` mux into a select and hands `classifyArms` a clean `_Bool` state
  prep of `%7` from seed `i1 false` — so the interaction genuinely IS exercised
  (the `ORC` column proves the peel is what got the program this far). What
  refuses it is the **drbq Inc-4 `i1`-width residual**, already written down in
  CLAUDE.md: *"at `i1` BOTH edges of an `i1` equality pin, so an `i1` seed under
  an `i1` condition is always ambiguous"*. The condition `%2` is itself a
  tainted `i1`, pinned `false` on the arm edge, and the seed is `i1 false`.
  Discriminator, measured: changing the seed to `bool b1 = 1` gives the **same**
  decline (the other edge pins `true`), which is the signature of the width
  residual and not of a seed coincidence. F2's narrowing cannot reach it by
  construction — it excludes values on the condition's own backward **wire**,
  and here the arm rotates a different register entirely.
* **The control compiles and its trace is BYTE-IDENTICAL to b6ap's committed
  golden** `tests/e2e/slice_control_fused_regions_int.expected.log` (22 lines),
  produced from source on the merged binary, with stage 2b
  `5 rail mint(s) … 2 verified, 0 violation(s), 0 unproven`. b6ap's capability
  is intact under F2's narrowing.

**Conclusion:** F2 and b6ap compose. A peeled region reaches F2's classifier and
is judged by exactly the fences F2 ships; the one shape that changes disposition
across the peel (`V0`, R-1) changes it on `main` too.

---

## §6 COUNTS (by command, on the merged tree)

```
$ ls ir-pass/test/*.ll | wc -l                 1859     (main 1851 + F2's net +8)
$ ls tests/e2e/*.expected.log | wc -l           350     (main  347 + F2's   +3)
$ ctest --test-dir build -N | tail -1     Total Tests: 397   (main 394 + F2's +3)
$ ctest --test-dir build -N -R '^e2e-'          387
$ ctest --test-dir build -N -R '^e2e-slice-'    348
$ ctest --test-dir build -N -R 'twin-identical'  29
$ grep -c '^add_test' tests/e2e/CMakeLists.txt  387
```

Every number is the exact sum of the two sides — the arithmetic signature of a
clean union. (F2 `git mv`'d 19 fixtures and added 8, so its net fixture delta is
+8, not +27.)

---

## §7 WHAT THIS PASS DELIBERATELY DID NOT DO

* **No push, no squash** — the squash commit is the orchestrator's.
* **No CLAUDE.md merge.** Neither A.1 nor b6ap touched `CLAUDE.md`, so F2's
  ruling paragraph came through untouched both times. The status-paragraph merge
  across all four tracks is the orchestrator's landing step.
* **No `tools/one.sh` whole-corpus sweep** from `review_f2_r1_probes`; the
  `cq-opt-equivalence-full` sweep over 1859 fixtures plus `ir-pass-lit` is this
  pass's corpus evidence.
* **No re-run of `tools/inplace_twin_matrix.py` / `angle_select_twin_matrix.py`**
  — `e2e-loop-twin-matrix` is a ctest entry and ran green inside the full suite
  (421 s); the other two are instruments, not gates, and neither side touched
  their subjects.
