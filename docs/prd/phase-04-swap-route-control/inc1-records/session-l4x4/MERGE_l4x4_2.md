# MERGE_l4x4_2 — `l4x4b-bool-ry-arm` × `main` a9cc062 (A.1 + b6ap + **F2**), SECOND pass

Merge record, 2026-09-11. Worktree `/Users/sorenwilkening/Desktop/CQ_l4x4`, branch
`l4x4b-bool-ry-arm` from the first merge **58b6229**, merged with **`main` a9cc062**
(= A.1 7203d1c + b6ap 3a3a2b9 + **Track C / F2** a9cc062). Merge commit **da2a4da**.
Merge base **3a3a2b9**. Not pushed; the squash is the orchestrator's
(`LANDING_PLAN.md` step 4). This pass discharges everything `MERGE_l4x4_1.md` §6 left
owed: F2 is now on `main` rather than carried, and the FULL `ctest -j6` +
`cq-opt-equivalence-full` ran here.

Three binaries, each identified **by symbol** before use, none of them rebuilt by me
except the first:

| label | binary | revision | `peelIndependentMergePhis` | `f2SeedPinnedByLiveRegister` arity | `constantAngleIsNonFinite` |
|---|---|---|---|---|---|
| `MRG` | `CQ_l4x4/build/ir-pass/cq-opt` | **this merge, da2a4da** | 1 | +`SmallPtrSetImpl` (F2) | **1** |
| `MAIN` | `CQ_f2/build/ir-pass/cq-opt` (read-only) | 8e1de9a; its worktree HEAD 30cf735 has **pass source byte-identical to `main` a9cc062** (`git diff a9cc062 30cf735 -- ir-pass/src ir-pass/include` = empty) | 1 | +`SmallPtrSetImpl` | 0 |
| `ORC` | `CQ_lang/build/ir-pass/cq-opt` (read-only) | the frozen **0c7380c** oracle | 0 | without | 0 |

`constantAngleIsNonFinite` is l4x4.b's own helper and is the discriminator that makes
`MAIN` a genuine pre-l4x4 reference rather than a directory name.

---

## §0 FINDINGS

**NONE.**

Stated as the three questions that could have produced one, each answered by
measurement over **778 probe rows** (§3):

1. **Did any verdict move on a corpus that is NOT l4x4.b's subject?** No.
   **89 movers vs `main`, and the `main` verdict of EVERY ONE of them is
   `bare i1 register condition`** — the exact string l4x4.b exists to retire.
   A.1's three corpora (119 rows), b6ap's two review corpora (353 rows) and F2's
   review corpus (42 rows) — **514 rows — move NOTHING**.
2. **Did anything `main` accepts stop compiling?** No: **0** MAIN-ACCEPT → MRG-DECLINE.
3. **Did any program that both binaries accept get a DIFFERENT circuit?** No: **0**
   rows where both accept and the lowered-IR md5 differs.

Two things are **reported rather than filed**, because neither is a mover:

* **R-1 — ONE FIXTURE WAS RESURRECTED BY THE MERGE AND IS DELETED IN IT** (§2). Not a
  compiler fact; a rename that existed on one side only.
* **R-2 — the `int b0` / `bool b1` spelling still declines at F2** (§5), byte-identically
  to `main`. That is `MERGE_f2_2.md`'s own R-2, unmoved: the drbq Inc-4 `i1`-width
  residual, already a filed follow-on, which l4x4.b does not claim and does not touch.

---

## §1 CONFLICTS — seven, every one resolved by reading both sides

The shape of all of them: **this branch is based on the F2 PRE-review checkpoint
578dbc4, and `main` carries F2's round-1-REVIEWED text 1419b5e.** The merge base
3a3a2b9 has no F2 at all, so both sides look like ADDITIONS of the same material in two
versions.

| file | hunk(s) | resolution | reason |
|---|---|---|---|
| `ir-pass/src/ArmClassify.cpp` | 3, at the `f2SeedPinnedByLiveRegister` header (:1259, :1315, :1411) | **MAIN** (F2's reviewed text: item I-3's "what `CondWire` actually is", I-1's two-door retirement trigger with the measured 2c-16 / R4-0 table, I-2's "wrong rival" paragraph) | **ALL THREE ARE COMMENT-ONLY.** Verified two ways rather than asserted: (a) `git diff 578dbc4 1f6c582 -- ArmClassify.cpp` touches only `railCondWireDisposition` / the rail ladder — l4x4.b never edits those blocks; (b) after resolution the file removes from `main` exactly the **13** non-comment lines l4x4.b is entitled to remove (the `!isa<CmpInst>` gate, `comparePredLowerable`'s cast, the `HasDataUse` loop, `condWireDisposition`'s call, and the two `isFinite()` lines refactored into `constantAngleIsNonFinite`) |
| `CLAUDE.md` | 3 | **MAIN** | same pre-review-vs-reviewed shape. The four-track status-paragraph merge is the orchestrator's at squash (`LANDING_PLAN.md` "After landing"); this pass wrote no status prose. ⚠ **One sentence `main` carries is now FALSE on this tree and is left for that pass, deliberately, rather than edited here**: *"THE OWNER'S `grover_oracle_uncompute.c` STILL DOES NOT COMPILE … F2 was wall 3 of 3"*. It compiles (§4) |
| `tests/e2e/CMakeLists.txt` | 1 | **HEAD** | the `main` side of the hunk is **EMPTY** — an adjacent add/add, F2's block ending where l4x4.b's begins. Kept l4x4.b's 6 registrations. `grep -c '^add_test'` **387 → 393** |
| `session-f2-i1/IMPL_f2.md`, `session-f2-i1/review_f2_r1.md` | add/add | **MAIN** | both "ours" are **BYTE-IDENTICAL to 578dbc4** (measured) — l4x4.b never edited F2's records, so ours is simply the older copy |
| `control_inplace_ry_stateprep_bool_seed_int_cond.ll`, `slice_control_inplace_ry_stateprep_bool.c` | add/add | **HEAD** | ours carry l4x4.b's "⚠ UPDATED BY … WALL 2 HAS SINCE MOVED" note, which `main`'s copies predate |

### 1a. Three now-FALSE statements inside the resolved hunks were corrected

Each said *"wall 1 (two merge phis, bd `b6ap`) still stands, so the owner's FILE still
declines `control flow`"*. b6ap LANDED on `main` 3a3a2b9 and is merged here, so all
three walls are down. Corrected in the two files above and in the `CMakeLists.txt`
l4x4.b block header (as dated HISTORY, not by deletion). They are comments; no
`add_test`, RUN line or CHECK moved.

### 1b. The mint-site enumeration survived, again

A.1's F-A1R2-1 invariant ("11 forward `lowerCompareToFlag` sites, every one with an
explicit `readKind`; 8 inverse, none") is unchanged by this merge — no mint added, none
removed. `MERGE_l4x4_1.md` §1 re-derived the table after the flag-mint conflict it had
to resolve; **this merge conflicts nowhere near a mint** (the three `ArmClassify.cpp`
hunks are in a function header comment).

### 1c. The merge is behaviour-neutral at source level — MEASURED, and it is the strongest single fact here

```
$ git diff 58b6229 HEAD --stat -- ir-pass/src ir-pass/include runtime tools/opcode_table.yaml include
 ir-pass/src/ArmClassify.cpp | 119 ++++++++++++++++++++++++++++++++-----
 1 file changed, 105 insertions(+), 14 deletions(-)

$ git diff 58b6229 HEAD -- ir-pass/src ir-pass/include \
    | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | grep -vE '^[+-]\s*//' | grep -vE '^[+-]\s*$' | wc -l
       0
```

**Zero non-comment lines of the pass changed between the first merge and this one**, and
`runtime/`, `tools/opcode_table.yaml` and `include/` are untouched (owner D3: no new
symbol). So `MERGE_l4x4_1.md`'s measurements carry forward by construction — and the 778
probe rows below are the independent confirmation, not the argument.

---

## §2 R-1 — THE RESURRECTED FIXTURE, and why it is a DELETE and not a rename

`ir-pass/test/control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll` came in from
`main` and turned `ir-pass-lit` **RED** on the first run (1894 discovered, 1 failed).

It is F2's own fixture, committed by Track C as a retirement-triggered DECLINE with this
in its header, verbatim:

> *"RETIREMENT: when `l4x4` lands, this file's string changes and it becomes an ACCEPT
> whose emitted stream is `cqrt_alloc_i1(false)` + `cqrt_ry_i1_controlled(h_b0, h_new,
> 0.5)` — with the register `h_b0` ITSELF as the control, no mint, no strip, no free.
> Re-derive it then; do not delete it."*

**l4x4.b had already done exactly that, on its own branch, before this merge**: `git mv`'d
to `control_inplace_ry_stateprep_rail_i1_seed.ll`, IR byte-unchanged, re-derived from the
pass output as the ACCEPT. `main` landed the file under the OLD name (Track C's branch
knew nothing of the rename), so the merge produced **one module under two names with
contradictory verdicts**.

Disposition: the resurrected copy is **DELETED in the merge commit**. The rename target IS
the re-derivation the retirement note asked for, so re-renaming would create a second copy,
not preserve anything. Measured on that exact module before deleting:

| binary | verdict |
|---|---|
| `MRG` | **ACCEPT**, emitting `cqrt_alloc_i1` ×2 + `cqrt_ry_i1` + `cqrt_ry_i1_controlled` **and nothing else** — the predicted stream, character for character |
| `ORC` 0c7380c | DECLINE `bare i1 register condition` |

The disposition is written into the accept twin's header so the deletion is not silent.

**A whole-corpus duplicate-body scan** (sha-256 over every fixture's non-comment lines)
found **9** same-IR groups; this was the only merge artefact — the other **8** pairs exist
on `main` already and are deliberate same-module/different-prefix pairs
(`control_swap_ifelse{,_derived}`, `spec_reject_callbr` / `spec_overaccept_probe_callbr_visible`, …).

**Dangling references: none that any gate reads.** The old name survives in 11 files — F2's
and l4x4's own RECORDS (which document the rename), two probe `.ll` headers, the PRD, and
the two fixtures' "was `git mv`'d from" notes. No `CMakeLists.txt`, no RUN line, no CHECK
line. Records are history; the cross-reference pass is the orchestrator's.

---

## §3 PROBE CORPORA — 778 rows, all twelve, on three binaries

One uniform recipe for every corpus (`.c` → `clang -O1 -emit-llvm`; `.ll`/`.s1.ll`
direct; `multi/` grouped by the `_caller`/`_lib` prefix and `llvm-link`ed), so a row is
comparable ACROSS binaries even where it does not reproduce a corpus runner's own
framing. A row is **(exit code, diagnostic string, md5 of the lowered IR when
accepting)** — an unchanged verdict over a CHANGED circuit still reads as a mover.

| corpus | rows | `MRG != MAIN` | `MRG != ORC` |
|---|---:|---:|---:|
| `session-l4x4/probes` (the SCOPE `t*` grid) | 35 | 18 | 18 |
| `session-l4x4/probes/impl` | 19 | 12 | 12 |
| `session-l4x4/review_l4x4b_r1_probes` | 45 | 33 | 33 |
| `session-l4x4/fix_l4x4b_r1_probes` | 10 | 9 | 9 |
| `session-9pum/probes` (Track A.1) | 24 | **0** | 7 |
| `session-9pum/review_a1_r1_probes` | 26 | **0** | 7 |
| `session-9pum/review_a1_r2_probes` | 69 | **0** | 25 |
| `session-b6ap/probes` | 75 | 8 | 35 |
| `session-b6ap/review_b6ap_r1_probes` | 95 | **0** | 49 |
| `session-b6ap/review_b6ap_r2_probes` | 258 | **0** | 110 |
| `session-f2-i1/probes` | 80 | 9 | 14 |
| `session-f2-i1/review_f2_r1_probes` | 42 | **0** | 9 |
| **total** | **778** | **89** | **328** |

**The audit that makes 89 a result rather than a number:**

```
MRG != MAIN (movers)                       : 89
  ... whose MAIN verdict is NOT 'bare i1'  : 0     <-- must be 0
  ... MAIN ACCEPT -> MRG DECLINE (regress) : 0     <-- must be 0
  ... both ACCEPT, CIRCUIT CHANGED         : 0     <-- must be 0
movers: 61 DECLINE->ACCEPT, 28 DECLINE->a LATER fence
```

The 28 that land on a LATER fence are all Prime-Directive-safe (a bare-`i1` bookkeeping
decline giving way to the fence that actually has something to say):
`rotation angle` 7 · `condition predates a non-diagonal gate` 5 ·
`state prep merged with a quantum register` 3 · `control flow` 3 ·
`stale rail record read past a controlled Ry` 2 ·
`state prep seed does not match the merge incoming` 2 ·
`arm rewrites a condition operand` 2 · `value-arm swap-route` 1 ·
`control flow inside a loop body` 1 · `condition measured before the control route` 1 ·
`unsupported quantum-derived rotation angle` 1.

**All 61 accepting movers were re-lowered and put through STRICT stage 2b:
61 checked, 61 `0 violation(s), 0 unproven`, 0 not clean.**

### Reconciliation with the two recorded columns

* `MERGE_l4x4_1.md` §3 measured against **PRE = 1f6c582** (l4x4.b present, A.1/b6ap/F2
  absent) and named every mover. Each of those named rows reproduces its recorded
  **MERGED** verdict here: `impl/V0_owner_file_2026-09-11` **ACCEPT**;
  `review_l4x4b_r1_probes/r03_b_zext_data` and `u01_borrow_before` **ACCEPT**;
  `session-b6ap/probes/{p00_owner_bool,p01_owner_intb1,p20_peel_bool_sel_first,
  p21_peel_bool_sel_after,p40_owner_sdagger}` **ACCEPT**;
  `w02_slice_phase_bool_src` **ACCEPT on `MRG` AND on `MAIN`** (a phase-bool program Inc 1b
  already handled — it was a mover against PRE only because PRE lacked b6ap, and is
  correctly not a mover here).
* `MERGE_f2_2.md` §4 measured **`MRG != B6P` = 0** on A.1's three corpora and b6ap's
  three. On this tree the same six corpora give `MRG != MAIN` = 0 / 0 / 0 / 8 / 0 / 0 —
  **the eight are `session-b6ap/probes`' `bool` rows**, which b6ap's own landing message
  predicted in those words (*"as written it now stops at `bare i1 register condition`
  (l4x4.b, next)"*), and every one has `main` = `bare i1 register condition`.
* The nine `session-f2-i1/probes` movers are the same class: `V0` (the owner's file),
  `C2`, `M1`, `b_prep`, `b_self`, `alt/rail_cond_i1` accept; `b_copy`, `bc2`, `u4` land on
  a later fence. `MERGE_f2_2.md` §5 recorded `V0`, `C2` and `M1` as
  `bare i1 register condition` **on `main`** and named l4x4 as the wall — this is that
  wall coming down.

---

## §4 THE MEASUREMENT — the owner's file, as written, COMPILES

`scratchpad/owner_file_2026-09-11.c` (= `example/grover/grover_oracle_uncompute.c`), NO
edits, `clang -O1` (`/usr/local/opt/llvm@19/bin`) + the MERGED `cq-opt`:

```
opt exit code : 0
stderr        : 0 bytes — not one byte, no warning
stage 2b      : free_pairing_check: 1 file(s), 6 rail mint(s) of which 5 left allocated,
                1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven
link + run    : ok (exit 0)
trace         : 19 lines
```

```
$ diff <MERGE_l4x4_1 §4's recorded 19 lines> <this run>
(empty)
```

**BYTE-IDENTICAL to the stream `MERGE_l4x4_1.md` §4 recorded.** The reading of it, line by
line against the source, is in that record and is not repeated; the two facts worth
restating are that `h0` (the `_Bool` `b0`) is read three times as a CONTROL (lines 5, 7,
15) and measured once (17) and is **never `cqrt_x`-bracketed and never freed** — Inc 1b's
invariant and Rule 6's required direction — and that the only two `cqrt_x` sit on the
ancilla `h2`, between its two controlled copies.

---

## §5 THE THREE SPELLINGS

`b0` is the register the middle `if` compares; `b1` the one the second `if` preps.

| spelling | `MRG` (this merge) | `MAIN` (a9cc062) | `ORC` (0c7380c) |
|---|---|---|---|
| **as written** — `bool b0` / `bool b1` | **ACCEPT, 19 lines**, 2b `1 verified, 0 violation(s), 0 unproven` | `bare i1 register condition` | `control flow` |
| **control** — `int b0` / `int b1` | **ACCEPT, 22 lines** — and the trace is **BYTE-IDENTICAL to b6ap's committed golden** `tests/e2e/slice_control_fused_regions_int.expected.log`, produced from source here | ACCEPT, 22 | `control flow` |
| **A** — `int b0` / `bool b1` | DECLINE `state prep seed is proven equal to the condition register` | **the same string, byte-identically** | `control flow` |
| **B** — `bool b0` / `int b1` | **ACCEPT, 19 lines**, 2b `1 verified, 0 violation(s), 0 unproven` | `bare i1 register condition` | `control flow` |

**Row B is the brief's open question and the answer is measured, not predicted: it
COMPILES.** `MERGE_f2_2.md` §5 recorded it as `bare i1 register condition` on `main` — a
bare rail `b0` is the condition before the prep arm is ever reached — and that is exactly
the wall l4x4.b removes. Its stream is the owner's file's with `h1` at `i32`:
`cqrt_alloc_i1/ry_i1` for `b0`, then `cqrt_alloc_i32` + `cqrt_ry_i32` +
`cqrt_ry_i32_controlled(h0, h1, -0.5)` for the negated prep, then the rail-root CNOT copy
and the two controlled copies for the peeled `a` mux, then three measures.

**Row A is `MERGE_f2_2.md`'s R-2, unmoved and re-confirmed here on both binaries.** Its
ground is the drbq Inc-4 `i1`-width residual (*"at `i1` BOTH edges of an `i1` equality
pin"*) — the CONDITION there is a COMPARE, so its flag is not on `CondWire` and F2's
narrowing cannot reach it by construction. **It is a filed follow-on, it is not l4x4.b's,
and l4x4.b neither fixes nor worsens it: `MRG` and `MAIN` give the same string.**

---

## §6 GATES (Rule 19, the full set — merge + Rule-13 core + a moved accept predicate)

```
$ cmake --build build -j8
  [ 55%] Built target CQPass
  [100%] Built target cq-opt

$ ctest --test-dir build -R ir-pass-lit --output-on-failure
1/1 Test #8: ir-pass-lit ......................   Passed   41.35 sec
100% tests passed, 0 tests failed out of 1

$ ctest --test-dir build -j6 -R '^e2e-' --output-on-failure
393/393 Test #318: e2e-loop-twin-matrix ..............  Passed  346.77 sec
100% tests passed, 0 tests failed out of 393
Total Test time (real) = 346.80 sec

$ git status --porcelain tests/
(empty)

$ ctest --test-dir build -j6 --output-on-failure
403/403 Test   #8: ir-pass-lit .......................  Passed   63.69 sec
100% tests passed, 0 tests failed out of 403
Total Test time (real) = 399.71 sec

$ cmake --build build --target cq-opt-equivalence-full
cq_opt_equivalence: compared 1893 fixtures, 0 mismatch(es)

$ cd build && lit -s ir-pass/test
Total Discovered Tests: 1893
  Passed           : 1892 (99.95%)
  Expectedly Failed:    1 (0.05%)
```

The 1 expected failure is the standing Phase-7 XFAIL `lowering_invert_add_i32.ll`;
**0 unexpected failures**. BOTH targets were built before every gate (the CLAUDE.md trap:
a `CQPass`-only rebuild leaves `%cq-opt` stale and lit reports false green). No relink
happened under any measurement, and nothing was killed by pattern.

⚠ The first `ir-pass-lit` run was **1894 discovered, 1 FAILED** — §2's resurrected
fixture. It is recorded rather than smoothed over: that red is the merge working.

### The two flipped fixtures, re-verified in both directions

| fixture | `ORC` 0c7380c | `MRG` |
|---|---|---|
| `control_peel_stateprep_rail.ll` (flipped by merge 1; `MERGE_l4x4_1.md` §6 owed this) | `cq-opt` exit **1** `control flow`, so `FileCheck` exit **2** — **RED** | exit 0, `FileCheck` exit 0 — **GREEN** |
| `control_inplace_ry_stateprep_rail_i1_seed.ll` (l4x4.b's own `git mv`, §2) | `cq-opt` exit **1** `bare i1 register condition`, `FileCheck` exit **2** — **RED** | exit 0, `FileCheck` exit 0 — **GREEN** |

---

## §7 COUNTS (by command, on the merged tree)

```
$ ls ir-pass/test/*.ll | wc -l                       1893
$ ls tests/e2e/*.expected.log | wc -l                 355
$ ctest --test-dir build -N | tail -1           Total Tests: 403
$ ctest --test-dir build -N -R '^e2e-'                393
$ ctest --test-dir build -N -R '^e2e-slice-'          353
$ ctest --test-dir build -N -R 'twin-identical'        30
$ grep -c '^add_test' tests/e2e/CMakeLists.txt        393
```

`main` a9cc062 is **1859 / 350 / 397 / 387 / 348 / 29**. The fixture arithmetic is worth
writing out, because the naive sum is wrong by one in each direction:

```
1859 (main)  + 34 (l4x4's net over its base 578dbc4, INCLUDING its one git mv)
             +  1 (main's copy of the file l4x4 renamed — the §2 resurrection)
             -  1 (that copy, deleted in the merge commit)
             = 1893
```

which is also why the first lit run discovered **1894**. Every other count is the exact
sum (+5 goldens, +6 ctest / `^e2e-`, +5 slices, +1 `twin-identical`).
`runtime/`, `tools/opcode_table.yaml` and `include/` are **UNTOUCHED**.

---

## §8 WHAT THIS PASS DELIBERATELY DID NOT DO

* **No push, no squash** — the squash commit is the orchestrator's (`LANDING_PLAN` step 4).
* **No CLAUDE.md status-paragraph merge.** `main` carries F2's *"the owner's file STILL
  DOES NOT COMPILE … F2 was wall 3 of 3"*, which is false on this tree (§4). Four tracks
  now have status prose to reconcile and that is one job, not four — but it is **owed
  before the squash lands**, because it is the one place a reader looks first.
* **No record cross-reference pass.** F2's and l4x4's records name the fixture §2 deleted;
  they are history and correct as history (§2).
* **No `tools/inplace_twin_matrix.py` / `angle_select_twin_matrix.py` re-run** — instruments,
  not gates; `e2e-loop-twin-matrix` IS a gate and ran green inside both `-j6` runs.
