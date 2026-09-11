# MERGE_l4x4_1 — `l4x4b-bool-ry-arm` × `main` 3a3a2b9 (Track A.1 + b6ap), FIRST pass

Merge record, 2026-09-11. Worktree `/Users/sorenwilkening/Desktop/CQ_l4x4`, branch
`l4x4b-bool-ry-arm` at the round-1 checkpoint **1f6c582**, merged with **`main` 3a3a2b9**
(= A.1 `compare-select-parity` landed 7203d1c, + b6ap `merge-phi-peel` landed 3a3a2b9).
**Merge base 0c7380c.** Not pushed. The branch is based on the Track-C **F2 checkpoint
578dbc4**, which is NOT yet on `main`, so this branch still CARRIES F2 — a SECOND merge
follows once F2 lands (`LANDING_PLAN.md` step 4).

Three binaries are named below and none of them is a live build tree:

* **ORACLE** — `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` at `main`
  0c7380c, read-only, untouched.
* **PRE** — the pre-merge checkpoint 1f6c582, rebuilt from `git archive 1f6c582 | tar -x`
  into `scratchpad/l4x4merge/pre` and configured/built there. Nothing under any worktree
  was stashed, rebuilt or restored to obtain it (the `IMPL_f2` §5b lesson: never A/B
  against a tree somebody may relink under you).
* **MERGED** — this worktree after the merge, BOTH targets built.

---

## 1. CONFLICTS — one, resolved by keeping both sides

`git merge main` reported **exactly one** content conflict; `ArmClassify.cpp`,
`TaintPropagation.h`, `CQLoweringPass.cpp` and `tests/e2e/CMakeLists.txt` auto-merged
(each side's hunks are in disjoint regions) and were then verified by hand, below.

| file | hunk | resolution | reason |
|---|---|---|---|
| `ir-pass/src/SwapRouteEmit.cpp` :776-799 (`emitInPlaceRotationRegion` step 1, the flag mint) | HEAD = l4x4.b's `Flag = RailCond ? Cond : lowerCompareToFlag(cast<CmpInst>(Cond), …)`; MAIN = A.1's `lowerCompareToFlag(Cond, …, readKind=CondReadKind::WireRuled)` | **BOTH**: the ternary is kept and the COMPARE limb gains `readKind=CondReadKind::WireRuled`; both comment blocks are kept and a third `⚠ MERGE` paragraph records the reasoning | the two sides change DIFFERENT things about the same statement — one adds a second species of condition, the other adds an argument to the mint. Taking either wholesale loses a fence: main's alone re-declines every rail, HEAD's alone drops A.1's rung-(iii) exemption bit and would silently re-open the `io3`/`gs1` class at this consumer |

### The question the merge had to answer, written down rather than left implicit

**For a RAIL flag nothing is minted, so what does the `CmpCondRead` record do there?**
**Nothing — and that is correct, not a hole.** Three facts, each checked in the merged
source rather than argued:

1. A.1 writes the compare record INSIDE `lowerCompareToFlag` (`CompareLowering.cpp`), the
   one compare-flag mint. The rail limb of the ternary never calls it, so no entry exists.
2. `reverifyCmpCondReads` (`ArmClassify.cpp:2515`) opens with
   `if (Taint.CmpCondReads.empty()) return false;` and is a `for (const auto &E :
   Taint.CmpCondReads)` loop. It never enumerates REGIONS and cannot miss one: an absent
   entry is a region whose condition was never a compare, not an unasked question.
3. The rail's own obligation is recorded on the rail side and re-asked by the rail twin:
   `markRailCondRead(taint, Flag, …)` fires at BOTH limbs of l4x4.b's step-2 loop (the
   negated `TNeg` and the un-negated `G.first`), and `reverifyRailCondReads`
   (`ArmClassify.cpp:2394`) re-asks rungs (ii)+(iii) at FINAL taint. Its own header now
   carries A.1's "(Track A.1) UNCHANGED — the compare seeds live in their own record"
   note, so the split is documented at both ends.

MEASURED, not assumed: the three round-2-window two-TU probes that exist precisely to
falsify this (`probes/impl/multi/w2`, `w3`, and the reviewer's `multi/w4`/`w5`/`w6`) all
still decline through `reverifyRailCondReads` on the MERGED binary, unchanged from the
checkpoint (§3).

### The mint-site enumeration survived the merge

A.1's F-A1R2-1 table is "11 forward sites, every one with an explicit `readKind`; 8
inverse, none". Re-derived on the merged tree by grep: every forward
`lowerCompareToFlag` call carries an explicit `readKind` (`AbortParkEmit:387` Unruled,
`ClassicalCallArmEmit:202` Unruled, `AngleSelectEmit:189`/`:514` WireRuled,
`CondTreeEmit:205` per-leaf, `CompareLowering:524` NotAControlRead, `IOSinkLowering:706`
Unruled, `GuardedStoreArmEmit:266` Unruled, `Specialization:219` Unruled,
`SwapRouteEmit:800` **WireRuled — this merge's line**, `SwapRouteEmit:1375` WireRuled,
`SwapRouteEmit:1896` WireRuled), and every inverse call still passes none. The merge
added no mint and removed none.

### The auto-merged files, verified by hand

* `ir-pass/src/ArmClassify.cpp` — `git diff main -- ArmClassify.cpp` removes only lines
  this branch is ENTITLED to remove: l4x4.b's own replaced gate (`if
  (!isa<CmpInst>(Region.Condition)) … kBareRailCondReason`), the `HasDataUse` loop it
  guards behind `!RailCond` (H-4), the `condWireDisposition` call it replaces with the
  `RailCond ? railCondWireDisposition : condWireDisposition` ternary, and **F2's**
  narrowing hunks (`f2Exact`, the plain-literal fast path) which are on this branch and
  not yet on `main`. Every A.1 addition (`markCmpCondRead`, `reverifyCmpCondReads`,
  `condCmpMeasuredBeforeReadPoint`, `condCmpOperandSeeds`, the `WireRuled` gate at the
  rung-(iii) call site) is present.
* `ir-pass/include/TaintPropagation.h` — the only line the merge removes from `main` is
  the raw-pointer spelling of `ControlledRotations`, replaced by l4x4.b's
  `WeakTrackingVH` mapped type (hazard H-1). A.1's `CmpCondRead` / `WireRuled` members
  are untouched.
* `ir-pass/src/CQLoweringPass.cpp`, `tests/e2e/CMakeLists.txt` — auto-merged with no
  deletion from either side; the four l4x4.b e2e groups and A.1/b6ap's registrations all
  present (`ctest -N` = 403).

`railMeasuredBeforeReadPoint` / `railWireNamesBackward` were WIDENED by A.1 from
`const CallInst *` to `const Value *`. l4x4.b's rail-ladder callers pass a `CallInst *`
and bind unchanged; no call site needed editing, and the widening cannot narrow the rail
closure (the body already breaks at the first non-`cq_theta_` name).

---

## 2. THE ONE FIXTURE THAT MOVED — an ACCEPT its own header predicted in writing

`ir-pass/test/control_peel_reject_stateprep_rail.ll` went RED. It is b6ap's fixture for
*the owner's file with `int b1`*, and its header says: **"⚠ ITS HEADER SAYS SO ON
PURPOSE, THE Inc-1b PRECEDENT: this fixture FLIPS TO AN ACCEPT when bd `l4x4` lands."**
This merge is the first binary carrying both, so it flipped.

Disposition, the Inc-1b `control_phase_kickback_reject_bare_i1.ll` precedent: `git mv`'d
to **`control_peel_stateprep_rail.ll`** and rewritten as the ACCEPT, with the flip, the
three dispositions and the stream reading in the header. NOT deleted; the rename does not
hide anything.

Three dispositions of one module, all measured:

| binary | verdict |
|---|---|
| ORACLE `main` 0c7380c | DECLINE `control flow` (the 2-phi wall) |
| b6ap alone (what the fixture pinned on `main` 3a3a2b9) | DECLINE `bare i1 register condition` |
| **MERGED** | **ACCEPT**, 19 gate lines, stage 2b `1 verified, 0 violation(s), 0 unproven` |

The emitted stream, read against the source (this is the whole reason the flip is a
capability and not a regression):

```
%h  = cqrt_alloc_i1(false); cqrt_ry_i1(%h, 0.5)                 ; b0
%h2 = cqrt_alloc_i32(0); cqrt_ry_i32(%h2, 0.5)
                          cqrt_ry_i32_controlled(%h, %h2, -0.5) ; the NEGATED prep
%bf = cqrt_alloc_i1(false); cqrt_cnot(%h, %bf)                  ; the rail-root CNOT copy
%out= cqrt_alloc_i32(0)
%selop  = cqrt_alloc_i32(2); cqrt_copy_i32_controlled(%bf,%selop ,%out); cqrt_x(%bf)
%selop1 = cqrt_alloc_i32(5); cqrt_copy_i32_controlled(%bf,%selop1,%out); cqrt_x(%bf)
cqrt_cnot(%h, %bf); cqrt_free(%bf)                              ; %bf back to |0>
cqrt_measure_i1(%h); cqrt_measure_i32(%h2); cqrt_measure_i32(%out)
```

* the arm is on the FALSE edge (`br i1 %1, label %merge, label %arm`), so l4x4.b spells it
  as ANTI-CONTROL BY Ry ADDITIVITY: `b0 = 1` ⇒ `Ry(θ)Ry(−θ) = I` ⇒ the seed `0`, which is
  the `[0, %entry]` incoming; `b0 = 0` ⇒ `Ry(θ)|0⟩`, the prep. Correct on both branches.
* the peeled `a` mux: `bf = 1` copies `2` (the `%entry` incoming, `b0 == 1`), `¬bf` copies
  `5` (the arm incoming, `b0 == 0`). Correct on both branches.
* `%h` is never `cqrt_x`-bracketed and never freed — Inc 1b's invariant and Rule 6. The two
  `cqrt_x` sit on the ANCILLA `%bf`, between the two controlled copies.

The fixture carries an ordered `CHECK` stream plus eight pure-negative / exact-count
prefixes (`XCNT` 2, `FCNT` 1, `ACNT` 6, `CNCNT` 2, `CPCNT` 2, `RYCNT` 3, `MCNT` 3, and a
`NOROUTE` block whose two load-bearing members are `cq_template_icmp` — a rail condition
mints NO flag — and `cqrt_cswap`).

---

## 3. PROBE CORPORA — PRE (1f6c582) vs MERGED, every corpus, every row

`scratchpad/l4x4merge/ab.sh <dir>` lowers each probe with BOTH binaries and compares
**exit code, diagnostic string, and — for an accept — the md5 of the lowered IR**, so an
unchanged verdict over a CHANGED circuit still reads as a mover. Two-TU probes are
`llvm-link`ed exactly as their own runners do.

| corpus | rows | movers |
|---|---|---|
| `session-l4x4/probes` (the SCOPE `t*` grid) | 35 | **0** |
| `session-l4x4/probes/impl` | 19 | **1** — `V0_owner_file_2026-09-11` |
| `session-l4x4/review_l4x4b_r1_probes` | 45 | **2** — `r03_b_zext_data`, `u01_borrow_before` |
| `session-l4x4/fix_l4x4b_r1_probes` | 10 | **0** |
| `session-9pum/probes` (Track A.1's) | 20 | **8** |
| `session-b6ap/probes` | 75 | **31** |

**Every mover is attributable, and every one is a landed track's own recorded effect.**

* **l4x4's own three.** `V0` is the owner's file — `control flow` → **ACCEPT** (§4).
  `r03`/`u01` are recorded in `review_l4x4b_r1.md:360` as declining for *"multi-φ regions
  — bd `b6ap`"*; b6ap landed, so they lower. Both verified: stage 2b `2 verified, 0
  violation(s), 0 unproven`, and both streams are the expected prep + CNOT-copy-select
  composition with no `cqrt_x` on a user register.
* **The 9pum eight** (`r10v`, `r903b`, `9pum`(2TU), `d1`–`d4`, `sw2.ll`) are all
  ACCEPT → DECLINE on A.1's two strings, and every one matches
  `session-9pum/probes/README.md`'s SUBJECT column character-for-character. These are the
  three plain-C silent miscompiles A.1 closes plus the `lo7u` switch row. PRE has no A.1,
  so PRE behaves as the ORACLE there, exactly as that README records.
* **The b6ap thirty-one** are all `control flow` → (accept | a LATER fence): the peel
  removing the multi-φ bookkeeping over-decline. Four land on a later DECLINE rather than
  an accept and each is a Prime-Directive-safe direction: `p85_v8int` →
  `condition predates a non-diagonal gate` (its arm rotates the condition register),
  `p86`/`p87` → `state prep seed is proven equal to the condition register` (F2's fence,
  which rides on this branch), `S02_stale_mux_record` → `operand predates a non-diagonal
  gate`, which is the string b6ap's own README records for it.
* The accepting b6ap/bool movers were each re-lowered and checked: `p00`, `p01`, `p20`,
  `p21`, `p40`, `w02`, all stage 2b `0 violation(s), 0 unproven`, all with exactly one
  `cqrt_free` per CNOT-copy ancilla and no `cqrt_cswap`.

**0 movers in the three corpora that are l4x4.b's own subject matter** (the `t*` grid, the
F-1 fix grid, and 42 of the 45 reviewer probes) is the merge's main negative result: A.1's
fences and b6ap's peel do not move the rail in-place-Ry / state-prep class anywhere.

---

## 4. THE OWNER'S FILE, AS WRITTEN — it compiles

`scratchpad/owner_file_2026-09-11.c` (= `example/grover/grover_oracle_uncompute.c`), NO
edits, `clang -O1` + the MERGED `cq-opt`:

```
opt exit code : 0
stderr        : (empty — not one byte, no warning)
stage 2b      : 6 rail mint(s) of which 5 left allocated, 1 cqrt_free site(s):
                1 verified, 0 violation(s), 0 unproven
link + run    : ok
```

Trace (19 lines):

```
 1  cqrt_alloc_i1(0) -> h0
 2  cqrt_ry_i1(h0, 0x1p-1)
 3  cqrt_alloc_i1(0) -> h1
 4  cqrt_ry_i1(h1, 0x1p-1)
 5  cqrt_ry_i1_controlled(h0, h1, -0x1p-1)
 6  cqrt_alloc_i1(0) -> h2
 7  cqrt_cnot(h0, h2)
 8  cqrt_alloc_i32(0) -> h3
 9  cqrt_alloc_i32(2) -> h4
10  cqrt_copy_i32_controlled(h2, h4, h3)
11  cqrt_x(h2)
12  cqrt_alloc_i32(5) -> h5
13  cqrt_copy_i32_controlled(h2, h5, h3)
14  cqrt_x(h2)
15  cqrt_cnot(h0, h2)
16  cqrt_free(h2)
17  cqrt_measure_i1(h0) -> 0
18  cqrt_measure_i1(h1) -> 0
19  cqrt_measure_i32(h3) -> 0
```

Line by line against the source:

* `if (a >= 3) b0 = cq_theta(b0, 0.5);` — `a` is the literal 5, so the guard folds away at
  `-O1` and the prep is unconditional: **lines 1–2**, `h0` = `Ry(0.5)|0⟩`.
* `if (a >= 3) b1 = cq_theta(b1, 0.5);` — after the mux `a` is 5 iff `b0 == 0`, so `-O1`
  proves this guard equivalent to `b0 == 0` and FUSES the two source regions into ONE
  diamond whose arm defines `b1` and whose merge carries the `a` phi as well. The arm is
  on the FALSE edge, so l4x4.b emits the negated form: **lines 3–5**,
  `Ry(+0.5)` then `Ry(−0.5)` controlled on `h0`. `b0 = 1` ⇒ identity ⇒ `b1 = |0⟩` =
  `false`; `b0 = 0` ⇒ `Ry(0.5)|0⟩` = the prep. `−θ` is an IEEE sign flip, not an `fsub`.
* `if (b0 == 1) a -= 3;` — b6ap PEELS this merge phi into a `select`, which the 4.4
  `SelectMergeEmit` lowers with r9e5's rail-root CNOT copy: **lines 6–16**. `h2` is a
  fresh `|0⟩` ancilla holding a basis copy of `h0`; `h2 = 1` (i.e. `b0 == 1`) copies `2`
  into `h3`, `¬h2` copies `5`; the second `cqrt_cnot` returns `h2` to `x ⊕ x = 0` and the
  `cqrt_free` is a proven-`|0⟩` free (Rule 6, and stage 2b says `1 verified`).
* `return cq_measure(b0) + cq_measure(b1) + cq_measure(a);` — **lines 17–19**, in that
  order, summed as `(m(b1) + m(b0)) + m(a)`, matching the stage-1 `add` order.

**`h0` is read four times as a CONTROL (lines 5, 7, 15) and measured once (17); it is
never `cqrt_x`-bracketed and never freed.** That is Inc 1b's invariant and Rule 6's
required direction — `Ry(0.5)|0⟩ ≠ |0⟩`, so a free would be a hidden measurement. The two
`cqrt_x` are on the ancilla `h2`.

### The one ordering observation — NOT a finding, with the argument

The orchestrator's predicted stream was *b0 prep; the peeled a-mux; the negated b1 prep;
measures*. The emitted order is **b0 prep; the negated b1 prep; the a-mux; measures** —
the last two swapped relative to SOURCE order. It is the same unitary, exactly:

* the b1 prep is `U = |0⟩⟨0|_{h0} ⊗ I + |1⟩⟨1|_{h0} ⊗ Ry(−0.5)_{h1}` (plus an
  unconditional `Ry` on `h1` alone);
* the whole mux block `V` touches `h0` only through `cqrt_cnot(h0, h2)`, where `h0` is the
  CONTROL, so `V = Σ_x |x⟩⟨x|_{h0} ⊗ V_x` on `(h2,h3,h4,h5)`;
* both are block-diagonal in `h0`'s computational basis and act on DISJOINT targets
  (`h1` vs `h2,h3,h4,h5`), so `[U, V] = 0`.

It is also STRUCTURAL rather than a choice: `-O1` fused the two source regions, so there
is no source order left in the IR between them — the arm's `cq_theta` is hoisted into the
pred (which strictly precedes the merge block), and the peeled select lives at the merge.

---

## 5. GATES (Rule 19) — LIGHT set, per the merge brief; the FULL suite is owed after the second merge

| gate | command | result |
|---|---|---|
| build | `cmake --build build -j8` | both targets (`CQPass` **and** `cq-opt`) linked, 0 errors; the 2 `-Wunused-parameter` warnings are pre-existing on `main` |
| lit (first run, pre-fixture) | `ctest --test-dir build -R ir-pass-lit --output-on-failure` | **1 failed** — `control_peel_reject_stateprep_rail.ll`, §2 |
| lit (after §2) | `ctest --test-dir build -R ir-pass-lit --output-on-failure` | **Passed, 57.17 s, 0 failed** (1893 discovered, 1 XFAIL) |
| targeted e2e | `ctest --test-dir build -j6 -R 'inplace_ry_bool\|inplace-ry-bool\|stateprep\|fused\|select-cmp\|select_cmp\|iterlocal' --output-on-failure` | **19/19 passed, 20.07 s** |
| e2e slices | `ctest --test-dir build -j6 -R '^e2e-slice-' --output-on-failure` | **100% tests passed, 0 tests failed out of 353**, 158.79 s |
| equivalence (sampled) | `ctest --test-dir build -R 'cq-opt-equivalence'` | **Passed, 15.51 s** |
| goldens | `git status --porcelain tests/` | no golden modified; the only `tests/` change is the branch's own pre-merge additions |
| stage 2b | `tools/free_pairing_check.py` on the owner's file and on all 8 accepting movers | `0 violation(s), 0 unproven` everywhere |

Counts, by command:

```
ls ir-pass/test/*.ll | wc -l          -> 1893
ls tests/e2e/*.expected.log | wc -l   ->  355
ctest --test-dir build -N | tail -1   ->  Total Tests: 403
```

(`main` 3a3a2b9 is 1851 / 347 / 394; the deltas are this branch's F2 + l4x4.b fixtures and
the four l4x4.b e2e groups, plus the §2 rename which is not an addition.)

---

## 6. WHAT THE SECOND MERGE STILL OWES

1. **F2 is still carried on this branch, not on `main`.** Re-merge once Track C lands; the
   `ArmClassify.cpp` F2 hunks that read as "removals vs main" today should then merge
   trivially or become no-ops.
2. **The FULL `ctest -j6`** and `cq-opt-equivalence-full` are owed on the final tree
   (Rule 19 gate moments 1, 2 and 5 — a Rule-13-core change, a merge, and an accept/decline
   predicate moved). `e2e-loop-twin-matrix` is the long pole and has not been run here.
3. **`control_peel_stateprep_rail.ll` should be re-verified RED on `main`** at squash time
   (it is measured RED on the ORACLE here, `control flow`; the b6ap-only disposition
   `bare i1 register condition` is the fixture's own recorded history, not a fresh
   measurement of mine).
4. **CLAUDE.md / PRD status paragraphs** are the orchestrator's at squash; this merge wrote
   none.
