# FIX_B1_R2 — the round-2 BLOCK (F-B1R2-1) closed by RE-VERIFICATION

bd `test_C_libtooling-r9e5` sub-increment 1b-B.1, branch `3qlq-inc1b-b-rail-select`.
Baseline: checkpoint **f8d29e8** (the round-1 fix), binaries saved before the first edit to
`…/scratchpad/fix_r2/pre/{cq-opt,libCQPass.so}` — every "PRE" figure below is that pair, never `main`.
Fix per `FIX_BRIEF_B1_R2.md`, **option 1** (record + re-verify), nothing predicted, no widening for the
compare select (bd `9pum`). NOT COMMITTED.

---

## 1. What changed (8 files under `ir-pass/`, +313/−12 lines, 8 new fixtures, 2 new e2e slices)

| file:line | change |
|---|---|
| `ir-pass/include/TaintPropagation.h:315` | `TaintSet::RailCondReads` — `SmallVector<pair<WeakTrackingVH /*Rail*/, WeakTrackingVH /*FirstRead*/>, 4>`, beside `DischargedFlagGates`. Header states the defect, why a record beats a prediction, why a nulled entry is SKIPPED, and a RETIREMENT TRIGGER for a stage that RAUWs a `cq_theta_i1` before the reader. |
| `ir-pass/include/ArmAnalysis.h:190,202` | declarations of `markRailCondRead` (write) and `reverifyRailCondReads` (read), next to `railWireNamesBackward` / `railMeasuredBeforeReadPoint` — the two rungs they re-ask. |
| `ir-pass/src/ArmClassify.cpp:1944` | `markRailCondRead` — append unless the identical `(Rail, FirstRead)` pair is already there; a rail read at two points records both. |
| `ir-pass/src/ArmClassify.cpp:2015` | `reverifyRailCondReads(M, taint)` — per-function cached `DominatorTree`, skip nulled/cross-function entries, **once per rail**: rung (ii) `railMeasuredBeforeReadPoint(Rail, Read, taint, DT)` → `condition measured before the control route`; rung (iii) position-free `findNonDiagonalWireGate({Rail}, true, nullptr, nullptr, &taint)` **and** position-aware `(…, Read, DT, &taint)` → `condition predates a non-diagonal gate`. Anchored on `Read` (it carries the region's `!dbg`). LOUD and FINAL; no silent fallback, no un-emission. |
| `ir-pass/src/CondTreeEmit.cpp:83` | `emitCondNode` gains an optional `TaintSet *taint` (declared in `CondTreeEmit.h`) and, on a FORWARD emission, records every gate that reads an `N.L`/`N.R` which `isCondRailLeaf` — one site covering BOTH callers (see §3, this is a finding). |
| `ir-pass/src/CondTreeEmit.cpp:184` | `emitCondNetwork` passes `&taint` at the node emission (a NON-ROOT rail leaf is read by that node's cnots/toffoli and nothing is minted for it). |
| `ir-pass/src/CondTreeEmit.cpp:241` | the `CopyRailRoot` mint's `cqrt_cnot(rail, bf)` — the 4.4 select's control read. |
| `ir-pass/src/SwapRouteEmit.cpp:1491` | `emitKickbackGroup` gains `TaintSet &taint` (3 call sites) and records the FIRST `cqrt_rz_i1(rail, ·)` of each group when `CtlIsRail` — the flat kickback and the nest's outer arm both come through here. |
| `ir-pass/src/SwapRouteEmit.cpp:2020` | the 4.3 nest's CONJUNCTION node passes `&taint` — either level ROOT may be the user's register, and for an INNER rail that toffoli is the ONLY read of it. |
| `ir-pass/src/AngleSelectEmit.cpp:211` | `emitPhaseAngleSelect`'s first `cqrt_rz_i1(rail, ·)` (the Rz-stem angle select on a rail). |
| `ir-pass/src/CQLoweringPass.cpp:431, 852` | the stage, in **BOTH** entry points, immediately after `repropagateControlMerges` and before `deleteGlobalPhases`/`lowerRotations`. The in-source argument is the P7 placement precedent, plus the two facts that make re-asking AFTER emission sound: the walker looks for `cq_theta_`-prefixed users (the emitted `cqrt_*` gates match no prefix it tests) and `taint.MeasureCalls` still holds `@cq_measure_*` only. |

Not touched: `RotationLowering`, the classifiers' round-1 ladders, the compare path, `WireWalk`, the
runtime ABI (`runtime/`, `tools/opcode_table.yaml`, `include/` are byte-unchanged — no new symbol).

### Fixtures (8 new; Rule 12 red-then-green, each verified RED on the saved f8d29e8 binary first)

| fixture | verdict | RED on f8d29e8 |
|---|---|---|
| `control_swap_reject_select_rail_round2_sibling_theta.ll` (`ll/e04`) | DECLINE `condition predates a non-diagonal gate` | yes — `rc=0` there, with `ry_i1(h5,.5); ry_i1(h5,.9); cnot(h5,bf)` |
| `control_swap_reject_select_rail_round2_measured_parent.ll` (`ll/e06`) | DECLINE `condition measured before the control route` | yes — `rc=0`, `measure_i1(h_cast)` then `cnot(h_cast,bf)` |
| `control_swap_reject_select_rail_round2_plainc_twotu.ll` | DECLINE `condition predates a non-diagonal gate` | yes — `rc=0`; the **committed `clang -O1` + `llvm-link` stage-1 module** of `multi/e16` |
| `control_phase_kickback_reject_rail_round2_sibling_theta.ll` (probe `w3`) | DECLINE `condition predates a non-diagonal gate` | yes — `rc=0`, `ry_i1(h,.5); ry_i1(h,.9); rz_i1(h,.7),!cq.branchphase` |
| `control_phase_nest_reject_rail_round2_sibling_theta.ll` (probe `w5`) | DECLINE `condition predates a non-diagonal gate` | yes — `rc=0`, 2b `3 verified`, `toffoli(h_cast, h_cmp2, g)` after both rotations |
| `control_swap_select_rail_round2_opaque_seed_accept.ll` (`ll/e11`) | ACCEPT | no — green on BOTH, byte-identical (the discriminator against review option 3) |
| `control_phase_kickback_rail_round2_window_accept.ll` (probe `w4`) | ACCEPT | no — green on BOTH, lowered modules byte-identical |
| `control_phase_nest_rail_round2_window_accept.ll` (probe `w6`) | ACCEPT | no — green on BOTH, lowered modules byte-identical |

The round-1 control the brief asked for already exists and is cited in the new headers rather than
duplicated: `control_swap_reject_select_rail_stale_sibling_theta.ll` (the `ll/e05` shape with the seed
tainted at ROUND 1), green on both binaries.

### e2e (2 new slices, +2 goldens, +1 lib TU — 0 pre-existing goldens touched)

* `e2e-slice-control-select-bool-round2-window` — **two TUs** through `run_slice_multi.sh`: the round-2
  window with the sibling AFTER the select. **ACCEPTS**, 29 trace lines, STRICT 2b `2 verified, 0
  violation(s), 0 unproven`, and the trace is source order (`ry_i1(h5,0x1p-2)` … merge … `ry_i1(h5,
  0x1.ccc…p-1)`). This is the strongest accept discriminator: the same program with the sibling BEFORE
  the select is the confirmed miscompile.
* `e2e-slice-control-select-bool-round2-opaque-seed` — single TU, `volatile bool` seed: two
  `cqrt_alloc_i1` + two independent `cqrt_ry_i1`, 17 lines, STRICT 2b clean.

**There is NO e2e DECLINE mode** (measured, not assumed): `run_slice_multi.sh` runs under `set -euo
pipefail` and byte-diffs a golden, and `tests/e2e/CMakeLists.txt` contains no `WILL_FAIL` and no decline
runner — so `multi/e16` cannot be registered as a slice. It is pinned in lit as its linked stage-1
module instead (`control_swap_reject_select_rail_round2_plainc_twotu.ll`), which keeps the plain-C
provenance without inventing a harness mode.

---

## 2. Measure and report

### (a) The whole lit corpus — `review_b1_r2_probes/corpusdiff.sh` re-pointed at the f8d29e8 PRE pair

```
bash …/fix_r2/corpusdiff_f8d29e8.sh
SCANNED=1773 MOVERS=5
control_phase_kickback_reject_rail_round2_sibling_theta RCDIFF(0->1) DIAGDIFF
control_phase_nest_reject_rail_round2_sibling_theta     RCDIFF(0->1) DIAGDIFF
control_swap_reject_select_rail_round2_measured_parent  RCDIFF(0->1) DIAGDIFF
control_swap_reject_select_rail_round2_plainc_twotu     RCDIFF(0->1) DIAGDIFF
control_swap_reject_select_rail_round2_sibling_theta    RCDIFF(0->1) DIAGDIFF
```

All five movers are the NEW decline fixtures and every one is `0 -> 1` (toward decline). **The 1765
pre-existing fixtures are 0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF**, and so are the three new accept
fixtures. (Two earlier runs of the same script, at six and at four fixtures, read `SCANNED=1771
MOVERS=4` and `SCANNED=1768 MOVERS=2` — the same statement each time.)

### (b) The round-2 reviewer's corpus — `run.sh` (73 single-TU probes) and `run_multi.sh` (3 two-TU)

```
bash review_b1_r2_probes/run.sh POST        # once on f8d29e8, once on the fix
diff <(sed 's/ trace=.*//' verdicts_PRE_f8d29e8.txt) <(sed 's/ trace=.*//' verdicts_POST_fix.txt)
```

**2 movers of 73, both ACCEPT → DECLINE:**

| probe | f8d29e8 | fix |
|---|---|---|
| `ll/e04` | ACCEPT, 28 trace lines, 2b clean | DECLINE `condition predates a non-diagonal gate` |
| `ll/e06` | ACCEPT, 27 lines, 2b clean | DECLINE `condition measured before the control route` |

`run_multi.sh`: **`multi/e16` moves ACCEPT (29 lines, 2b clean) → DECLINE `condition predates a
non-diagonal gate`** — the plain-C, two-TU CONFIRMED MISCOMPILE is closed. `e12` unchanged (declines
`value-arm swap-route` on both). `e13` unchanged and its lowered module is **byte-identical** on the two
binaries (`diff` on `tail -n +4` of both) — the compare spelling is deliberately untouched (bd `9pum`).

**Three probes the brief expected to move and did not. Each is measured, and two of them are the brief's
expectation being wrong rather than the fix being incomplete:**

* **`ll/e07` — ACCEPT on both, lowered module byte-identical, and it is CORRECT.** The sibling theta sits
  AFTER the select, so the emitted stream is `ry_i1(h,.5); [merge]; ry_i1(h,.9); measure_i1(h)` — source
  order, gate for gate. The register the copies read really is `Ry(0.5)|x⟩`, the label the select's
  condition `%b` names, and the measurement really reads `Ry(0.9)Ry(0.5)|x⟩`, the label `%b3` names. The
  fix's rung (iii) is the ladder's own two-prong question, so it accepts here for exactly the reason the
  shipped rail ladder accepts a post-region gate (`ProvenPostRegion`): position-free finds the sibling,
  and the DT prong proves it runs after every execution of the recorded read point. Declining it would
  be an over-decline of a correct program, and it is now the shipped e2e accept slice
  `e2e-slice-control-select-bool-round2-window` in plain C.
* **`c/e02` — DECLINES on f8d29e8 ALREADY** (`condition measured before the control route`), so it
  cannot move. Measured why: at `-O1` its `static int f(int)` is INLINED, the merge collapses, and the
  seed is `%2 = icmp slt %1, 6` — a compare on the theta, **tainted at round 1**. The program is not in
  the round-2 window at all in its shipped form; the round-1 ladder catches it. (Its hand-IR twin
  `ll/e06`, which keeps the 6.5 arm, IS in the window and is one of the two movers.)
* **`ll/e11` — ACCEPT on both, byte-identical**, as the brief requires: the seed is opaque and stays
  classical, so `lowerRotations` really does mint two registers.

### (c) The round-1 review corpus — `review_b1_r1_probes/run_corpus.sh POST` (108 programs)

```
diff …/scratchpad/VERDICTS_FIX1.txt …/fix_r2/r1corpus_POST_fix.txt
```

**Identical — 0 movers** against the orchestrator's post-fix-1 record.

### (d) `session-r9e5/probes/` (38 `.c` programs)

Run on both binaries with a runner written for this (`…/fix_r2/run_probes39.sh`, same recipe as
`run_corpus.sh`): **identical — 0 movers**.

### (e) e2e goldens

```
git status --porcelain tests/
 M tests/e2e/CMakeLists.txt
?? tests/e2e/slice_control_select_bool_round2_opaque_seed.c
?? tests/e2e/slice_control_select_bool_round2_opaque_seed.expected.log
?? tests/e2e/slice_control_select_bool_round2_window.c
?? tests/e2e/slice_control_select_bool_round2_window.expected.log
?? tests/e2e/slice_control_select_bool_round2_window_lib.c
```

**Zero pre-existing goldens changed.** Both new goldens were generated from the subject binary and read
line by line before committing them to the tree (the derivations are in the slices' headers).

### (f) Test runs (all on this machine, after `cmake --build build -j8` of BOTH targets)

| command | result |
|---|---|
| `ctest --test-dir build -R ir-pass-lit` | **Passed, 44.70 s** (in the full run below; a standalone earlier run at 6 fixtures was 67.71 s) |
| `lit -s ir-pass/test` | **1773 discovered · 1772 Passed · 1 Expectedly Failed · 0 unexpected**, 44.84 s |
| `ctest --test-dir build -j6 -R '^e2e-'` | **377/377 passed**, 486.08 s |
| `ctest --test-dir build -j6` (FULL) | **387/387 passed, 357.23 s** — the final run, after a comment-only rebuild. Two earlier full runs on the same tree: 387/387 in 481.27 s (after the last two fixtures) and 387/387 in 520.72 s (before them). The spread is load, not content. |

Counts, measured with `ctest -N` / `ls` (f8d29e8 → now): total **385 → 387**, `^e2e-` **375 → 377**,
`^e2e-slice-` **337 → 339**, `twin-identical` **28 → 28** (unchanged), `ir-pass/test/*.ll` **1765 →
1773**, `tests/e2e/*.expected.log` **339 → 341**. `runtime/`, `tools/opcode_table.yaml` and `include/`
are untouched.

### Injection matrix over the three new ACCEPT fixtures (Rule 12's "does the pin actually pin?")

16 injections × each fixture's own prefixes, run on the real lowered output (`…/fix_r2/inject.py`):
clean control **6/6**, **4/4** and **4/4** prefixes green; **0 MISSED**. The brief's specific case — a sibling
`cqrt_ry_i1` on the rail between the two `cqrt_cnot` — is caught by `ORD` **and** `RYCNT`; a `cqrt_x`
on a user register by `ORD`+`NOX`; an extra free by `ORD`+`FCNT`; an extra cnot by `ORD`+`CNCNT`; a
rotation injected AFTER the measure (invisible to the `ORD` `-NEXT` chain) by the whole-file `RYCNT`
count.

---

## 3. The OTHER TWO CONSUMERS — reached, contrary to the reviewer's `e09` result,
## and the second one found a hole in this fix's own first spelling

The brief asked me to try, and to record the attempts rather than fabricate one. Four probes, now
committed as `probes/w1`–`w4` with a README addendum:

| probe | shape | f8d29e8 | fix |
|---|---|---|---|
| `w1` | `e09` + `cq_measure(%y)` keeping `%out` live; `br i1 %b` in the ROUND-1 region's own MERGE block | DECLINE `control flow` | DECLINE `control flow` |
| `w2` | `w1` minus the sibling | DECLINE `control flow` | DECLINE `control flow` |
| `w3` | `w1` + one `br label %second`, so the rail theta and its branch have their own block | **ACCEPT** rc=0, 2b `1 verified, 0 violation(s)`, emitting `ry_i1(h,.5); ry_i1(h,.9); rz_i1(h,.7),!cq.branchphase` | **DECLINE** `condition predates a non-diagonal gate` |
| `w4` | `w3` minus the sibling | ACCEPT | ACCEPT, module **byte-identical** |

So `e09`'s decline is the REGION SHAPE (a rail branch sitting in the previous region's merge block),
not the ladder and not the sibling — `w2` is the control that shows it. One block boundary later the
window is reachable for the kickback consumer too, it was a silent wrong unitary on f8d29e8, and it now
declines. `w3`/`w4` are shipped as the two kickback fixtures above.

### ⚠ And the 4.3 NEST reached it too, through an emission site the first spelling of this fix missed

Probing the nest was meant to be a formality — the brief's recording sites are
`emitCondNetwork`'s node loop and `emitKickbackGroup`, and the nest goes through both. It does not go
through them for the case that matters. `SwapRouteEmit::emitPhaseKickbackNestRegion` builds the
CONJUNCTION node BY HAND and calls `emitCondNode(Conj, …)` **directly**, with `Conj.L`/`Conj.R` the two
level ROOTS — either of which may be the user's register since 1b. And when the OUTER arm carries no
phase gates (`if (b) { if (c) cq_phi(θ); }`, the ordinary nested-AND), `emitKickbackGroup` is called
with an EMPTY angle list and returns before recording anything, so that toffoli is the ONLY read of the
register. For an INNER rail it is the only read in every case, since the inner arm's phases ride the
conjunction ancilla.

| probe | shape | f8d29e8 | fix |
|---|---|---|---|
| `w5` | depth-2 nest, OUTER condition the `%out`-derived rail + sibling, outer arm with NO gates | **ACCEPT** rc=0, 2b `3 verified, 0 violation(s)`, `ry_i1(h,.5); ry_i1(h,.9); toffoli(h, h_cmp2, g); rz_i1(g,.7),!cq.branchphase` | **DECLINE** `condition predates a non-diagonal gate` |
| `w6` | `w5` minus the sibling | ACCEPT | ACCEPT, module **byte-identical** |

The fix for that is not a fourth call site — it is moving the recording INTO `emitCondNode`, the one
function both callers go through, so a node's control read of a rail is recorded wherever the node was
built. That is the `markBranchPhaseGate` lesson (`CLAUDE.md`: "a seventh emission site that forgets the
call re-opens this with no diagnostic anywhere") applied to its successor record, one epic later, and it
is why `emitCondNetwork` no longer records rail reads itself. `w5`/`w6` are shipped as
`control_phase_nest_{reject_,}rail_round2_{sibling_theta,window_accept}.ll`.

**The Rz-stem ANGLE SELECT records at its own single site** (`emitPhaseAngleSelect`'s first
`cqrt_rz_i1`) and is covered by construction; I did not find a program that reaches the round-2 window
through it, and I did not fabricate one.

---

## 4. Open questions / things a round 3 should look at

1. **`ll/e07` is an accept, and the review called it a mover.** My derivation (§2b) says it is correct and
   the DT prong is the right answer; a third round should re-derive it independently, because "the
   sibling is after the read point" is exactly the kind of claim this project's history says to re-check.
2. **The compare select is untouched and still miscompiles** (`ll/e08`, `multi/e13`, byte-identical on
   both binaries here) — bd `9pum`. The record's shape was chosen so that increment is an extension
   (add compare SEEDS with the leaf mint template as the read point), not a second stage.
3. **The recording sites are now four, and the argument that they are ALL of them is structural rather
   than enumerated: a gate fires on a user register only through `emitCondNode` (any node control),
   `emitCondNetwork`'s `CopyRailRoot` cnot, `emitKickbackGroup` (`CtlIsRail`), or
   `emitPhaseAngleSelect`'s rail branch.** A fifth emitter that reads a rail and forgets
   `markRailCondRead` re-opens F-B1R2-1 with no diagnostic anywhere — §3 is the measured demonstration
   that this is not hypothetical, since the first spelling of THIS fix already missed one.
4. **One diagnostic per RAIL, not per read point.** A kickback records one entry per group (arm, tail
   incoming); they are emitted contiguously so they answer identically, and the reader stops at the
   first decline for a rail. If a future emitter ever reads one rail at two positions with user code
   BETWEEN them, that assumption is worth re-deriving (the reader already handles it correctly — it
   asks every entry — but the "answers identically" sentence would stop being true).
5. **`review_b1_r2.md`'s §6 item 3 is not done here**: "ask the same question of every OTHER predicate
   that reads `taint.Tainted` inside `detectControlRegions` and whose answer is consumed after
   `repropagateControlMerges`". This fix closes the two the round found (`railWireNamesBackward`,
   `findNonDiagonalWireGate`) at the RAIL consumers only. The PREDICATE-species row that
   `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 needs is still owed.
6. **F-B1R2-2/3/5 (the three DOC items) are NOT addressed here** — this fix is the BLOCK only.
