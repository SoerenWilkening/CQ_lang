# fix_inc2_r2 — Inc 2 ROUND-2 FIX (fixture truth + record)

Agent `fix_inc2_r2`, 2026-09-06.
SUBJECT (mine) = `$SP0/wt/inc2` branch `3qlq-inc2` @ 6ee3ea3 (build 05:33, current).
INC-1-ONLY = `/Users/sorenwilkening/Desktop/CQ_lang` @ `a3c1513` (build 05:20) — READ ONLY, never rebuilt.
ORACLE = `$SP0/wt/pre-3qlq` @ 52d7764.

## 2026-09-06 step 0 — setup
- Read BRIEF_common, BRIEF_fix_inc2_r2, rebase_inc2.md, review_inc2_r2.md (F-I2-1..F-I2-10) IN FULL.
- Saved the pre-fix subject binary: `$SP/progress/fix_inc2_r2_work/{cq-opt.r2base,libCQPass.so.r2base}`.
- SCOPE reminder: do NOT touch `LoopLowering.cpp` (F-I2-1 is pre-existing on main = bd
  `test_C_libtooling-7yd0`, fixed as a separate C-1 round 4 AFTER Inc 2 lands).

## 2026-09-06 step 1 — F-I2-3 DONE (commit 5ad2258)
`ir-pass/test/lowering_switch_value_nonI32_cast.ll` RE-DERIVED from the rebased binary's own output.
- Mechanism it now pins (whole-region, `CHECK-NEXT`-adjacent, 24 lines from the first alloc to the
  measure): `alloc out(i64 0)` + ONE `cqrt_copy_i64(p,out)` preload, then per case
  `add_i64_hl` -> `xor_i64` delta -> `add_i64_hl_unc` + `free` -> `icmp_eq_i32_hl` flag ->
  `cqrt_copy_i64_controlled(f,d,out)`, then both strips + frees, then the trunc + measure.
- Header rewritten: the retired route is now marked as HISTORY with the reason nothing went red
  (its three directives were about the cast alone).
- Prefixes: default (ordered+adjacent), `NOROUTE` (whole-file PURE-negative: `cqrt_cswap`,
  `cqrt_x(`, `= trunc`, `cq_template_trunc_i32`, `phi i64`, `under quantum control`, `switch i32`,
  `cqrt_rz_`), `FCNT`(4 frees) `CCNT`(2 controlled copies) `PCNT`(1 preload) each in its own prefix,
  plus the pre-existing `INPUT` prefix. No count inside `NOROUTE` (the drbq Inc-4 windowing lesson).
- **p119.8 discriminator, MEASURED by MUTATION** (not asserted): commented out
  `ir-pass/src/SwitchValueEmit.cpp:294 taint.HandleWidth[Out] = Abi;`, rebuilt (`BUILD_EXIT=0`,
  `fix_inc2_r2_mutbuild.log`) -> the fixture FAILS at the FIRST RUN line with
  `error: <unknown>:0:0: in function example i32 (i32, i64): no template for opcode 'trunc i32' in
  tainted context` (`opt` exit 1, an over-decline). Reverted + rebuilt; `cmp` says the rebuilt
  `build/ir-pass/cq-opt` is **byte-identical** to `$W/cq-opt.r2base`, so nothing of the mutation
  survives. The property is NAMED by the positive `CHECK-NEXT` on
  `call i32 @cq_template_trunc_i64_to_i32(i32 %[[OUT]])`.
- **RED-GREEN vs INC-1-ONLY** (`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`,
  a3c1513): `opt` rc=0 (it lowers, by the ROUTE), then per prefix —
  `CHECK` rc=1 (adjacency fails at line 90, the `%[[OUT]]` alloc), `NOROUTE` rc=1 (line 123
  `cqrt_cswap` found), `CCNT` rc=1 (0 of 2 `cqrt_copy_i64_controlled`), `FCNT` rc=0, `PCNT` rc=0,
  `INPUT` rc=0. **3 of 6 prefixes discriminate**; FCNT/PCNT coincide because the route also frees 4
  rails and also emits exactly 1 uncontrolled preload copy — recorded in the header rather than
  quoted as coverage.
- `lit --filter lowering_switch_value_nonI32_cast` on the SUBJECT: **PASS**.

## 2026-09-06 step 2 — F-I2-4 DONE (commit see below), COMMENT ONLY
Verified the finding myself before writing it down (Rule 11):
- `grep -rn 'bool isPhiCall' ir-pass/src` -> **7 definitions in 7 files**
  (`ArmHomogeneity, ArmClassify, SelectClassify, RegionTreeDetect, SwitchClassify, SwitchArmProve`
  all `isCallToPrefix(V,"cq_phi_")`; `SwapRouteEmit` the `intrinsicSuffix` spelling of the same test).
- `include/CQ.h:73` declares `void cq_phi (double angle);` — NO suffix, so the prefix matches nothing.
- The predicate itself ALREADY carries a "VACUOUS SINCE Inc 1, DELIBERATELY KEPT" block
  (`SelectClassify.cpp:48-66`). What was missing is the note AT THE TWO GATES, which is what the
  brief asks for and what a reader of the gate would otherwise take at face value.
ADDED (no code deleted, no behaviour):
1. above `operandCarriesPhase` (gate 5's PHASE half): vacuous since a3c1513; the WI-3 class is
   STRUCTURALLY gone (a branch phase has no register operand, D1; an uncontrolled one is deleted,
   D2), and the successor shape — a register carrying kickback-imparted relative phases — is NOT
   that hazard, citing round-2 finding **F-I2-5** (`q1k_disjoint_phase_then_value` accepts and is
   BYTE-IDENTICAL to its pre-hoisted select twin) plus the linearity argument.
2. above `operandsAlias` (gate 6): its closure degenerates to `{A}` and the gate to `A == B`; the
   nearest LIVE analogue declines EARLIER, at gate 2c, **MEASURED on all three binaries**:
   `int t = cq_theta(q,0.9); p = (q>5)?t:q;` ->
   `cq controlled lowering: condition predates a non-diagonal gate under quantum control`
   on subj / inc1 / orac (`$W/p/g6_theta_alias.c`, my own re-run of the lens's probe).
   The gate-5 channel-B fallback is labelled ANALYTIC, not measured, with the ancestry argument.
Rebuild: `BUILD_EXIT=0`; `cmp build/ir-pass/cq-opt $W/cq-opt.r2base` -> **byte-identical**, which is
the proof the change is comment-only.

## 2026-09-06 step 3 — F-I2-7 pinned as a PAIR + F-I2-6 recorded (commit above)
Re-measured the lens's four programs myself on ALL THREE binaries (`$W/run.sh`, stage 1->2->2b->3->4):
- `q1e_ent.c` (`int p=q+11; if(q>3){6-op chain}`) DECLINES
  `cq controlled lowering: non-routable value multiplexer under quantum control` on subj / inc1 / orac.
- `q1e_ent_twin.c` (the same body pre-hoisted into `?:`) ACCEPTS on subj / inc1 / orac, **22 trace
  lines on all three**, STRICT 2b rc=0.
- `q3c_and_diamond.c` and `q3c_and_twin.c` (the `&&` item, F-I2-6) BOTH DECLINE
  `cq controlled lowering: control flow under quantum control` on subj / inc1 / orac — so the byte-
  identity comparison the round-1 brief asked for genuinely has **no subject**. Recorded, not pinned:
  a fixture asserting "both spellings decline" would duplicate two existing compound-condition
  declines and pin nothing new.
NEW FIXTURES (2), corpus 1685 -> **1687**:
- `ir-pass/test/control_swap_value_reject_base_from_cond.ll` — the diamond, `RUN: not ... | FileCheck`
  with the string mirrored in full (`error{{.*}}cq controlled lowering: non-routable value
  multiplexer under quantum control`) + `CHECK-NOT` on the §3c string and on any lowering.
- `ir-pass/test/control_swap_select_base_from_cond.ll` — the twin, whole-merge `CHECK-NEXT` block
  (flag mint -> out alloc -> two `cqrt_copy_i32_controlled` with the `cqrt_x` bracket -> strip ->
  free -> measure), plus `NOROUTE` (whole-file pure-negative incl. `cqrt_cswap`, `cqrt_rz_`,
  `select i1`, `phi i32`, `br i1`), `CCNT`(2) and `FCNT`(2).
- Both are captured from real `clang -O1` (SSA renamed only). ⚠ THE HEADERS RECORD WHAT `-O1` DID:
  reassociation moved the arm chain onto **%q**, so `ChainBase != Routed` — the two bases the
  decline is about are the OPTIMISER's, not the source's.
- **RED-GREEN IS DELIBERATELY ABSENT AND SAID SO IN BOTH HEADERS**: measured, both fixtures PASS on
  INC-1-ONLY (a3c1513) and on the ORACLE (52d7764) as well as on the subject, and the accept
  fixture's lowered `@slice` is **BYTE-IDENTICAL across all three** (`cmp`). The pair records a
  PRE-EXISTING over-decline; it is not a witness of an Inc-2 change and must not be quoted as one.
- Named for the owner item: **"the base-from-cond asymmetry"** (notes §4).
`lit --filter base_from_cond`: **2 PASS**.

## 2026-09-06 step 4 — F-I2-1 RECORDED (not fixed; commit above)
RE-MEASURED the finding myself before recording it (Rule 11), full pipeline, STRICT 2b rc=0 and
`opt` exit 0 in every cell (`$W/run.sh`, traces under `$W/out/`):
| pair (K=4 per-bit) | subj rolled | subj unrolled | inc1 rolled | inc1 unrolled |
|---|---|---|---|---|
| `q5sel_preadd` (4.4 select merge + `m+7`) | 44 lines, 4 `and_hl`, **0 unc** | 52, 4, 4 | 44, 4, **0** | 52, 4, 4 |
| `q4b_preadd` (Inc-2 VALUE merge + `p+7`) | 52, 4, **0** | 60, 4, 4 | 57, 4, **0** | 65, 4, 4 |
| `q5v_none` (select merge, NO preheader op) | IDENTICAL 51/51, 4/4 unc | | IDENTICAL | |
| `q5ctl_theta_preadd` (THETA root) | IDENTICAL 40/40, 4/4 unc | | IDENTICAL | |
| `q7_k32` (K=32) | 240 lines, 32 mints, **0 unc** | 301, 31, 31 | 240, 32, **0** | 301, 31, 31 |
Also re-measured on the SUBJECT: `q5v_xor` DIVERGE 44/52 (emitted `cqrt_xorc_i32` in place),
`q5v_mul` DIVERGE 44/52 (`cq_template_mul_i32_hl`, OUT of place — the separate Q-R1-1 cause),
`q5v_add2` IDENTICAL 52/52 (`-O1` folds `+7;+9` to `+16`), `q5w_mux` IDENTICAL 58/58 (4.5 data-mux:
the op folds into the case constants). The `q5sel_preadd` numbers are **identical on subj and inc1**,
which is what makes "pre-existing on landed `main`" a measurement and not a claim.
SHIPPED (records only — `LoopLowering.cpp` NOT touched, per the brief):
- 18 `.c` reproducers copied into `docs/prd/phase-04-swap-route-control/inc2-records/` under the
  lens's own names, so `review_inc2_r2.md`'s cross-references still resolve.
- That dir's `README.md` gained a round-2 section: the shape, the headline 13-line reproducer, my
  re-measured tables, the O(K) row, the full 8-row discrimination table, the analytic root cause
  (`commitOutOfLoopInPlaceOps`'s `!P->hasOneUse()` vs a rail with two prior WRITERS), why nothing
  covers it, and **bd `test_C_libtooling-7yd0`** as the owner. Intro rewritten (it said "round-1").
- PRD §0 gained **E11**, dated, placed directly under E1 (its subject is E1's out-rail; the
  out-of-order placement is stated in the line itself). It says Inc 2 adds a FOURTH producer =
  MORE CUSTOMERS, NO NEW DEFECT, and that the fix is C-1 round 4 on `main`.
- **No fixture pins the leak as an accept** — that would bless it; said so in both documents.

## 2026-09-06 step 5 — F-I2-2 resolution + the whole round-2 RECORD (commit 4b233df)
Re-measured F-I2-2 on all three binaries before recording it:
- `q1_derived` (chained `p=cq_theta(p,0.9)` before a 6-op value arm) ACCEPT subj **24** / inc1 **29**
  / orac **29**; `q1_derived_twin` (pre-hoisted select) DECLINE
  `cq controlled lowering: control flow under quantum control` on **all three**.
- `q1_plain` ACCEPT 23/28/28, `q1_plain_twin` ACCEPT 23/23/23 — so the refusal is specific to the
  CHAINED theta, not to the select.
- `q1f_fork_{diamond,twin,after}` (the kjd1 fork the gate-5 seeding was built for) DECLINE
  `cq opcode lowering: operand predates a non-diagonal gate` on **all three** — the `br` path is
  protected by `declineStaleRecordOps`, a different and later fence.
DOCS SHIPPED:
- `RETIRE_SWAP_ROUTE_INC2_NOTES.md` **§4 — Rule-13 ROUND 2** (§4.1 F-I2-1, §4.2 the reviewer flag
  RESOLVED with the seeding-artifact mechanism + the permutation/linearity argument + the backstop,
  §4.3 F-I2-3, §4.4 F-I2-4/F-I2-5, §4.5 F-I2-6/F-I2-7 + the owner-item name, §4.6 F-I2-8 with the
  rebase conflict table in one paragraph, §4.7 what I ran). ⚠ **Numbered §4, not "§2 — round 2" as
  the brief says** — §2 and §3 were already taken by round 1's ledger and the rebase; the section
  says so in its first line and nothing was renumbered.
- PRD: status header + the §0 branch note + a new **§7 STATUS** block, all three saying "rebased onto
  a3c1513, Rule-13 reviewed twice, round 2 CLEAR ON THE MECHANISM, **NOT landed, clearance pending**",
  and all three pointing F-I2-1 at bd `test_C_libtooling-7yd0` / E11.
- `CLAUDE.md`: the **three** Inc-2 status sentences (lines ~205, ~880, ~1135) each scoped to `main`
  with the branch's true state beside it. None says landed. Each records that on the branch
  `cqrt_cswap` has ONE minter (`AbortParkEmit`).

## 2026-09-06 step 6 — verification (only what I ran)
| gate | command | result |
|---|---|---|
| lit, direct | `lit ir-pass/test` | **1687 discovered · 1686 passed · 1 expectedly failed** (the standing `lowering_invert_add_i32.ll` XFAIL), 75.2 s, LIT_EXIT=0 |
| lit, ctest | `ctest -R ir-pass-lit` | **Passed**, 39.6 s, CTEST_EXIT=0 |
| Inc-2 gates | `ctest -j6 -R 'e2e-value-.*twin-identical\|e2e-slice-control-switch-value\|e2e-slice-control-value'` | **15/15 PASSED**, 26.5 s — the 4 `cmp` twin gates, 10 value slices, `e2e-slice-control-switch-value` |
| injection | `inject.py` × 7 mutations | `lowering_switch_value_nonI32_cast.ll` **7/7 CAUGHT**; `control_swap_select_base_from_cond.ll` **6/7 → strengthened → 7/7** |
| STRICT 2b | `free_pairing_check.py` (no `--allow-unproven`) | 0 violations on both fixture outputs, and rc=0 on **every** accepting plain-C program I ran |
| census (3 files touched) | grep over the lowered output | `cqrt_cswap` 0 · non-i1 `cqrt_rz` 0 · `!cq.branchphase` 0 |
| corpus | `ls ir-pass/test/*.ll \| wc -l` | **1687** (1685 + the F-I2-7 pair) |
| binary | `cmp build/ir-pass/cq-opt $W/cq-opt.r2base` | **byte-identical** — this round changed no behaviour |
| directive hygiene | grep for prose that spells a live prefix + colon | none in the 3 fixtures |
NOT run (and not claimed): the full `ctest`, `e2e-loop-twin-matrix`, `frontend-lit`, the runtime
entries, the full-corpus census, the full e2e suite.

## 2026-09-06 step 7 — one gap I found in my own record, and closed
My notes §4.2 claimed "the DOC half is done" for F-I2-2's gate-5 item, and it was not: I had written
the VACUITY comments (F-I2-4) but not the ancestry-exemption one. Added a paragraph directly under
`hasCoherentDownstreamUse`'s "keeping the sanctioned chained-prep accept" sentence (the singleton-
`Ancestry` mechanism, the three-binary measurement, the permutation argument, the
`declineStaleRecordOps` backstop, and that widening the seeding is an OWNER item), and rewrote the
notes sentence to say what is actually in source. Rebuilt: `cq-opt` **byte-identical** to r2base.

---

# HAND-BACK

## 1. What shipped
Branch `3qlq-inc2` in `$SP0/wt/inc2`, **SEVEN commits** on top of `6ee3ea3` (tip **72974d5**, 24
commits above `a3c1513`, working tree clean, **NOT pushed**, no bd touched). ⚠ **`LoopLowering.cpp`
was NOT touched**, and no Inc-1-landed code beyond the two comments the brief names (plus a third,
below). `build/ir-pass/cq-opt` is **byte-identical** to the pre-round binary — this round changed
**no behaviour at all**.

| commit | what |
|---|---|
| `5ad2258` | **F-I2-3** — `ir-pass/test/lowering_switch_value_nonI32_cast.ll` RE-DERIVED |
| `e495327` | **F-I2-4** — two VACUITY comments in `ir-pass/src/SelectClassify.cpp` (comment only) |
| `fc61ab4` | **F-I2-7** — 2 NEW fixtures, `control_swap_{value_reject,select}_base_from_cond.ll` |
| `e8fd7c3` | **F-I2-1 RECORD** — 18 reproducers + a README section under `inc2-records/`, PRD §0 **E11** |
| `5b5a1a4` | the F-I2-7 accept fixture strengthened after the injection matrix found a hole in it |
| `4b233df` | the record: notes **§4**, PRD status header + §0 branch note + a new **§7 STATUS**, `CLAUDE.md`'s three Inc-2 sentences |
| `72974d5` | **F-I2-2's DOC half in source** — the gate-5 ancestry-exemption paragraph (comment only) |

Fixture corpus **1685 → 1687**. Files touched: 2 source (comment only), 3 fixtures (1 re-derived +
2 new), 21 doc/record files.

**Dispositions, one line each.** F-I2-1 RECORDED not fixed (pre-existing on `main`, bd
`test_C_libtooling-7yd0`, C-1 round 4 there). F-I2-2 RESOLVED in the increment's favour, with the
mechanism named and an owner item filed for the widening. F-I2-3 fixture RE-DERIVED. F-I2-4 two
gates marked vacuous, no code deleted. F-I2-5 recorded and cited. F-I2-6 no subject. F-I2-7 pinned
as a pair + named "the base-from-cond asymmetry". F-I2-8/9/10 nothing owed.

## 2. What I ran (only what I ran)
* **Every measurement I wrote down, I re-ran myself** on the three binaries (SUBJECT `3qlq-inc2`,
  INC-1-ONLY `main` a3c1513, ORACLE 52d7764) through stage 1 → 2 → **STRICT 2b** → 3 → 4. No
  `--allow-unproven` anywhere; 2b rc=0 on every accepting lowering. Harness + programs +
  all-stage artifacts under `$SP/progress/fix_inc2_r2_work/{run.sh,p/,out/}`.
* `lit ir-pass/test`: **1687 discovered · 1686 passed · 1 expectedly failed** (the standing
  `lowering_invert_add_i32.ll` XFAIL), 75.2 s, LIT_EXIT=0. `ctest -R ir-pass-lit`: **Passed**, 39.6 s.
* `ctest -j6 -R 'e2e-value-.*twin-identical|e2e-slice-control-switch-value|e2e-slice-control-value'`:
  **15/15 PASSED**, 26.5 s — the four `cmp` twin gates, ten value slices, `e2e-slice-control-switch-value`.
* **Injection matrix**, 7 mutations each: re-derived fixture **7/7 CAUGHT**; new accept fixture
  **6/7 → strengthened → 7/7**.
* **Red-green vs INC-1-ONLY** on the re-derived fixture: 3 of 6 prefixes discriminate (`CHECK`
  adjacency, `NOROUTE` on `cqrt_cswap`, `CCNT`); `FCNT`/`PCNT` do not, and the header says so.
* **A mutation build**: commenting out `SwitchValueEmit.cpp:294 taint.HandleWidth[Out] = Abi;`
  makes the pass over-decline `no template for opcode 'trunc i32' in tainted context`. Reverted;
  `cmp` proves the rebuilt binary byte-identical.
* Census over the 3 fixtures I touched: cswap 0, non-i1 `cqrt_rz` 0, `!cq.branchphase` 0.
* **NOT run, and not claimed:** the full `ctest`, `e2e-loop-twin-matrix`, `frontend-lit`, the runtime
  entries, the full-corpus census, the rest of the e2e suite. No push, no bd.

## 3. Findings that are NOT mine to decide

### OWNER QUESTION 1 — "the base-from-cond asymmetry" (F-I2-7) needs a bd issue
`int p = q + 11; if (q>3) { 6-op chain }` DECLINES `cq controlled lowering: non-routable value
multiplexer under quantum control`; the pre-hoisted `?:` twin ACCEPTS. **Identical on all three
binaries**, twin lowering byte-identical across all three. Pinned by
`ir-pass/test/control_swap_{value_reject,select}_base_from_cond.ll`; reproducers
`$W/p/q1e_ent{,_twin}.c`. It points the OPPOSITE way to the increment's own reviewer flag (§4.2),
and only that one had been written down. Filing the bd issue is the orchestrator's.

### OWNER QUESTION 2 — widening gate 5's `rotationAncestry` seeding (F-I2-2)
The 4.4 refusal of a DERIVED coherent base is a SEEDING ARTIFACT (`rotationAncestry(Op)` walks only
when `Op` IS a rotation call), the `br` diamond's accept is sound (a permutation into a fresh |0⟩
ancilla), and the hazard the seeding was built for is caught on the `br` path by
`declineStaleRecordOps` — all three re-measured on all three binaries. Widening it is a Rule-13-core
ACCEPT-CLASS change and needs its own red-green + lens. Recorded in source and in notes §4.2; **not
done here**.

### OWNER QUESTION 3 — F-I2-1's landing plan is assumed, not decided by me
I recorded it as "pre-existing on `main`, bd `test_C_libtooling-7yd0`, fixed as a separate C-1
round 4 on `main` AFTER Inc 2 lands", which is what my brief states. If the owner wants it on the
Inc-2 branch instead, PRD §0 E11, notes §4.1 and `inc2-records/README.md` all say the other thing
and must be corrected together.

### Standing, unchanged by this round
Inc 2's own three OQs (Q+Q *condition* capability; the run-time classical SHIFT AMOUNT; the
`value-arm swap-route` decline string naming a retired mechanism — 6 sites, 28 fixtures), OQ-22
(the F-V1-1 `HandleWidth` widening), OQ-23 (V2's basis-state evaluator), bd `3qlq.8` (the PHASE half
of the i128 Rule-1 gap), Q-R1-1 (the hoisted loop-invariant TEMPLATE rail, which `q5v_mul`
re-measures), OQ-9 (`control_swap_value_diamond_derived.ll` no longer pins a derivation), and the
pre-existing `ChainWalk.h:204` "Inc 2 turns on emitRz's controlled arm" ambiguity on `main`.

## 4. What is left
* **The clearance on Inc 2**, then the landing. Nothing else on this branch is owed by round 2.
* **A round 3 is warranted on the C-1 machinery specifically, not on Inc 2's emitter** — this
  round's only LEAK came from the ROOT-SET widening in `LoopLowering`, and that file's own comment
  predicted the shape of the miss. That work is bd `test_C_libtooling-7yd0` on `main`.
* Two bd issues for owner questions 1 and 2 above (orchestrator's).
* ⚠ The notes' round-2 section is **§4**, not "§2 — round 2" as my brief called it: §2 and §3 were
  already taken. The section says so in its first line; if the orchestrator's index says §2, it is
  the index that needs fixing.
