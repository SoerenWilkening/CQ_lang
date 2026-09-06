# fix_eqpx — IMPLEMENTER progress (bd test_C_libtooling-eqpx, P1 consumer tripwire)

Worktree `$SP/wt/eqpx`, branch `eqpx-fix` (base `main` 0b402d6). Work dir
`$SP/progress/fix_eqpx_work/` (`W=`). Frozen pre-fix baseline binary
`$SP/bin/main-16b15b3/{cq-opt,libCQPass.so,libcq_*.a}`.

## 2026-09-06 step 0 — build + harness controlled  [DONE]
* `tail -1 $SP/progress/orch_wt_eqpx_build.log` -> `BUILD_EXIT=0`.
* `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` in `$SP/wt/eqpx` -> EMPTY.
* Harness copied to `$W/run.sh`, reproducers to `$W/p/`. CONTROLS (measured):
  * `W=$W $W/run.sh $W/p/ctlA_clean_xor_const.c fix`  -> `ACCEPT ctlA_clean_xor_const fix 2b=0 lines=9 imm=0 run=0`
  * `... c1c_m_xor_and_noregion.c fix + tu_extf.c`     -> `ACCEPT c1c_m_xor_and_noregion fix 2b=0 lines=21 imm=1 run=0`  (THE RED)
  * same two on `main` -> identical (`lines=9 imm=0`, `lines=21 imm=1`).
* Source read: investigate_eqpx.md whole; `OpcodeLowering.cpp:200-345,410-460`;
  `ArithLowering.cpp:300-370,600-700`; `LoopLowering.cpp:130-215,1520-1575,1680-1710,2260-2290,2655-2690,3060-3095,3395-3425`;
  `TaintPropagation.h:355-410`; fixture `control_phase_kickback_reject_preloop_commit_stale.ll`.
* Line numbers RE-VERIFIED on THIS tree (0b402d6): `grep -rn 'InPlaceRailOps.insert(' ir-pass/src`
  -> `LoopLowering.cpp:1698` (W1 `emitBreakForward`), `:2281` (W2 `tryCaseA` ACCEPT),
  `:2679` (W3 `collapseRailPhisIn` step (3)), **`:3084`** (W4 `commitOutOfLoopInPlaceOps` —
  the investigation says `:2972`, which was 258d974; on this tree it is `:3084`).
  Rollback `:3411`. `inPlaceValueRailOperand` def `LoopLowering.cpp:143`, decl `LoopPlan.h:332`.
  `OpcodeLowering.cpp` does NOT `#include "LoopPlan.h"` today (verified).
* DECIDED, with the measurement: the new block will **not** carry the `!inBennettClone`
  conjunct the (1b) block has. Reason: the Phase-2 dispatch (`OpcodeLowering.cpp:428`)
  honours `InPlaceRailOps` UNCONDITIONALLY, so gating the tripwire on it would leave a
  hole exactly where the dispatch has none. It is INERT either way — `SpecializeSeed.h:5`
  says `seedClone` builds a FRESH `TaintSet`, and clones are created at
  `CQLoweringPass.cpp:~526`, long after `lowerLoops` (`:363`), so no clone instruction
  can ever be in `taint.InPlaceRailOps`.

## 2026-09-06 step 1 — RED first (Rule 12)  [DONE]
* 43-program census on `main` (frozen 16b15b3): `$W/census_main.txt`. Matches
  `investigate_eqpx.md` §4 exactly. 18 programs carry the signature (imm>=1):
  `a1 a2 a3 c1c_m_xor_add1 c1c_m_xor_and c1c_m_xor_and_noregion c1c_m_xor_mul n04
  n05 n06 n08 n15 n16 n19 n20 n21 hand_add_from_xor hand_xor_commuted`.
* **16 fixtures written** (8 DECLINE + 8 ACCEPT-CONTROL; the brief's 15 counted
  `n09`/`n10` and `n02`/`n03` as 2 groups — I ship one fixture per program):
  * declines `ir-pass/test/lowering_reject_inplace_rail_stale_{w2_xor_derived,
    w2_xor_bareout,w2_add_derived,w3_xor_derived,w3_add_derived,w1_xor_derived,
    w1_xor_bareout,w2_xor_commuted_handir}.ll`
  * accepts `ir-pass/test/lowering_inplace_rail_{ctlA_const_imm,k01_arg_imm_xor,
    k02_arg_imm_add,k03_volatile_imm,n09_w4_preheader,n02_select_merge,
    n03_value_merge,z36_inregion_add}_accept.ll`
  Bodies are each reproducer's own `clang -O1` stage-1 module with `@main`
  stripped (`$W/strip_main.py`), `!llvm.loop` + `!dbg` VERBATIM; the two-TU ones
  are already `llvm-link`ed. Stripping `@main` did NOT change any disposition
  (re-measured below).
* **RED, per decline fixture, on the FROZEN `main`@16b15b3 binary**
  (`$MB/cq-opt -load-pass-plugin $MB/libCQPass.so -passes=cq-lowering -S <f> | immcheck.py`):
  | fixture body | rc | railInImm | the emitted gate |
  |---|---|---|---|
  | w2_xor_derived (`c1c_m_xor_and_noregion`) | 0 | **1** | `cqrt_xorc_i32(%h2, %h_op)`, `%h_op = cq_template_and_i32_hl` |
  | w2_xor_bareout (`n04`) | 0 | **1** | `cqrt_xorc_i32(%h2, %out)`, `%out = cqrt_alloc_i32` |
  | w2_add_derived (`a1`) | 0 | **1** | `cqrt_addc_i32(%h2, %h_op)` |
  | w3_xor_derived (`c1c_m_xor_and`) | 0 | **1** | `cqrt_xorc_i32(%h3, %h_op)` |
  | w3_add_derived (`n08`) | 0 | **1** | `cqrt_addc_i32(%h3, %h_op)` |
  | w1_xor_derived (`n15`) | 0 | **2** | `cqrt_xorc_i32(%h2, %h_op)` x2 (forward + reverse-play) |
  | w1_xor_bareout (`n16`) | 0 | **2** | `cqrt_xorc_i32(%h2, %out)` x2 |
  | w2_xor_commuted_handir | 0 | **1** | `cqrt_xorc_i32(%h_op, %h2)` — WRONG REGISTER |
  All 8 accept controls: rc 0, `railInImm=0`.
* **`lit ir-pass/test --filter 'inplace_rail'` on the PRE-FIX build**:
  `1707 discovered / 16 selected / 8 Passed / 8 Failed` — the 8 Failed are EXACTLY
  the 8 declines. That is the RED.

## 2026-09-06 step 2 — the fix (2a minimal + 2b stronger form)  [DONE, both shipped]
Commit `15196f3` on `eqpx-fix` (RED baseline `360f7c3`).
`git diff --stat 360f7c3 15196f3 -- ir-pass/src ir-pass/include`:
`TaintPropagation.h +25 · ArithLowering.cpp +15 · LoopLowering.cpp +43/-4 ·
OpcodeLowering.cpp +122` — NOTHING in `runtime/`, `tools/opcode_table.yaml`,
`include/`. No new `cqrt_*` / `cq_template_*` symbol (owner D3).
* **2a** `OpcodeLowering.cpp`: `#include "LoopPlan.h"`, a `diagnoseRailOpStale`
  beside `diagnosePreLoopCommitStale`, and the Phase-1 block immediately after the
  (1b) block and before M-C. It re-asks **G2 ALONE**
  (`inPlaceValueRailOperand(BO, taint)`) under FINAL taint for every
  `taint.InPlaceRailOps` member NOT in `PreLoopCommittedInPlaceOps`, and
  `continue`s after the loud
  `cq loop lowering: in-place rail op no longer provable at lowering`.
  ~75 lines of that diff are the Rule-0 comment (what it re-asks and why not the
  full fence — G5; whom it serves, W1-W3 by name and line; what moves the answer,
  E1 at `:376` and E2 at `:409`; the four licences that forbid a silent
  out-of-place fallback; the 8h7d.5 decline-only answer).
  **NOT gated on `!inBennettClone`** unlike (1b): the Phase-2 dispatch honours the
  marking unconditionally, so gating would leave a hole where the dispatch has
  none. Inert either way (`seedClone` builds a FRESH `TaintSet`; clones are built
  long after `lowerLoops`) — and measured inert (0 fixture/golden movement).
* **2b SHIPPED** (~40 lines total, and it moved NO accept control):
  `TaintSet::InPlaceRailIdx` (`DenseMap<Instruction*, unsigned>`, an INDEX never a
  `Value *`), written by ONE new helper `LoopLowering::markInPlaceRailOp` that all
  **four** writers now call (`:1729 :2312 :2710 :3115`), erased beside
  `InPlaceRailOps` in the rollback (`:3446`), re-verified in the Phase-1 re-ask
  (`BO->getOperand(Idx) != Rail` ⇒ the same loud decline), and **CONSUMED** by
  `ArithLowering::rewriteInPlaceValueRail` instead of re-deriving `TL` from a
  `Tainted` that Phase 2's `promote()` mutates. The M-C `InPlaceReassign` route
  records no index and keeps its own `TL` pick (its `sub` widening uses a
  DIFFERENT rail predicate), so M-C's stream is byte-for-byte unchanged — measured.

## 2026-09-06 step 2c — GREEN  [DONE]
* build `cmake --build build -j8` -> `BUILD_EXIT=0`; currency check EMPTY.
  Binary saved at `$SP/bin/eqpx-fix1/{cq-opt,libCQPass.so}`.
* `lit ir-pass/test --filter 'inplace_rail'` -> **16 selected, 16 Passed** (was
  8 Passed / 8 Failed).
* `lit -s ir-pass/test` -> **1707 Discovered · 1706 Passed · 1 Expectedly Failed ·
  0 unexpected**, 37.58 s. `ctest -R ir-pass-lit` -> **Passed, 37.66 s**.
  (1691 pre-existing + 16 new = 1707; no pre-existing fixture moved.)
* **n15/n16, the W1 crash-risk cell, MEASURED**: `opt` rc 1 with EXACTLY ONE
  diagnostic — ours. `lowerBreakReversePlay` prints NOTHING; no crash, no
  `LLVM ERROR`. Now pinned by three `CHECK-NOT`s in both W1 fixtures.
* **43-reproducer census, `main`(16b15b3) vs `fix`** (`$W/census_{main,fix}.txt`,
  48 programs incl. 6 extra probes of mine): **18 MOVED, 24 UNCHANGED, 0 other**.
  The 18 are EXACTLY the programs with `imm>=1` on `main`, and every one moves to
  the mirrored decline `cq loop lowering: in-place rail op no longer provable at
  lowering` — `a1 a2 a3 c1c_m_xor_add1 c1c_m_xor_and c1c_m_xor_and_noregion
  c1c_m_xor_mul hand_add_from_xor hand_xor_commuted n04 n05 n06 n08 n15 n16 n19
  n20 n21`. Every program accepting on BOTH binaries (23): trace `cmp`
  BYTE-IDENTICAL (23/23) and lowered module identical modulo the `; ModuleID`
  path line (23/23, `diff` after stripping `ModuleID`/`source_filename`).

## 2026-09-06 step 3 — the 0-churn gate, the corpus diff, the census  [DONE]
* **`ctest --test-dir build -j6 -R '^e2e-' --output-on-failure`** ->
  **`100% tests passed, 0 tests failed out of 357`, 317.36 s**, and
  `git status --porcelain tests/` **EMPTY** — **0 goldens regenerated, 0 new slices.**
  `git diff --stat main -- tests/ runtime/ tools/ include/` is EMPTY for the whole
  branch.
* **Corpus diff `main`@16b15b3 vs `fix`, all 1691 PRE-EXISTING lit fixtures**
  (`$W/corpus_diff.py`, comparing exit code / first diagnostic line / output module):
  **`fixtures compared: 1691 · RCDIFF=0 · DIAGDIFF=0 · OUTDIFF=0`**.
* ctest counts MEASURED and UNCHANGED: `ctest -N` **367**, `-R '^e2e-'` **357**,
  `-R '^e2e-slice-'` **321**; goldens **323**; lit files **1707** (1691 + 16).

## 2026-09-06 step 3b — MUTATION VALIDATION (one half at a time, the fix_r2 pattern)
| mutation | build | result |
|---|---|---|
| **M1** — the whole new Phase-1 block disabled (`false &&`) | 0 | `lit --filter inplace_rail` **8 Passed / 8 Failed**, and the 8 Failed are EXACTLY the 8 declines. **The decline fixtures pin THIS predicate and nothing else.** |
| **M2+M3** — the tripwire kept, but the INDEX conjunct dropped AND `rewriteInPlaceValueRail` stops CONSUMING the index (both `false &&`) | 0 | `lit -s ir-pass/test` **1707 / 1706 Passed / 1 XFAIL** — **NOTHING REDDENS.** |
Binary restored after both: `cmp $SP/bin/eqpx-fix1/cq-opt build/ir-pass/cq-opt` ->
byte-identical; currency EMPTY. See the OWNER QUESTION on M2+M3 below — the stronger
form is honest defence-in-depth, and I say so rather than claiming it is pinned.

## 2026-09-06 step 4 — the record-truth items  [DONE, commit `1333278`]
COMMENTS/DOCS ONLY. The rebuilt `cq-opt` is **BYTE-IDENTICAL** (`cmp`) to the pre-edit
one and `lit -s` re-ran 1707/1706/1 XFAIL, so this commit is a statement that behaviour
did not move.
1. `TaintPropagation.h` — the writer enumeration is now FOUR by name and line
   (W1 `emitBreakForward` `:1729`, W2 `tryCaseA`'s ACCEPT `:2312` = "round 1's
   `railRoot` marking", ONE site, W3 `collapseRailPhisIn` step (3) `:2710`, W4
   `commitOutOfLoopInPlaceOps` `:3115`), and the "filed as bd eqpx, whose proposed
   fix…" paragraph is past tense with the three ways the class grew.
2. `OpcodeLowering.cpp` (1b) comment — past tense, pointing at the new block below it.
3. `RETIRE_SWAP_ROUTE_INC1_NOTES.md` — §2's ⭐ eqpx row (writers -> four, disposition
   -> FIXED with the string); §3.12's ADD row gains a dated **FALSIFIED** note (the row
   KEPT, its reading retired); NEW **§3.16** with the four writers, the two growth
   events, the fix and its four "why not" arguments, the stronger form, the 8x2
   red-green table, the WHAT WAS RUN measurement table and what is NOT covered.
4. `retire-swap-route-PRD.md` §0 — a dated **E13**.
5. `CLAUDE.md` — the C-1 bullet's eqpx sentence gains a ⭐ FIXED clause; the Build &
   Test lit-count line gets a dated **1707** prefix with the fixture names and the
   measured lit/ctest/corpus figures, and states the ctest counts UNCHANGED at
   367/357/321. `ROADMAP.md` — the eqpx mention flipped to FIXED.

---

# ── HAND-BACK — fix_eqpx (branch `eqpx-fix`, NOT pushed, NOT merged) ──

## 1. What shipped

Branch `eqpx-fix` in `$SP/wt/eqpx`, base `main` **0b402d6**. Three commits:

| commit | what |
|---|---|
| `360f7c3` | **RED** — the 16 lit fixtures alone, on the unmodified pass |
| `15196f3` | **the fix** — 2a (the tripwire) + 2b (the operand-index plumbing) |
| `1333278` | **the record-truth items** — comments + docs only; the rebuilt `cq-opt` is `cmp`-BYTE-IDENTICAL to the pre-edit one |

`git diff --stat main -- ir-pass/src ir-pass/include`:
```
 ir-pass/include/TaintPropagation.h |  63 +++++++++++++---
 ir-pass/src/ArithLowering.cpp      |  15 ++++
 ir-pass/src/LoopLowering.cpp       |  43 +++++++++--
 ir-pass/src/OpcodeLowering.cpp     | 143 ++++++++++++++++++++++++++++++++++---
 4 files changed, 242 insertions(+), 22 deletions(-)
```
`git diff --stat main -- tests/ runtime/ tools/ include/` is **EMPTY**. No new
`cqrt_*` / `cq_template_*` symbol (owner D3). Whole branch: 24 files, +2187/-26 —
the 4 sources, 16 new fixtures, and 4 docs (`CLAUDE.md`, `ROADMAP.md`, the notes,
the PRD).

**THE FIX.** `OpcodeLowering.cpp` Phase 1, immediately after the (1b)
`PreLoopCommittedInPlaceOps` block and before the M-C block: for every
`taint.InPlaceRailOps` member NOT in `PreLoopCommittedInPlaceOps`, re-ask **G2 ALONE**
(`inPlaceValueRailOperand(BO, taint)`) under FINAL taint, and `continue` after
```
cq loop lowering: in-place rail op no longer provable at lowering
```
(`DiagnosticInfoUnsupported(DS_Error)` + `!dbg`, `diagnoseRailOpStale`). G2 alone, not
the whole M-C fence, because `inPlaceFenceHolds`' G5 loop clause is not gated by
`IgnoreSelfMarking` and would refuse 100 % of in-loop sites. Never a silent
out-of-place fallback. NOT gated on `!inBennettClone` (the Phase-2 dispatch is not
either — gating would leave a hole where the dispatch has none; inert because
`seedClone` builds a fresh `TaintSet`).

**THE STRONGER FORM, also shipped.** `TaintSet::InPlaceRailIdx` records the proven
rail's operand INDEX; ONE new helper `LoopLowering::markInPlaceRailOp` is now the only
way to join `InPlaceRailOps` and all four writers call it; the rollback erases both;
the Phase-1 re-ask re-verifies the index; and `rewriteInPlaceValueRail` CONSUMES it
instead of re-deriving `TL` from a `Tainted` that Phase 2's `promote()` mutates. M-C's
`InPlaceReassign` route records no index and keeps its own pick, so M-C is
byte-for-byte untouched. **See OWNER QUESTION 1 — it is observationally inert today.**

## 2. What I ran (every number measured, with the command)

| # | command | result |
|---|---|---|
| 1 | harness controls, `run.sh p/ctlA_clean_xor_const.c fix` / `p/c1c_m_xor_and_noregion.c fix + tu_extf.c` | `ACCEPT … lines=9 imm=0` / `ACCEPT … lines=21 imm=1` — matches the brief exactly |
| 2 | 8 decline bodies through the FROZEN `$SP/bin/main-16b15b3/cq-opt` + `immcheck.py` | **all rc 0 with `railInImm` 1 (six) or 2 (the two W1 break cells)** — THE RED |
| 3 | `lit ir-pass/test --filter 'inplace_rail'` on the PRE-fix build | **16 selected · 8 Passed · 8 Failed**; the 8 Failed are exactly the 8 declines |
| 4 | same, on the fix build | **16 Passed** |
| 5 | `lit -s ir-pass/test` | **1707 Discovered · 1706 Passed · 1 Expectedly Failed · 0 unexpected**, 37.58 s |
| 6 | `ctest --test-dir build -R ir-pass-lit` | **Passed, 37.66 s, 0 failed** |
| 7 | **`ctest --test-dir build -j6 -R '^e2e-'`** | **357/357 passed, 0 failed, 317.36 s**; `git status --porcelain tests/` **EMPTY** → **0 golden churn, 0 new slices** — the gate |
| 8 | corpus diff `main`@16b15b3 vs fix over the **1691** pre-existing fixtures | **RCDIFF=0 · DIAGDIFF=0 · OUTDIFF=0** |
| 9 | 43-reproducer census (48 programs) `main` vs `fix`, STRICT stage 2b | **18 MOVED · 24 UNCHANGED** — the 18 are EXACTLY the `railInImm>=1` members, all to the mirrored decline |
| 10 | trace / module identity for the 23 programs accepting on BOTH | trace `cmp` **23/23 byte-identical**; lowered module **23/23 identical** modulo the `; ModuleID` path line |
| 11 | the W1 crash-risk cell (`n15`, `n16`) on the fix | `opt` **rc 1, EXACTLY ONE diagnostic (ours)**, no second diagnostic from `lowerBreakReversePlay`, no crash, no `LLVM ERROR` |
| 12 | all 8 declines, stderr audit | rc 1, **1 stderr line each**, **0** `broken module` / `LLVM ERROR` / assertion markers |
| 13 | **M1 mutation** — the new block disabled | `lit --filter inplace_rail` **8 Passed / 8 Failed**, the 8 Failed being the 8 declines |
| 14 | **M2+M3 mutation** — the index re-verify AND the emitter consume both disabled | `lit -s` **1707 / 1706 / 1 XFAIL — nothing reddens**; corpus diff vs the shipped fix over all 1707 fixtures **RCDIFF=0 · DIAGDIFF=0 · OUTDIFF=0** |
| 15 | ctest / file counts | `ctest -N` **367**, `-R '^e2e-'` **357**, `-R '^e2e-slice-'` **321** (UNCHANGED); `ls ir-pass/test/*.ll` **1707**; `ls tests/e2e/*.expected.log` **323** (UNCHANGED) |

**The 43-program table** is `$W/census_main.txt` vs `$W/census_fix.txt`. The 18 movers:
`a1_add_gate_in_body`, `a2_add_two_offsets`, `a3_add_xor_mixed`, `c1c_m_xor_add1`,
`c1c_m_xor_and`, `c1c_m_xor_and_noregion`, `c1c_m_xor_mul`, `hand_add_from_xor`,
`hand_xor_commuted`, `n04_bare_out_xor_noregion`, `n05_xor_mul_noregion`,
`n06_xor_add1_noregion`, `n08_add_region_gate_in_body`, `n15_break_w1_xor_r2derived`,
`n16_break_w1_xor_bareout`, `n19_xor_commuted_src`, `n20_xor_commuted_add1`,
`n21_xor_commuted_nonphi`. The 24 unchanged include every ACCEPT CONTROL
(`ctlA`, `k01`, `k02`, `k03`, `n09`, `n10`, `n02`, `n03`, `z36`,
`c1c_w1_bodyadd_r2derived`, `u01`, `u02`, `m_add_and_noregion`, `c1c_m_add_and`,
`m_sub_and_noregion`, `n01`) and every pre-existing DECLINE (`n07`, `n11`, `n12`,
`n13`, `n14`, `n17`, `n18`) with its string unchanged.

**NOT RUN, and I make no claim about them:** the full `ctest` (Rule 19 — the
orchestrator owns that gate), `frontend-lit`, `runtime`, `e2e-loop-twin-matrix` other
than as part of the `^e2e-` run (where it passed), and any Bennett-clone-specific
probe beyond the analytic argument above.

## 3. OWNER QUESTIONS

### OWNER QUESTION 1 — the stronger form (2b) is DEFENCE-IN-DEPTH and NOTHING PINS IT

MEASURED (rows 14 above): with BOTH halves of the operand-index plumbing disabled —
the Phase-1 index re-verify and `rewriteInPlaceValueRail`'s consume — the whole
1707-fixture corpus is green and the two binaries differ on **0** fixtures
(`RCDIFF=0 · DIAGDIFF=0 · OUTDIFF=0`). By this project's own standard that makes it a
**decoration, not a discriminator**, and I could not construct a program that separates
it. The reason it is inert is an argument, not an accident: with the tripwire in place
G2 returns non-null ⇒ exactly ONE operand is tainted at Phase 1, and no Phase-2 event
can flip which one — an UNTAINTED operand is never RAUW'd (RAUW replaces uses of
tainted values) and never joins `Tainted` (`promote` only inserts the NEW handle of an
op that was itself tainted and collected).

I shipped it because the brief asked for it and because it retires the THIRD
computation of one predicate at a third program point — literally the bd 8h7d.5
F-1/F-3 shape — and because the inertness argument depends on a chain a future stage
can break silently. **Owner: keep it as argued defence-in-depth (my recommendation), or
drop it as an unpinned clause.** Reproducer for the measurement: the M2+M3 binary is
saved at `$SP/bin/eqpx-m23/{cq-opt,libCQPass.so}`; the mutation is two `false &&`
inserts at `OpcodeLowering.cpp`'s `IdxDisagrees` and `ArithLowering.cpp`'s
`InPlaceRailIdx.find` conditions.

### OWNER QUESTION 2 — an UNEXPLAINED (but measured-correct, and PRE-EXISTING) loop collapse in the `n02`/`n03` accept-control family

Not eqpx's, not this increment's, byte-identical on the pre-3qlq ORACLE 52d7764,
`main`@16b15b3 and the fix — I am reporting it because I hit it while validating the
accept controls and it is the kind of thing a lens should look at rather than a thing I
should chase.

`n02_select_merge_xor_noregion.c` keeps a 3-trip loop with `r = r ^ w` in its `clang
-O1` stage-1 module, and the LOWERED module has **no loop at all** and **one**
out-of-place `cq_template_xor_i32`. Sweeping the trip count (`$W/p/x_n02_k{2,4,5,6}.c`,
one `sed` off the original):

| K | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|
| `cq_template_xor_i32` in `@slice` | 0 | 1 | 0 | 1 | 0 |

i.e. the emitted circuit realises `r ^ (K odd ? w : 0)`, which **is** the arithmetically
correct value for an xor involution at every one of the five, and the `add` analogue
(`$W/p/x_n02_add_k4.c`) is the `-O1` closed form `shl/and/add` = `r + 4w`, also correct.
The hand-unrolled twin `$W/p/x_n02_unrolled.c` is trace-BYTE-IDENTICAL to `n02`. So
nothing here is a wrong value on any observable register, and the direction of the
difference is FEWER leaked ancillas, never a dirty free. **What I could not do is name
the stage that removes the loop** — the pass has no unroller (`grep` for
`LoopFullUnroll|UnrollLoop|deleteLoop` in `ir-pass/src` finds nothing), and I stopped
rather than rat-hole. Because it is parity-CORRECT at both parities it is not a naive
erase, which is exactly why it deserves one pass of a lens's eyes.

### Nothing contradicts a PRD §2 owner decision (D1–D7)
No new `cqrt_*` / `cq_template_*` symbol; `runtime/`, `tools/opcode_table.yaml` and
`include/` untouched; no golden regenerated; no slice added; no writer's fence widened
or narrowed; no re-ask added at any writer.

## 4. What is left

* **Two adversarial rounds and a clearance** (Rule 13). This is the Rule-13 core and
  the function's own history is nine findings over seven rounds, two of them introduced
  by a fix. A green 1707/357 clears nothing.
* The brief's step-5 push and the bd close are the ORCHESTRATOR's (I did not push and
  did not touch bd).
* The two OWNER QUESTIONS above.
* Not attempted, and correctly out of scope: the capability-preserving SECOND WRITER
  ROUND (re-marking after `repropagateControlMerges`) that would re-accept some of the
  18 movers. It is argued down in notes §3.16 as a better PREDICTION rather than a
  re-verification, and must never be the fence; as a later, separate increment ON TOP of
  the tripwire it is defensible.
