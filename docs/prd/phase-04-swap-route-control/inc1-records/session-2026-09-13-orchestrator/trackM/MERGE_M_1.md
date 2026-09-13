# MERGE_M_1 — `mphi-rail-leaf` × `main` e625f30, landing 3 (Track M, bd `boi6` D-B / `8xaw`)

Merge-and-gate record, 2026-09-13. Worktree `/Users/sorenwilkening/Desktop/CQ_mphi`, branch
`mphi-rail-leaf` from `main` **8659a77**, merged with **`main` e625f30** (= landing 1's Track C
`21mg` + Track L's H-10 pins, landing 2's Track R-1 `rb9x`, and this session's docs). Review
verdicts: r1 CLEAR-WITH-ITEMS → `FIX_M_R1.md` → r2 **CLEAR-WITH-ITEMS** (`review_M_r2.md`, three
items, none a miscompile, none an over-accept). Committed on the branch, **not pushed**; the squash
is the orchestrator's. Instance of `../MERGE_BRIEF_TEMPLATE.md` + `MERGE_BRIEF_M.md`.

**The last commit carrying CODE, FIXTURES or GOLDENS is `54079b6`**, and every gate below was run on
the tree at that commit; the branch tip is the docs-only commit that adds THIS record and its
corpora on top of it (`git log --oneline -1` in the worktree is the hash the squash message should
cite). Four commits, in order:

```
<tip>    docs(mphi): merge-and-gate record MERGE_M_1.md + GATES.md lines + the merged-binary corpora
54079b6  test(mphi): round-2 review items F2-1/F2-2/F2-3 (fixture + comment only)   <- the gated tree
2251621  Merge branch 'main' into mphi-rail-leaf
4971b73  wip(mphi): Track M + fix R1 + records      (git status --porcelain | wc -l = 63 before it)
```

Three binaries:

| label | `cq-opt` sha256 (16) | `libCQPass.so` (16) | what it is |
|---|---|---|---|
| ORACLE | `fbbe0820ef4b176a` | `40e9c7a51e8120bb` | `/Users/sorenwilkening/Desktop/CQ_lang/build`, `e96f89c` — **re-hashed before first use, matches `PROTOCOL.md`**, never built, never written |
| SUBJECT (pre-merge) | `0d3105d0eb9d476a` | `7b0c0bb505e6a41a` | the round-1 fix's build; re-hashed on disk before the merge and **matches** every `0d3105d0` row of `GATES.md` |
| **MERGED** | **`f7b65d8ccd7bc472`** | **`f9e898badfd4207a`** | this tree after the merge + items A + reconfigure + `cmake --build build -j8` (BOTH targets, 52.5 s) |

The MERGED hash is NEW — it carries landing 1's `MeasureLowering` and landing 2's `TaintPropagation.h`
`PeelClones` as well as Track M's — so **nothing was citable**: every gate below was RUN on
`f7b65d8ccd7bc472`.

---

## §0 FINDINGS

**ZERO compiler findings. One instrument fact, re-measured rather than inherited, and one thing the
brief asked for that does not exist.**

The four questions that could have produced a compiler finding, each answered by measurement:

1. **Did the merge move anything?** No conflict existed to mis-resolve (§1), and the three review
   items are mechanically fixture-and-comment only: `git diff -U0 2251621 54079b6 --
   ir-pass/src/SwapRouteEmit.cpp | grep -vE '^[+-]\s*//'` yields **0** added or removed
   non-comment lines. The only `ir-pass/src` file item A touched is that one, and only its comment.
2. **Did anything the ORACLE accepts stop compiling?** **0** ACCEPT→DECLINE over 3113 rows (§3).
3. **Did any program both binaries accept get a DIFFERENT circuit?** **0** md5 differences over the
   1519 ORACLE accepts (§3).
4. **Is every new accept Rule-6 clean?** All **79** accepting movers re-lowered through STRICT stage
   2b: `0 violation(s), 0 unproven`, 79/79 (`probes/merge/stage2b_movers_f7b65d8c.txt`).

**F-R1 REPRODUCES ON THIS BINARY, and the arithmetic closes.** Landing 2 found that the shared corpus
recipe tags a decline with `grep -oE 'cq [a-z0-9 ]+: [^"]+'`, which matches **nothing** in
`cq_measure_<sfx> operand …`, so that whole family renders as an empty `D:` and a DECLINE→DECLINE
string change inside it is *invisible*, not merely unnamed. I did not take that closure on trust:
`probes/merge/decline_stderr_delta_M.sh` re-runs BOTH binaries over **every row either side declined
(1593)** and byte-compares the FULL stderr plus the exit code. Result: **92 rows differ, of which 89
are the visible movers (79 D→A + 10 D→D) and 3 were invisible** — the same three as landing 2, all
landing 1's declared `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement
needs a defined value` (`trackC/probes/c6_undef_bool.c`, `trackC/probes/i0_poison_operand.ll`,
`ir-pass/test/lowering_reject_measure_undef_operand.ll`), each still a loud `DS_Error` at exit 1.
**No row moved on any Track M or R-1 string that the string sweep had hidden.** The 89 + 3 = 92
arithmetic closing exactly against §3's 89 visible movers is the cross-check that the delta
instrument is itself sound.

⚠ **Landing 2's own parallelism artefact is FIXED here, not repeated.** Its
`decline_stderr_delta.sh` wrote the `### <rel>` header and the diff body as two separate appends
under `-P6`, so two rows could interleave and it had to re-run the three invisible rows serially
before naming them. This copy writes each row's output to its own file in a temp dir and
concatenates them in sorted order, so the parallel output *is* the evidence — no serial re-run was
needed and none was done.

**The brief's `$SES/trackR/review_R1_r1_probes/G6_quantum_mux_values.c` does not exist.**
`find <inc1-records> -name G6_quantum_mux_values.c` returns exactly **one** path, the 2026-09-11
integration probe — which is also the module Track M pinned as
`control_swap_accept_select_mergephi_quantum_arm_then_prep.ll`. Measured at that one path (§4):
ACCEPT **26** lines, as the brief predicts. `customers.sh` says so in a comment rather than silently
dropping the row.

---

## §1 CONFLICTS — zero, and the union was checked anyway

```
$ git -C /Users/sorenwilkening/Desktop/CQ_mphi status --porcelain | wc -l   # before
      63
$ git add -A && git commit -m "wip(mphi): Track M + fix R1 + records"   -> 4971b73
$ git merge main                                                        -> 2251621, NO conflict
$ git status --porcelain                                                -> (empty)
```

`MERGE_BRIEF_M.md` predicted a conflict in `tests/e2e/CMakeLists.txt` (three appenders) and possibly
in `trackM/GATES.md`. **Neither fired.** The CMakeLists reason is the same as landing 2's — the three
sides appended at **different anchors**, so git's three-way merge saw disjoint hunks: Track M's nine
entries go in at the `slice_control_inplace_ry_*` group (`@@ -4829`), after
`e2e-phase-bool-loop-twin-identical` (`@@ -5304`) and at the end (`@@ -5539`), while `main`'s eight
(landing 1's seven + landing 2's one) are at `@@ -4851` and beyond. `trackM/GATES.md` was never
touched on `main` (`git log 8659a77..e625f30 -- …/trackM/GATES.md` is empty), so there was nothing to
union — the branch's rows stand as written and this landing's are appended below them.

**A clean auto-merge is not evidence that the result is the UNION, so the union was checked three
ways** — this is exactly the step the brief's "keep ALL blocks in order" exists to guarantee:

| check | result |
|---|---|
| `git diff e625f30 2251621 -- tests/e2e/CMakeLists.txt` | ONE hunk `@@ -4851,6 +4851,130 @@`, adding **only** Track M's nine entries |
| `git diff 4971b73 2251621 -- tests/e2e/CMakeLists.txt` | THREE hunks, adding **only** `main`'s eight (the R-1 fused slice, Track L's three carried-theta entries, landing 1's four measure entries) |
| `grep -c '^add_test'` at base / branch / main / merged | **393 / 402 / 401 / 410** — 393 + 9 + 8 = 410 exactly |

Also verified by reading: the `get_property(_E2E_ALL_TESTS DIRECTORY PROPERTY TESTS)` +
`set_tests_properties(...)` sweep is still the **LAST** statement in the file (its own comment says it
must be, or `CQ_PYTHON`/`CQ_LD`/`CQ_S1CACHE` would not reach every test — a merge that appended after
it would have been green here and wrong in ways nothing in the tree checks).

**No `ir-pass/src` conflict appeared, as the brief expected**, because the three tracks are disjoint
by file (`C`: `MeasureLowering.{h,cpp}`; `R-1`: `TaintPropagation.h`, `MergePhiPeel.cpp`,
`ArmClassify.cpp`; `M`: `SelectClassify.{h,cpp}`, `SelectMergeEmit.cpp`, `RegionFlatten.cpp`,
`Specialization.cpp`, `SwapRouteEmit.cpp`, `ControlPlan.h`). `git diff --name-status e625f30 2251621`
outside `docs/` is exactly Track M's **49** paths and nothing else. `TaintPropagation.h` and
`ControlPlan.h` are shared HEADERS, so the whole tree was rebuilt rather than incrementally linked —
which the `cmake --build build -j8` output confirms (every `ir-pass` TU recompiled).

### The three review items (step 8, applied BEFORE the full suite)

* **F2-1 (MEDIUM, the MUST)** — `control_swap_accept_select_mergephi_rail_then_kickback.ll` now
  carries `; CHECK: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 3.000000e-01)` between the flag mint
  (`:204`) and the `_unc` strip. This is the one gate in the whole increment that is a `cqrt_rz`, and
  it was pinned only by a COUNT — which any `rz` satisfies. `ran: review_M_r2_probes/rz_mutation.sh`
  on the merged binary:

  | mutant | before (`0d3105d0`, review r2) | **after (`f7b65d8c`)** |
  |---|---|---|
  | unmutated control | all 11 prefixes green (required) | all 11 prefixes green |
  | target `%h_cmp` → `%h` (the `b0` rail) | **MISSED by all 11** | **caught — `CHECK`** |
  | target `%h_cmp` → `%h4` (the prepped `b1` rail) | **MISSED by all 11** | **caught — `CHECK`** |
  | target `%h_cmp` → `%out3` (the user's `a`) | **MISSED by all 11** | **caught — `CHECK`** |
  | angle `3.000000e-01` → `9.000000e-01` | **MISSED by all 11** | **caught — `CHECK`** |

  ⚠ The script's own label formatting prints the catching prefix twice (`caught byCHECK,CHECK` — a
  `${caught:+…}${caught:-…}` artefact); I re-ran the 11 prefixes individually on the `%h` mutant and
  the verdict is `CHECK exit=1`, the other ten `exit=0`. **Exactly one prefix catches it, and it is
  the new line.** The fixture's own "⚠ NO `cqrt_rz` NEGATIVE HERE" paragraph was rewritten to say
  what is now pinned and what was missed before, so the file carries its own history.
* **F2-2 (LOW, DOC)** — the F-M7 retirement trigger at `SwapRouteEmit.cpp` asserted that a
  `SelectRegion` cannot reach `declineRegion`; the round-1 fix's own loop (`:2639`) calls it on one
  directly, and `Pending[select] >= 1` now lets the Kahn backstop (`:2667`) find a select `!Done`.
  The comment now (a) says a `SelectRegion` DOES reach the lambda and that only the alias pre-flight
  (`:2573`) cannot see one — by null block fields plus `if (!Doomed) continue;`, **not** by any `Kind`
  test; (b) gives the real safety ground, which is about TIME and not kind: all three call sites run
  BEFORE the emission loop at `:2685` and each returns immediately after diagnosing, so no M-β RAUW
  and no `RegionFlatten` erasure has happened and every `Condition` is still a live instruction; and
  (c) re-points the trigger at the EMISSION-time readers (the `fg9k` value arm on a φ; a fourth
  `declineRegion` site placed inside the emission loop).
* **F2-3 (LOW)** — the merge-OUT rail (`%out`/`%out3`/`%out5`), the register the source's variable
  ends up in and the one every accept MEASURES, was named by **no** `NOX-NOT` in 11/11 accepts and by
  no `NOFREE-NOT` in 8/11. Now **11/11 and 11/11**. `ran: review_M_r2_probes/negcoverage.py` →
  `11 fixtures, 0 with a NOX gap / ancilla-pointing / undefined negative` (was 11 with a gap).
  `ran: probes/impl/vacuity.py` over the same 11 → **84 named negatives, 0 VACUOUS** (was 63/0), i.e.
  the 21 added negatives are all non-vacuous. `ran: lit --filter 'mergephi|rail_after_prep'` →
  **20/20 PASS**.

---

## §2 RESURRECTIONS — the trigger did not fire; the scan was run anyway and is clean

`git diff --name-status -M` over `ir-pass/test` + `tests/e2e`, base→main and base→merged: **0 renames
on either side**, so the bd memory `merge-resurrects-git-mv-fixture` trigger is inapplicable. (Item D
of the brief notes Track M fixed seven `NOROUTE-NOT: phi` fixtures **in place**, which is why there is
no rename to resurrect.) Run regardless, because a clean scan is only worth its baseline:

```
$ python3 <sha-256 over each ir-pass/test/*.ll's NON-COMMENT lines>
files=1928  same-body groups=9
```

**All 9 groups are the ones `MERGE_R1_1.md` §2 and `MERGE_C_1.md` §2 enumerated** — the eight
deliberate same-module/different-prefix pairs plus landing 1's declared
`lowering_measure_round2_sixfive_handle.ll` / `control_classical_call_arm_accept.ll` pair. **Track M's
20 new fixtures create no group**: no two of them share a body and none duplicates a shipped module.
Nothing to dispose of.

Separately, the `phi`-anchor hygiene fix survived the merge intact: **16** fixtures carry
`NOROUTE-NOT: {{= phi }}` and **0** carry the bare `NOROUTE-NOT: phi` that matched the worktree path.

---

## §3 CORPORA — 3113 rows RUN on the merged binary, 92 movers, every one explained

`probes/merge/corpus_merge_M.sh` → `probes/merge/corpus_f7b65d8c.txt`. Corpora = the template's step 5
(`ir-pass/test/*.ll` **1928**, `$SES/probes`, every `$SES/track*/probes` and `$SES/track*/*probes*`
**recursively** — so `trackM/probes/impl`, `trackM/probes/merge`, `trackM/fix_M_r1_probes`,
`trackM/review_M_r{1,2}_probes`, `trackR/probes/{impl,merge,r2}`, `trackR/review_R1_r1_probes`,
`trackC/probes`, `trackC/review_C_r1_probes`, `trackL/probes` are all in — plus the seven 2026-09-11
session dirs' `probes/` + `review_*_probes/`), i.e. the template's list and item C's additions
together. Row = `<rel>|<oracle>|<merged>`, verdict `A:<md5-8 of the lowered IR>` or `D:<diagnostic>`,
both binaries on the SAME stage-1 file. `-P6`; each row has its own `mktemp -d`; the body is sorted
before it is written.

```
# corpus:     3127 files | oracle=fbbe0820ef4b176a merged=f7b65d8ccd7bc472
rows=3113   oracle_accepts=1519   merged_accepts=1598
DECLINE -> ACCEPT                                  = 79
decline-string moves (D -> a LATER, different D)   = 10
ACCEPT -> DECLINE                                  = 0
both-accept rows with a DIFFERENT lowered IR       = 0
(+ 3 D->D moves the string recipe cannot see, §0)
```

**The two zeros are the statement to read first**: not one module the ORACLE accepts stopped
compiling, and not one module both binaries accept emits a different circuit. All three landings are
accept-monotone by construction (M widens the condition grammar to a region-merge-φ rail leaf; R-1
only REMOVES a collider from F2; 21mg only adds a classical disposition to an operand class that
previously declined) — the sweep measures that the construction holds over 3113 modules.

⚠ **md5s are NOT comparable ACROSS sweeps** (the corpus lowers each module from a fresh `mktemp`
file, so `; ModuleID = …` differs per run and every accepting row's md5 moves). The md5 is meaningful
only WITHIN a row, where the ORACLE and the MERGED binary read the SAME stage-1 file. Nothing here is
compared against the implementer's or the fix's corpus by md5; the cross-sweep comparison is on
verdict class and diagnostic string only.

### The 79 DECLINE→ACCEPT, by ORACLE string

| # | ORACLE string | owner |
|---|---|---|
| **46** | `cq controlled lowering: control flow` | **Track M** (this landing) |
| **10** | `cq controlled lowering: state prep seed is proven equal to the condition register` | landing 2 (R-1) |
| **23** | (empty `D:` — the lossy render of `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle`) | landing 1 (21mg) |

Track M's 46 are its nine new ACCEPT fixtures; the owner's file and `vb`/`vc`; the eleven `m*`
probes the scope named plus `m13`/`m15`/`m16`; the twelve `r*` round-1 review probes (incl. `r03`,
the F-M1 customer, and `r22` at K=3 and K=1000); `q02`/`q03` from round 2; `i2_cmpladder`,
`a_two_selects` and `p3d8q_sibling` from the implementer's own set; the 2026-09-11 integration probes
`G6_quantum_mux_values.c` and `U1_owner_regfree_phi.c`; and **four cross-track probes nobody wrote
for Track M** — `trackL/probes/a_flat_n2.c` and `trackR/probes/v_vd_{guard_neg,no_b1_arm,two_regions}.c`.
Those four are the sweep earning its keep: they are other tracks' scoping probes that this landing's
grammar now compiles.

R-1's 10 and landing 1's 23 are the same populations their own merge records enumerate, re-measured
here on a binary that carries all three landings.

### The 10 visible decline-string moves — all DECLINE → a LATER, more specific fence

| # | from | to | owner |
|---|---|---|---|
| 6 | `control flow` | `condition predates a non-diagonal gate` (rung (iii) / gate 2c) | **M** — `p20.c`, `p20_from_boi6.c`, `r16_p20.c`, `r01_inplace_arm_bool.c`, and the two fixtures `…_chained_arm.ll` / `…_inplace_arm.ll` |
| 2 | `control flow` | `condition measured before the control route` (rung (ii)) | **M** — `m05.c` and its fixture `…_measure_before.ll` |
| 1 | F2's seed string | `control flow` | landing 2 — `R2_p80_window.c` |
| 1 | F2's seed string | `condition measured before the control route` | landing 2 — `R4_p80_measured.c` |

Every one is still a loud `DS_Error` at exit 1. The M rows are the increment's declared behaviour:
the leaf grammar no longer pre-empts at GATE 2, so the region is CLAIMED and then refused by the
fence that actually owns the hazard — which is what makes `control_swap_reject_select_mergephi_inplace_arm.ll`
(the round-2 review's graded OVER-DECLINE, with its bd `3d8q` retirement trigger) a meaningful pin
rather than a tautology.

**Every accepting mover re-lowered through STRICT stage 2b on the merged binary** —
`probes/merge/stage2b_movers_f7b65d8c.txt`, 79 rows, **0 violation(s), 0 unproven, 79/79**, no
`--allow-unproven` anywhere.

---

## §4 CUSTOMERS on the MERGED binary — the headline is that the owner's file compiles

Four-stage `PROTOCOL.md` pipeline per customer (`clang -O1 -g` → `cq-opt` → `free_pairing_check.py`
STRICT → link with `libcq_templates.a` BEFORE `libcq_runtime.a` → run), all on `f7b65d8ccd7bc472`
(`probes/merge/customers.sh`).

| customer | verdict | stage 2b (STRICT) | trace | against |
|---|---|---|---|---|
| **C1** `$SES/probes/owner_file_2026-09-13.c` | **ACCEPT, exit 0, stderr 0 bytes** | `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven` | **29 lines** | **BYTE-IDENTICAL** to `tests/e2e/slice_control_cascade_two_bools.expected.log`; **lines 1–16 BYTE-IDENTICAL to `probes/va.trace`** |
| `$SES/probes/va.c` | ACCEPT, exit 0 | `6 mints / 5 left allocated, 1 free: 1 verified, 0/0` | **19 lines** | **BYTE-IDENTICAL** to `probes/va.trace` |
| `$SES/probes/vb.c` | ACCEPT, exit 0 | `8/6, 2 free: 2 verified, 0/0` | **29 lines** | **BYTE-IDENTICAL to C1's trace** |
| `$SES/probes/vc.c` | ACCEPT, exit 0 | `8/6, 2 free: 2 verified, 0/0` | **29 lines** | **BYTE-IDENTICAL to C1's trace** |
| **C2** `$SES/probes/vd.c` | **DECLINE, exit 1** | — | — | `vd.c:10:14: … cq controlled lowering: state prep seed is proven equal to the condition register under quantum control` — F2, as scoped (R-2 is an owner ruling, not folded in) |
| **C2′** `$SES/trackR/probes/v_vd_guard_neg.c` | **ACCEPT, exit 0** | `11 mints / 8 left allocated, 3 free: 3 verified, 0/0` | **42 lines** | the same program with the third region's guard written `a >= -5`, so the downstream compare cannot be pinned FALSE — M + R-1 together compile it |
| `$SES/trackM/probes/m16.c` (run-time `a`) | ACCEPT | `8/6, 3 free: 3 verified, 0/0` | **31 lines** | as the fix recorded |
| `$SES/trackM/probes/impl/i2_cmpladder.c` | ACCEPT | `6/5, 2 free: 2 verified, 0/0` | **21 lines** | as the fix recorded |
| `$SES/trackR/probes/b_A_intb0_boolb1.c` (landing 2's customer) | ACCEPT | `5/5, 2 free: 2 verified, 0/0` | **22 lines** | **BYTE-IDENTICAL** to `tests/e2e/slice_control_stateprep_bool_under_int_compare_fused.expected.log` |
| `$SES/trackC/probes/owner_2026-09-11_2218.c` (landing 1's customer) | ACCEPT | `5/4, 1 free: 1 verified, 0/0` | **15 lines** | **BYTE-IDENTICAL** to `tests/e2e/slice_measure_classical_bool.expected.log` |
| `review_integration_probes/G6_quantum_mux_values.c` | ACCEPT | `6/5, 3 free: 3 verified, 0/0` | **26 lines** | as the brief predicts |
| `$SES/probes/ve.c` | DECLINE, exit 1 | — | — | `ve.c:7:26: … cq taint escape: tainted value stored to memory` — unchanged, out of scope |

**C1's emitted stream, and the one invariant to read it by** (`h0` = `b0`, `h1` = `b1`):

```
alloc_i1(0)->h0; ry_i1(h0,.5)
alloc_i1(0)->h1; ry_i1(h1,.5); ry_i1_controlled(h0,h1,-.5)
alloc_i1(0)->h2; cnot(h0,h2); alloc_i32(0)->h3;
  alloc_i32(2)->h4; copy_i32_controlled(h2,h4,h3); x(h2);
  alloc_i32(5)->h5; copy_i32_controlled(h2,h5,h3); x(h2); cnot(h0,h2); free(h2)
add_i32_hl(h3,-3)->h6
alloc_i1(0)->h7; cnot(h1,h7); alloc_i32(0)->h8;
  copy_i32_controlled(h7,h6,h8); x(h7); copy_i32_controlled(h7,h3,h8); x(h7); cnot(h1,h7); free(h7)
measure_i1(h0); measure_i1(h1); measure_i32(h8)
```

`h0` and `h1` are USER registers: read only as controls, never `cqrt_x`-bracketed, never freed
(`Ry(θ)|0⟩ ≠ |0⟩`, Rule 6). The two `cqrt_x` pairs are on the CNOT-copy ancillas `h2` and `h7`, each
of which returns to `x ⊕ x = 0` before its free — so both frees are proven-`|0⟩` ones, which is what
stage 2b's `2 verified` records. The first 16 lines are the 2026-09-11 landing's stream unchanged;
the 13 new lines are the second merge-φ select, the construct this increment exists for.

---

## §5 GATES, verbatim

```
build (cmake -S . -B build -DLLVM_DIR=… -DCMAKE_BUILD_TYPE=Release; cmake --build build -j8, BOTH targets,
       after the merge + items A)
  cq-opt       f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc
  libCQPass.so f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d
  52.511 s wall; 4 warnings, ALL pre-existing and in files no track touched
  (RegionTreeDetect.cpp:173/174 -Wunused-variable, TaintPropagation.cpp:255/1988 -Wunused-parameter);
  no new warning

FULL ctest --test-dir build -j6 --output-on-failure      (ONCE, this landing's only full run)
  100% tests passed, 0 tests failed out of 420
  Total Test time (real) = 388.40 sec        [wall 6:28.47; quiet box, no other agent gating]
  ir-pass-lit Passed 62.00 sec · frontend-lit Passed 9.44 sec ·
  e2e-loop-twin-matrix Passed 214.33 sec (the long pole, as CLAUDE.md says) ·
  e2e-free-pairing-selftest Passed 0.55 sec · e2e-loop-twin-quarantine-selftest Passed 0.27 sec ·
  e2e-census-slice-sync Passed 0.12 sec
  NO failure, so nothing had to be re-run serially.

cmake --build build --target cq-opt-equivalence-full     (OWED: decline strings moved AND analysis
                                                          sites changed in SelectClassify + the hcrg graph)
  cq_opt_equivalence: compared 1928 fixtures, 0 mismatch(es)      93.13 s

corpus sweep ORACLE-vs-MERGED     rows=3113, 79 DECLINE->ACCEPT, 10 decline-string moves,
                                  0 ACCEPT->DECLINE, 0 both-accept md5 differences
decline-side full-stderr delta    1593 rows, 92 differ, 3 invisible to the string recipe (all landing 1's)
stage 2b over the 79 accepting movers   0 violation(s), 0 unproven, 79/79
duplicate-body fixture scan       files=1928, same-body groups=9, 0 merge artefacts
rz mutation matrix (F2-1)         4 mutants, 4 caught (was 0 caught); unmutated control still green
negative coverage (F2-3)          11 fixtures, 0 gaps; vacuity 84 named negatives, 0 VACUOUS
lit --filter 'mergephi|rail_after_prep'   20/20 PASS
```

---

## §6 COUNTS, by command

| command | `e96f89c` | after landing 2 (`main` e625f30) | **merged (landing 3)** |
|---|---|---|---|
| `ls ir-pass/test/*.ll \| wc -l` | 1893 | 1908 | **1928** (+20: 11 accepts, 9 declines) |
| `ls tests/e2e/*.expected.log \| wc -l` | 355 | 361 | **367** (+6) |
| `ctest --test-dir build -N \| tail -1` | 403 | 411 | **420** (+9) |
| `ctest -N -R '^e2e-'` | 393 | 401 | **410** |
| `ctest -N -R '^e2e-slice-'` | 353 | 359 | **365** (+6) |
| `ctest -N -R twin-identical` | 30 | 32 | **34** (+2: `cascade-two-bools-twin-identical`, `cascade-select-in-loop-twin-identical`; the third new CMake gate is `cascade-two-bools-base-prefix-identical`, a PREFIX gate, deliberately not a twin) |
| `grep -c '^add_test' tests/e2e/CMakeLists.txt` | — | 401 | **410** |
| twin matrix cells (`grep -c '^m_'` + `grep -c '^cell '`) | 288 | 288 | **259 + 29 = 288** (unchanged — Track M ships no in-loop *lowering* change; its in-loop slice is a twin-identical pair, not a matrix cell) |
| `cq-opt-equivalence-full` | 1893/0 | 1908/0 | **1928/0** |

---

## §7 WHAT I DID NOT DO

* **No squash, no push, no bd write.** The squash message is the orchestrator's; the gated tree is
  **`54079b6`** and the tip to cite is this record's own commit on top of it.
* **Nothing outside this worktree was written.** The ORACLE checkout was only ever *read* (its two
  binaries re-hashed before first use, then executed); it was never built and never written.
* **No second full suite**, and no full suite before the merge — `PROTOCOL.md`'s merge-and-gate row
  allows exactly one, and it ran on the MERGED tree so it covers all three landings' code together.
  No other measurement was in flight while it ran (no relink under a running measurement, no `pkill`).
* **No injection matrix.** It is the implementation row's gate, and `87 applied / 0 MISSED / 1 N/A @
  0d3105d0` is a fact about the PRE-merge binary — *not* re-run and *not* cited as a fact about
  `f7b65d8c`, because the hash moved. What I did run on the merged binary is the review's own
  `rz_mutation.sh` (the mutation the matrix did not contain), the vacuity instrument and
  `negcoverage.py`; the accept fixtures themselves are covered by `ir-pass-lit` inside the full run
  and their streams' md5s are in the corpus.
* **No twin-matrix run of my own** — `e2e-loop-twin-matrix` ran inside the full suite (214.33 s,
  Passed), which is the only instrument that can see a leaked TEMPLATE-minted rail.
* **I did not re-open the round-2 review's verdict or re-derive its unitaries.** F2-4 (the
  pre-existing over-declines `q01`/`q04`/`q05`/`q06`/`q07`) is **not filed**: a merge worktree does
  not open issues. It belongs to the orchestrator's session close, along with the round-2 review's
  graded OVER-DECLINE on `p20`/F-M3 and the bd `3d8q` customer growth `GATES.md` records.
* **I did not touch any pass predicate.** Item A2 is the only `ir-pass/src` edit in this landing's
  own commits and it is mechanically comment-only (§0 question 1).
