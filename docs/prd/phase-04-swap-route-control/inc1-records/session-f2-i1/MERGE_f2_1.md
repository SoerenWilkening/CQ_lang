# MERGE 1 — `main` 7203d1c (Track A.1) into `f2-condwire-narrowing`

**Merge record.** Worktree `/Users/sorenwilkening/Desktop/CQ_f2`, branch
`f2-condwire-narrowing`, from checkpoint **1419b5e**. Merge commit **8a1fec1**.
Not pushed; the squash is the orchestrator's (LANDING_PLAN step 3). This is the
**first** of the two planned merges — `b6ap` lands next and is merged in a second
pass, after which the FULL suite + `cq-opt-equivalence-full` run. The gates below
are the **light** set the orchestrator scoped for this pass.

Nothing under `/Users/sorenwilkening/Desktop/CQ_lang/` or any other worktree was
written. `CQ_lang/build/ir-pass/cq-opt` was used READ-ONLY as the frozen 0c7380c
ORACLE and was verified to still be that revision (`nm | grep -c
reverifyCmpCondReads` → **0**, i.e. pre-A.1).

---

## §0 FINDINGS

**NONE.** No probe verdict moved across the merge, in either direction, on any
of the five corpora re-run (§4). The three departures from a recorded README
verdict are all accounted for and none is merge-induced; they are named in §4.5.

---

## §1 CONFLICTS

**NONE — `git merge main` applied cleanly (exit 0, no `UU`/`AA` paths).**

The two tracks touch exactly **two** files in common and neither overlaps:

| file | A.1's regions (base 0c7380c line numbers) | F2's regions (same base) | overlap |
|---|---|---|---|
| `ir-pass/src/ArmClassify.cpp` | 1865, 1895, 1912, 1931, 1946, 2072, 2113, 4204 | 219, 1188, 1360, 2455, 2984, 2994 | **none** |
| `tests/e2e/CMakeLists.txt` | appends its 5 slice registrations | appends its 3 | **none** (both blocks present) |

A.1's `ArmClassify.cpp` work is `railWireNamesBackward` (widened to
`const Value *`, plus the `taint.InPlaceRailOps` crossing), the per-activation
barrier inside `railMeasuredBeforeReadPoint`, the new `condCmpOperandSeeds` /
`condCmpMeasuredBeforeReadPoint` / `reverifyCmpCondReads`, and the
`classifyPhaseKickback` call site. F2's is `f2SeedPinnedByLiveRegister`'s
`CondWire` parameter + the one `!CondWire.count(V)` conjunct at the equality
**test**, the `railWireClosure` set builder at the caller, the deleted
plain-literal fast path, and the large header comments. Every changed region
therefore came from exactly one side.

Every other file is an ADD on one side only (A.1: 38 new `.ll` + 1 deleted + 9
e2e files + 18 other `ir-pass` sources/headers + its `session-9pum/` record;
F2: 8 new `.ll`, 19 `git mv`'d, 3 slice pairs, `CLAUDE.md`,
`control-in-place-PRD.md`, its `session-f2-i1/` record).

### 1a. The merge is an EXACT content union — measured, not assumed

Conflict-free is not the same as interaction-free. `git diff --numstat` over
`ir-pass include tests`:

```
merged vs 7203d1c :  5305 added / 1118 removed   ==  F2 standalone  (0c7380c..1419b5e)
merged vs 1419b5e :  4398 added /  131 removed   ==  A.1 standalone (0c7380c..7203d1c)
```

Both equalities hold exactly, so applying the merge to either parent reproduces
the *other* side's change byte-for-byte. There is no third delta.

### 1b. The F2 I-3 retirement trigger is NOT tripped

`IMPL_f2.md` §1c-bis names the cheapest way to break this narrowing by accident:
*if `railWireClosure` as called by F2 and R4's `CondRails` ever DIVERGE — a
different helper, a different `WireDir`, a different seed set, an `Exclude` on
one side and not the other — the narrowing must be re-derived from scratch.*
Checked on the merged tree:

```
F2   (ArmClassify.cpp:3784)   railWireClosure(Region.Condition, Taint, WireDir::BackwardOnly, nullptr, nullptr, CondWire);
                              for (Value *P : Prov) railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr, CondWire);
R4   (ArmClassify.cpp:3915)   railWireClosure(Region.Condition, Taint, WireDir::BackwardOnly, nullptr, nullptr, CondRails);
                              for (Value *P : Prov) railWireClosure(P, Taint, WireDir::BackwardOnly, nullptr, nullptr, CondRails);
```

Same helper, same two seeds, same `Taint`, same direction, no `Exclude` on
either, same `Prov` (`condProvenance(Region.Condition)` at `:3176`). A.1 touched
neither site and did not touch `railWireClosure` itself (it is defined at
`ArmClassify.cpp:476`, outside every A.1 hunk; A.1's `WireWalk.cpp` edits are to
`phiTracksWire` and `findNonDiagonalWireGate`, which are rung (iii)'s walker, not
this closure). **The set equality the narrowing's safety rests on survives the
merge unchanged.**

---

## §2 BUILD

```
cmake --build build -j8
… [ 83%] Linking CXX shared module libCQPass.so
  [ 90%] Built target CQPass
  [100%] Built target cq-opt
```

BOTH targets, per the CLAUDE.md trap (a `CQPass`-only rebuild leaves `%cq-opt`
stale and lit reports false green). The only warnings are the two pre-existing
`-Wunused-parameter` in `TaintPropagation.cpp` (`resolveSources`' `PhiFns`,
`deleteGlobalPhases`' `M`), present on both parents.

---

## §3 GATES (light set — the full suite is the post-b6ap pass)

```
$ ctest --test-dir build -R ir-pass-lit --output-on-failure
1/1 Test #8: ir-pass-lit ......................   Passed   87.64 sec
100% tests passed, 0 tests failed out of 1

$ lit -s ir-pass/test
Total Discovered Tests: 1821
  Passed           : 1820 (99.95%)
  Expectedly Failed:    1 (0.05%)

$ ctest --test-dir build -j6 -R 'stateprep|select-cmp|select_cmp|kickback-cmp' --output-on-failure
100% tests passed, 0 tests failed out of 8
Total Test time (real) =  12.22 sec

$ ctest --test-dir build -j6 -R 'iterlocal' --output-on-failure
100% tests passed, 0 tests failed out of 3
Total Test time (real) =   5.80 sec
```

The 1 expected failure is `lowering_invert_add_i32.ll` (the standing Phase-7
XFAIL); **0 unexpected failures**.

⚠ The orchestrator's filter `kickback-cmp` matches **no ctest name** — A.1's
kickback-side e2e work is registered as `e2e-slice-control-phase-bool-loop-
iterlocal{,-unrolled}` plus the `e2e-phase-bool-loop-iterlocal-twin-identical`
`cmp` gate. Those three were run as the fourth line above rather than left
silently unexercised. The 8 in the third line are F2's six
`e2e-slice-control-inplace-ry-stateprep*` (three pre-existing + its three new)
and A.1's two `e2e-slice-control-select-cmp-*`.

---

## §4 PROBE CORPORA — every verdict re-run on the merged binary

Three binaries, so that a mover can be ATTRIBUTED rather than argued:

| label | binary | revision |
|---|---|---|
| `MRG` | `CQ_f2/build/ir-pass/cq-opt` | the merge, 8a1fec1 |
| `F2C` | a purpose-built reference in the session scratchpad | the F2 checkpoint **1419b5e** (local `--shared` clone, `cq-opt` only) |
| `ORC` | `CQ_lang/build/ir-pass/cq-opt` | the frozen **0c7380c** oracle (read-only) |

The decisive reading: a merge-induced mover on F2's corpus shows as
`MRG ≠ F2C`; one on A.1's shows as `MRG` departing from A.1's recorded landed
SUBJECT column. Both were measured.

### 4.1 `session-f2-i1/probes/` — 80 probes, **MRG == F2C on all 80**

* 29 top-level `.c` (`V0 C2 M1 M2 M3 mp`, `u1-u6 v1-v4 w1-w5`, `a_* b_* bc1 bc2`)
* 21 `alt/*.ll` — the α/β alternative readings
* 30 `mut/*.ll` — the pin-identification mutants

`ORC` reproduces `probes/README.md` row for row: `V0` `control flow`; `C2`/`M1`
`bare i1 register condition`; `M2` F2; `M3`/`v4` accept; the 13/13
self-controlled spellings all declining at their recorded fence (`u1`/`w1`/`w2`
F1, `u2` F2, `u3` value-arm, `u4` bare-i1, `u5`/`w4`/`w5` `condition data use`,
`u6`/`v1`/`v2`/`w3` gate 2c, `v3` R4); `alt/` 21/21 declining at the recorded
strings; `mut/` 27 accept + the three `Truncated` rows (`step_cap_over`,
`unevaluable_pinned_operand`, `unfoldable_curated_call`) declining with the F2
string. `MRG` differs from `ORC` on exactly F2's own documented flips
(`a_prep`, `a_self`, `bc1`, `M2`, `u2`) and on nothing else.

### 4.2 `review_f2_r1_probes/run_all.sh` — 42 probes (NEW = MRG, OLD = ORC)

Every conclusion the round-1 README records still holds on the merged binary:
`rival/` **6/6 decline** on NEW; the α 2×2 (`offwire_rival` accepts on both,
`offwire_folded` still declines F2, `onwire_rival` declines 2c on both,
`onwire_folded` is the ruling's new accept); `beta_post_{add,xor}` accept while
`…_R` decline F1 on both; `fp_fwd_{fneg,fabs}` still decline (the proof the
exclusion sits at the TEST); `x1..x5` decline on both; `z3` NEW accept / OLD
decline, `z1` `rotation arm shares the condition flag` on both; `b1..b3`
`control flow` on both; `k4`/`k5` compound → `control flow`, `k1` (not compound
after `-O1`) accepts.

### 4.3 `session-9pum/probes/` — 21 probes

`MRG` reproduces A.1's recorded **SUBJECT** column exactly: `r10v`, `r903b`,
`d1`, `d2`, `d3`, `d4` ACCEPT→DECLINE `condition measured before the control
route`; `9pum_{caller,lib}` ACCEPT→DECLINE `condition predates a non-diagonal
gate`; `d5_*` `control flow` on both; `a1`–`a7`, `k10`, `sw1` accept; `sw2`
declines (F-A1-4); `ip1`/`ip3` `rail record read past an in-place gate on the
same rail` on all three.

**`F2C == ORC` on all 21** (F2 has no effect on A.1's corpus) and **`MRG ≠ F2C`
on exactly the 8 rows A.1 documents as movers**. No extra mover.

### 4.4 `review_a1_r1_probes/run.sh` (SUBJECT re-pointed at the merged build)

26 rows, every one as `FIX_A1_R1.md` records: `k7`/`k8`/`k9`/`o3_kick` decline
`predates a non-diagonal gate` (the BLOCKER closed), `k10` accepts; `b1`/`b2`
oracle-DECLINE → subject-ACCEPT (the per-activation barrier); `o7a` declines,
`o7c` accepts; `c1`/`c10`/`c7`/`c8`/`c3`/`c4` accept and `c2`/`c9` decline (the
F-A1-3 narrowing, with `-O1` folding the compare back onto the measured
register); `sw1` accept / `sw2` decline; `k6` declines on both; `g2`/`g3`
decline; `sp1`/`sp2` decline on both.

### 4.5 `review_a1_r2_probes/run.sh` — ~70 rows, and the three explained departures

All rows match that README's SUBJECT column **except three**:

| probe | README SUBJECT (checkpoint `b439944`) | merged | why this is not a merge mover |
|---|---|---|---|
| `io3.c` | ACCEPT ✘ | **DECLINE** `condition predates a non-diagonal gate` | A.1's own ROUND-2 FIX. That README is the round-2 *review*, written against the pre-fix checkpoint; the landed 7203d1c commit message says outright that it closes "the pre-existing 7.6 I/O-sink / 7.5 guarded-store flag-mint hole (bd 61k6, closed by the `WireRuled` narrowing)". |
| `gs1.c` | ACCEPT ✘ | **DECLINE** | same fix, 7.5 guarded Shadow store face |
| `multi/io3m.c` | ACCEPT ✘ | **DECLINE** | same fix, `io3` as two TUs |

Everything else is unmoved, including the discriminators that make those three
readable: `io5` (already DECLINE), `io0`/`gs0` (accept controls), `io4` (the
kickback with the same wire shape, DECLINE on both), the seven `c_*` consumers
that always caught the shape, `f4f`/`f4h`/`f4a`/`x1`/`x2`/`x3`/`m1`,
`r1`–`r4`/`b3`/`b4`, `s01`–`s07`, `a01`–`a07`, `od1`–`od4`, `d3a`–`d3d`,
`ab0`–`ab2`, `f4b`–`f4e`, `multi/w3`–`w11`, `multi/q4a`/`q4b`.

**These three verdicts should be folded into `review_a1_r2_probes/README.md` (or
its successor) by whoever writes A.1's landing record** — the file currently
reads as if the miscompile still ships. ⚠ **DISCHARGED 2026-09-11 by the session
docs pass: `session-9pum/review_a1_r2_probes/README.md` now carries a dated ERRATA
block naming exactly these three rows and pointing at `FIX_A1_R2.md` and at this
section.** The three rows in `../session-9pum/review_a1_r2.md` itself are left as
written — it is a dated review of a pre-fix checkpoint, and its own §0 says so.

---

## §5 COUNTS (by command, on the merged tree)

```
$ ls ir-pass/test/*.ll | wc -l                 1821     (main 1813 + F2's net +8)
$ ls tests/e2e/*.expected.log | wc -l           348     (main  345 + F2's   +3)
$ ctest --test-dir build -N | tail -1     Total Tests: 395   (main 392 + F2's +3)
$ ctest --test-dir build -N -R '^e2e-'          385
$ ctest --test-dir build -N -R '^e2e-slice-'    346
$ ctest --test-dir build -N -R 'twin-identical'  29
```

Every number is the exact sum of the two sides, which is the arithmetic
signature of a clean union (F2 `git mv`'d 19 fixtures and added 8, so its net
fixture delta is +8, not +27).

---

## §6 WHAT THIS PASS DELIBERATELY DID NOT DO

* **No full `ctest -j6`** and **no `cq-opt-equivalence-full`** — the orchestrator
  scoped them to the post-`b6ap` pass, and they are mandatory there (Rule 19
  moments 1, 2 and 5 all apply to this branch).
* **No push, no squash** — the squash commit is the orchestrator's.
* **No `tools/one.sh` whole-corpus sweep** from `review_f2_r1_probes` (1784×2
  fixtures); `ir-pass-lit` over 1821 fixtures is this pass's corpus evidence.
* **No CLAUDE.md merge.** A.1 did not touch `CLAUDE.md` (measured:
  `git diff --name-status 0c7380c 7203d1c` lists no `CLAUDE.md`), so F2's ruling
  paragraph came through untouched. The status-paragraph merge across all four
  tracks is the orchestrator's landing step.
* **No re-measurement of the owner's `grover_oracle_uncompute.c`** — F2 is wall
  3 of 3 and `b6ap`/`l4x4` are still ahead of it; `V0.c` still declines
  `control flow` on the merged binary, unchanged from both parents (§4.1).
