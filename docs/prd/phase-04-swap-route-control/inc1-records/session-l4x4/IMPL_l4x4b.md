# IMPL — bd `test_C_libtooling-l4x4` sub-increment **l4x4.b**: the in-place controlled-Ry ARM and the controlled STATE PREP on a bare `_Bool` (rail-root) condition, including the NEGATED condition

**Implementation record.** Branch `l4x4b-bool-ry-arm`, worktree
`/Users/sorenwilkening/Desktop/CQ_l4x4`, based on the Track-C checkpoint
**578dbc4** (`f2-condwire-narrowing`), NOT on `main`. **Not committed, not
pushed.** Two frozen reference binaries, both read-only, neither rebuilt:
**ORACLE** = `main` 0c7380c, **F2** = the base checkpoint 578dbc4.

> **Bottom line.** (a) The owner's shape lowers: his `grover_oracle_uncompute.c`
> **second region in isolation** compiles to the exact seven-line trace the brief
> predicted, with no `cqrt_x`, no mint, no strip and no free. (b) **H-1 is fixed
> structurally**, in three parts, and the first spelling of part 3 was measurably
> WRONG — it cost a legitimate accept, and the correction is recorded rather than
> quietly applied. (c) **The three-way corpus sweep reads 2 movers, both
> DECLINE → ACCEPT on `bare i1 register condition`, with 0 DIAGDIFF and 0
> OUTDIFF over 1784 pre-existing fixtures.** (d) **H-2's tripwire is measurably
> load-bearing at this consumer**: with `markRailCondRead` disabled the round-2
> window program compiles at `opt` exit 0 with the arm controlled on the wrong
> register — the F-B1R2-1 miscompile, at a new consumer. (e) Three measurements
> changed the plan and are recorded in §7, one of which (`t10`) means a fixture
> SCOPE asked for would have pinned nothing.

---

## §0 MEASURE FIRST — SCOPE §0.1's table, re-run THREE WAYS before coding

Built BOTH targets (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
-DCMAKE_BUILD_TYPE=Release && cmake --build build -j8`), then ran every probe in
`probes/` against ORACLE, F2 and the PRE-CHANGE subject build with
`probes/impl/run3.sh`.

**All 35 probes agree across all three binaries, and every row matches SCOPE
§0.1 exactly.** In particular the F2 narrowing moves NONE of them — every
rail-condition probe dies at `classifyArms`' first gate, which is upstream of F2.
The full table is in `probes/README.md`; the load-bearing rows are:

| probe | ORACLE | F2 | SUBJ (pre-change) |
|---|---|---|---|
| `t1` in-place Ry arm on a rail | `bare i1 register condition` | same | same |
| `t3` state prep on a rail | same | same | same |
| `t5` in-loop rail form | same | same | same |
| `t5c` its COMPARE twin | `condition predates a non-diagonal gate` | same | same |
| `t6c` Ry on the cond wire, COMPARE twin | `state prep merged with a quantum register` | same | same |
| `t7` negated rail | `bare i1 register condition` | same | same |
| `t24c` stale record, COMPARE twin | `stale rail record read past a controlled Ry` | same | same |

---

## §1 THE CLASSIFIER — sites, and the ONE re-decline partition

All in `ir-pass/src/ArmClassify.cpp`, inside `classifyArms`. Line numbers are
this branch's.

| line | what | why |
|---|---|---|
| **2556** | `const bool RailCond = isCondRailLeaf(Region.Condition);` and the gate becomes `if (!isa<CmpInst>(…) && !RailCond)` | THE GATE. Every rail-condition diamond died here; now the rail is admitted and the non-rail non-compare keeps `control flow`. |
| **2562** | `if (RailCond && !Region.Pred)` → `control flow` | no pred, no read point for rungs (ii)/(iii). Loud, never a silent skip. |
| **2581** | `comparePredLowerable` guarded by `!RailCond` | a rail has no predicate and no `_hl` template. |
| **2590-2601** | RUNG (i) `Taint.Tainted.count(Rail)` → `control flow`; RUNG (ii) `railMeasuredBeforeReadPoint(Rail, Region.Pred->getTerminator(), …)` → `condition measured before the control route` | placed exactly where `condDataUseDisposition`'s `MeasuredEarly` sits for a compare, so message ORDER mirrors the compare path. |
| **2621-2627** | the `HasDataUse` loop guarded by `!RailCond` | **H-4.** Left in it is WRONG ABOUT THE WRONG OBJECT: a rail's users are the user's own `_Bool` reads, so `HasDataUse` is TRUE for the flagship program and `condDataUseDisposition` would adjudicate the USER'S REGISTER as a flag lineage. Pinned by `control_inplace_ry_rail_data_use.ll`. |
| **2689** | `RailCond ? railCondWireDisposition(…) : condWireDisposition(…)` | RUNG (iii), spelled exactly as `classifyPhaseKickback:4685` spells it. |
| **2720** | `declineRailClass()` — the ONE spelling of the §2.6 re-decline, routed through `declineArm` | so a region that also carries a deferred wire gate keeps that message. |
| **2856 / 2882 / 3763 / 3971** | the four re-decline sites: PHASE (diamond), EQ-FOLD, PHASE (if/else leaf anchor), VALUE | **H-8.** Written at every accept site, not once — the spelling homogeneity already uses, for the reason the file's own `SawRotationArm` comment records ("Luck is not a fence"). |
| **2940** | `if (RailCond && Region.InLoop)` → `control flow inside a loop body` | the **l4x4.c** carve-out (bd `test_C_libtooling-wx8g`). Not a fence: the shape reaches here and R7 (b)/(b′) would carry — what it lacks is a WITNESS (its compare twin declines by row W) and it is the C-1 invariant/carried mixture. ⚠ **SAY THE COST IN FULL (round-1 review F-2): because the COMPARE spelling cannot express this shape AT ALL — measured, `t5c` declines identically on ORACLE, F2 and here — the carve-out closes the ONLY door, so "Grover as a ROLLED loop with a `_Bool`-controlled rotation or state prep" compiles in NO spelling on ANY binary.** That is an owner-visible over-decline, filed with that sentence, not a missing witness. |
| **2954** | `if (RailCond && Arms.size() > 1)` → `kBareRailCondReason` | ONE content arm only; the two-arm anti-control stream is a different emission order and owes its own round. Unreachable from plain C (`-O1` folds it to an angle select = **l4x4.a**). |
| **2976** | `RailCond && Region.ArmNegated && !Region.ArmFalse && valueCarriesUndef(angle)` → `rotation angle` | the ONE literal hazard the negation creates (bd `xy9n`), refused BEFORE mutation. ⚠ **IT WAS NOT THE ONLY ONE — see the ROUND-1 row below.** |
| **3738** | `Region.RailLadderProven = true` at the rotation-arm accept | §2.8's backstop; the emitter refuses a rail without it. |

> ### ⚠ ROUND-1 RULE-13 FIX — one NEW clause, and the line numbers above are the CHECKPOINT's
>
> Every number in the table is as of the PRE-REVIEW checkpoint **267937d**. The
> round-1 fix inserts a shared helper near the top of the file and two comment
> blocks, so the post-fix anchors are: `RailCond` gate **2582**, no-pred **2587**,
> `comparePredLowerable` guard **2605**, rung (ii) **2621**, rung (iii) **2715**,
> `declineRailClass` **2746**, in-loop carve-out **2981**, one-arm **2994**, undef
> angle **3017**, `RailLadderProven` **3851** (all by `grep`, not by arithmetic).
>
> | line (post-fix) | what | why |
> |---|---|---|
> | **125** | `bool constantAngleIsNonFinite(const Value *Angle)` — `dyn_cast<ConstantFP>` + `!isFinite()`, in the file's first anonymous namespace | **ONE SPELLING** (Rule 14). Called by the new clause below AND substituted into `angleSelectArmsAdmissible`'s clauses (2a)/(2b), which had the identical expression inline. The substitution is behaviour-identical — MEASURED, `OUTDIFF=0` over all 1816 fixtures against the checkpoint binary. |
> | **3090** | `RailCond && Region.ArmNegated && !Region.ArmFalse && constantAngleIsNonFinite(angle)` → `rotation angle` | **FINDING F-1**, graded OVER-ACCEPT-ARGUED: the checkpoint compiled `if (!b) r = cq_theta(r, __builtin_inf());` at `opt` exit 0, emitting `ry(h1,+inf); cry(h,h1,-inf)` — so on the `b = 1` branch, **where the source is the IDENTITY**, the register got `Ry(−∞)Ry(+∞)` = NaN. The additivity identity that licenses the whole negated form holds for FINITE angles only. The COMPARE twin is faithful (one gate inside a `cqrt_x` bracket), so the hole is l4x4.b's own. NO NEW STRING. |
>
> **A RUN-TIME ANGLE KEEPS ACCEPTING** — decision (b) of the fix brief, and it is
> a decision with an argument rather than an omission: the emitter performs
> `fneg`, one sign bit, which cannot leave the finite class, whereas Inc-2b's
> `fsub` manufactures a non-finite value from two FINITE arms — so the clearance
> blocker **F-11's structure does not transfer** and there is no compile-time-
> invisible class here. The only failing input is an angle that was ALREADY
> non-finite, i.e. an ill-formed CQ program in every spelling. The residual and
> the owner option that removes it are **§7 Q8**.

**Untouched and verified by reading:** `condProvenance` (for a bare rail
`Prov == {rail}` exactly — it collects a theta's RESULT and stops); F1 all three
clauses; F2 including the Track-C `CondWire` narrowing; R3; R4/R6 (with their
`if (!StatePrep)` skip); R7's loop clauses; the final P1 fence;
`straightThroughConstFoldHandle` (a benign `dyn_cast_or_null<ICmpInst>` miss — an
unbuilt re-anchor can only OVER-decline); `classifyAngleSelect` (l4x4.a);
`classifyClassicalCallArm` (bd `54ur`).

---

## §2 THE EMITTER, AND H-1's FIX

### 2a. `SwapRouteEmit.cpp`

`emitInPlaceRotationRegion` takes a `Value *Cond` (`:678`) with `CondI` as the
diagnose anchor; `RailCond = isCondRailLeaf(Cond)` (`:679`); the caller-independent
backstop `if (RailCond && !R.RailLadderProven) → kBareRailCondReason` (`:689`).

* **step 1 (`:851`)** `Flag = RailCond ? Cond : lowerCompareToFlag(cast<CmpInst>(Cond), …)`
  — byte-for-byte the substitution `emitPhaseAngleSelect` already ships for the
  phase stem. Nothing is minted.
* **step 2 (`:887`)** the NEGATED rail arm, §2.3 **option A**, ANTI-CONTROL BY Ry
  ADDITIVITY. `T` keeps angle θ and is hoisted as the UNCONDITIONAL gate; a CLONE
  `TNeg` is chained onto it with `−θ` and recorded in `ControlledRotations`, so
  the stream is `ry(h,θ); ry_controlled(h_b,h,−θ)`. `−θ` is an `APFloat::changeSign`
  on a `ConstantFP` (exact; a run-time classical angle gets `CreateFNeg`, also
  exact) — **there is no `fsub`, so the Inc-2b rounding fence has no subject**.
  `G.first` is repointed to `TNeg` so M-β's RAUW target is still the LAST gate.
  The COMPARE path keeps its `cqrt_x` bracket byte-for-byte.
  ⚠ `TNeg` is inserted into `taint.ThetaCalls` immediately AFTER `T`, never
  appended — `lowerRotations` documents and depends on "a chained theta N+1 takes
  theta N's result as its operand", and a post-region `cq_theta` on the merge
  (RAUW'd to `TNeg`) would otherwise be lowered against an un-RAUW'd operand.
* **`markRailCondRead` at BOTH rail read points** (`:923` the negated `TNeg`,
  `:944` the un-negated hoisted gate) — the FIFTH and SIXTH sites. Measured
  count: **6** (`grep -rn 'markRailCondRead(' ir-pass/src` → `CondTreeEmit.cpp:83`,
  `:241`, `AngleSelectEmit.cpp:211`, `SwapRouteEmit.cpp:923`, `:944`, `:1711`).
* **step 3 (`:1003`)** the strip and the `cqrt_free` are SKIPPED WHOLE for a rail.
  The strip has no subject (nothing was minted); the free would be a hidden
  measurement (`Ry(θ)|0⟩ ≠ |0⟩`, Rule 6).
* **step 4** M-β UNCHANGED — a correctness requirement for the state prep.
* **`emitRegion` (`:1113-1139`)** dispatches a rail region to
  `emitInPlaceRotationRegion` BEFORE the `dyn_cast<CmpInst>` cast, so every path
  below still sees a real compare; a rail whose plan says anything other than
  `InPlaceRotation` declines LOUDLY.

### 2b. H-1 — THE CONTROL OPERAND. Three parts, and part 3's first spelling was wrong

`taint.ControlledRotations` mapped `theta → raw Value *`. Sound while every
control was a minted `i32` compare flag; **not** sound for a rail, whose control
is the user's `@cq_theta_i1` CALL that `lowerRotations` — the map's own consumer —
RAUWs onto an `i32` handle and then ERASES.

1. **`WeakTrackingVH` as the mapped type** (`TaintPropagation.h:190`). It FOLLOWS
   the RAUW (the entry BECOMES the handle) and NULLS on an erase with no
   replacement. Only ONE reader consumes the value (`RotationLowering.cpp:226`);
   the other four uses are key tests, so the change is contained.
2. **DETERMINISTIC ORDER** (`RotationLowering.cpp:242-266`). Pass 1 lowers every
   recorded CONTROL theta plus its whole CHAINED ancestry; pass 2 the rest;
   relative order preserved inside each pass, so the file's existing
   "parent before child" invariant is INHERITED rather than re-established.
   ⚠ **It is a no-op for every module without a rail control, by construction**:
   `ControlThetas` is empty when every control is a compare flag, and the
   partition then reproduces `taint.ThetaCalls` verbatim. That matters because
   the `!Chained` arm consumes a `BirthOrder` slot (the Q+Q ordering seed) — and
   the 0-OUTDIFF sweep in §6 is the witness that nothing moved.
3. **A LOUD USE-SITE CHECK** (`:355`): a recorded control that is NULL, or that is
   STILL a `@cq_theta_*` call, declines `unsupported controlled rotation control
   handle` and lowers nothing — never a fall-through to the UNCONTROLLED gate,
   which would fire the arm on both branches.

> ⚠ **PART 3's FIRST SPELLING WAS `isIntegerTy(32)` AND IT WAS MEASURABLY WRONG.**
> A CHAINED theta lowers to `Handle = Op`, its arg-0, which for a rail whose
> parent is a TEMPLATE value (a `%out`-derived `icmp` — the round-2 window) is a
> pre-`lowerOps` `iN` value that `lowerOps` RAUWs to an `i32` handle one stage
> later. That transient is this file's OWN documented behaviour and applies to the
> UNCONTROLLED gate identically. The first spelling declined
> `probes/impl/multi/w2` for the wrong reason and would have refused a shape that
> has nothing to do with H-1. What H-1 needs is that the control was RESOLVED —
> i.e. is no longer the theta call — and that is what is asked now. Recorded here
> because "a type check that happens to fire" is exactly the passes-for-a-reason-
> nobody-wrote-down shape this project keeps finding.

**MEASURED IN THE LOWERED IR, not in the exit code** (SCOPE H-1's instruction):
`probes/t1` emits `call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 9.0e-01)`
with `%h` the rail's own `cqrt_alloc_i1` handle — an `i32`, live, not erased.

---

## §3 THE FREEZE, AND WHAT THE SPINE DOES WITH `b`

`ChainWalk::railCarriesControlledRotation(H)` derives the rail from the emitted
gate's **arg-1** use, so:

* **arg-1 (the ROTATED rail) is FROZEN** — unchanged by l4x4.b.
* **arg-0 (the CONTROL, the user's register) is NOT**, and must not be:
  `isInPlaceGateOn` requires `arg-1 == H` and the generic `_controlled` bail
  refuses it outright. Consequently `isTerminalHandle(h_b)` hits `return false`
  (the controlled gate is not an in-place gate on it, not a measure sink, not an
  output sink, not a copy-out sink) — **the whole-DAG spine never claims it** —
  and `preservesBasisUnderRecord`'s disqualify list names every `_controlled`
  gate, so it is never an M-B interior candidate either.

**NET: `b` IS LEFT ALLOCATED AND NEVER FREED.** Two things a reviewer will ask,
both answered in the source at `emitInPlaceRotationRegion` step 3: (i) `b` is
`Ry(θ)|0⟩ ≠ |0⟩`, so a free would be a hidden measurement — the leak is the
REQUIRED direction, not a shortfall; (ii) if `b` is also MEASURED (the flagship
program) its `cqrt_measure_i1` is an ordinary sink and nothing changes.

**It is the disposition the COMPARE form already gives its own condition
register, and that is MEASURED, not argued**: probe `t11c` accepts on `main` and
`%h` appears in NO `cqrt_free`. So l4x4.b introduces no new leak class; it gives
the USER'S register the treatment the FLAG'S SOURCE register already gets.
Pinned by `control_inplace_ry_rail_dead_register.ll` (`FCNT-NOT`) and by
`control_inplace_ry_rail_data_use.ll`'s `NOFREEB-NOT` (the only free there is the
`zext` template rail's). Stage 2b on all five e2e slices:
`4 rail mint(s) of which 4 left allocated, 0 cqrt_free site(s): 0 verified,
0 violation(s), 0 unproven`.

---

## §4 RED-GREEN LOG

**28 fixtures added, 2 `git mv`'d and rewritten, 3 pre-existing amended
(comments only), 0 pre-existing behaviour changed.** Corpus **1784 → 1810**
(`ls ir-pass/test/*.ll | wc -l`).

### 4a. DECLINES (14) — each written before the code that makes it reachable

| fixture | probe | string |
|---|---|---|
| `..._reject_rail_measured_before.ll` | `t9` | `condition measured before the control route` |
| `..._reject_rail_sibling_theta.ll` | `p1` | `condition predates a non-diagonal gate` |
| `..._reject_rail_chained_between.ll` | `p2` | same |
| `..._reject_rail_cond_wire.ll` | `d2` hand IR | same |
| `..._reject_rail_stateprep_merged_quantum.ll` | `t6` | `state prep merged with a quantum register` (F1) |
| `..._reject_rail_stale_record.ll` | `t24` | `stale rail record read past a controlled Ry` (R6) |
| `..._reject_rail_inloop.ll` | `t5` | `control flow inside a loop body` (**l4x4.c**) |
| `..._reject_rail_ifelse.ll` | hand IR | `bare i1 register condition` |
| `..._reject_rail_multigate_arm.ll` | hand IR | `control flow` (R1) |
| `..._reject_rail_negated_undef_angle.ll` | hand IR | `rotation angle` |
| `..._reject_rail_round2_sibling_theta.ll` | `w2`, two-TU linked | `condition predates a non-diagonal gate` **from `reverifyRailCondReads`** |
| `..._reject_rail_round2_measured_parent.ll` | `w3`, two-TU linked | `condition measured before the control route`, same stage |
| `control_swap_reject_phase_rail_cond.ll` | hand IR | `bare i1 register condition` (§2.6 PHASE) |
| `control_swap_reject_value_rail_cond.ll` | **PRE-EXISTING, amended** | same (§2.6 VALUE) |

Eleven are RED on BOTH reference binaries (they answer `bare i1 register
condition` there, so neither can witness the fence). Three — the two §2.6 files
and `..._reject_rail_ifelse.ll` — decline with the SAME string on all three
binaries FOR DIFFERENT REASONS, and each header says so and names the RECORDED
MUTATION that discriminates: delete that class's `if (RailCond)` clause and
`emitRegion`'s rail dispatch refuses the region with `control flow`, a different
string from a different layer.

#### 4a-R1. ROUND-1 RULE-13 FIX — +5 declines (corpus 1810 → 1818 with 4b-R1)

| fixture | source | string | RED on |
|---|---|---|---|
| `control_inplace_ry_reject_rail_negated_inf_angle.ll` | plain C `-O1`, `review_l4x4b_r1_probes/x01_neg_inf_angle.c` | `rotation angle` | **the CHECKPOINT 267937d itself** (rc 0 there — measured) |
| `control_inplace_ry_reject_rail_negated_nan_angle.ll` | `x02_neg_nan_angle.c` | same | same |
| `control_inplace_ry_reject_rail_negated_neginf_angle.ll` | the `-inf` member | same | same |
| `control_inplace_ry_reject_rail_stateprep_negated_inf_angle.ll` | plain C `-O1`, probe `x06_prep_neg_inf.c` | same | same |
| `control_swap_reject_value_rail_cond_early_clause.ll` | plain C `-O1`, probe `t16_i1_stateprep` | **`value-arm swap-route`** | **NOT red on the checkpoint — F-5 is a COVERAGE finding, and the header says so** |

⚠ **THE FOURTH IS A MEMBER THE REVIEW DID NOT NAME, and it is why "one conjunct"
had to be measured rather than assumed.** F-1's three reproducers are all IN-PLACE
Ry arms; the CONTROLLED STATE PREP is a different accept shape and duplicates the
angle the same way (`alloc(SEED); ry(h_r,θ); cry(h_b,h_r,−θ)`), so the same defect
is reachable through it — MEASURED from plain C on the checkpoint, rc 0 with
`ry(%h1,+inf); cry(%h,%h1,-inf)`. The clause covers it because it sits among the
SHARED rail clauses, ABOVE the three `StatePrep`-guarded ones; that placement is
what the fixture pins, and its FINITE control is the already-committed
`control_inplace_ry_stateprep_rail_negated.ll` (unmoved).

The first four are the F-1 fix's red-green, and they are the STRONG kind of red:
the checkpoint binary **compiled** all three at `opt` exit 0, verify-clean and
stage-2b clean, so it — not a reference binary — is what witnesses the fence.
(`main` 0c7380c and the F2 checkpoint are red too, but with a DIFFERENT string
from a DIFFERENT layer, `bare i1 register condition`, so neither can witness it.)
The `-inf` member records a READING: the fix brief grouped `-inf` with the accept
controls, and it is a DECLINE here because the defect is the SUM of the two
emitted slots — `Ry(+inf)·Ry(−inf)` is NaN whichever sign the source wrote — so
accepting it would be an over-accept on the identical unitary.

The fifth is F-5: the VALUE class on a rail has TWO exits and only one was
pinned. See the `SCOPE_l4x4.md` §2.6 ERRATA.

#### 4b-R1. ROUND-1 RULE-13 FIX — +3 accept controls, one per conjunct

| fixture | pins | goes RED if |
|---|---|---|
| `control_inplace_ry_rail_negated_zero_angle.ll` | `0.0` is FINITE: `Ry(0)·Ry(−0) = I` exactly | the `isFinite()` question is re-spelled as any "is this angle usable" test (`isNonZero`, `isNormal`, truthiness) |
| `control_inplace_ry_rail_negated_runtime_angle.ll` | **decision (b)** — a RUN-TIME angle keeps accepting, `fneg` and no `fsub` | someone imports Inc-2b's constant-arms-only narrowing to this shape |
| `control_inplace_ry_rail_unnegated_inf_angle.ll` | the `Region.ArmNegated` conjunct — ONE emitted slot for one user angle is FAITHFUL | the fence is widened into a blanket refusal of non-finite angles |

Each of the three is GREEN on the checkpoint and GREEN after the fix — which is
the point: the clause is a NARROWING, and these are the measurement that it
narrowed nothing it should not. All three are `-O1`-reachable (transcribed from
`review_l4x4b_r1_probes/{n12,n11}` and the un-negated twin of `x01`).

### 4b. ACCEPTS (14, of which 2 are flips)

`control_inplace_ry_rail_{diamond,negated,i1_width,f64_width,derived_base,dead_register,two_regions,post_ry_sdagger,data_use,measure_after,opaque_seed,cast_base}.ll`
and `control_inplace_ry_stateprep_rail_{i32,i1_seed,negated}.ll`.

Every assertion block is **DERIVED FROM THE PASS OUTPUT** by a generator
(`probes/impl/`-adjacent scratch), never typed — the drbq Inc-4 lesson (9 of 20
accepts once named a `%h1` that did not exist). Prefixes: a positional
`CHECK`/`CHECK-NEXT` stream plus five PURE-NEGATIVE whole-file prefixes (`NOX`,
`NOROUTE`, `NOMINT`, and per-file `FCNT`/`NOFREEB`) and three exact whole-file
counts (`CRCNT`, `RYCNT`, `ACNT`). `NOX-NOT: call void @cqrt_x(` is the
non-negotiable, and the whole-file form is both stronger than SCOPE's suggested
`cqrt_x(i32 %h_b` and true (the rail path has no ancilla to bracket either).

**THE TWO FLIPS, both `git mv`'d with the IR BYTE-UNCHANGED** (the 3qlq.4 / r9e5
precedent), each carrying its own old header below a `---- HISTORY ----` rule:

* `control_inplace_ry_reject_raw_i1_cond.ll` → **`control_inplace_ry_rail_diamond.ll`**.
  Its own header PREDICTED the flip ("a real (3-gate cheaper) capability … NOT a
  physics wall"), and the prediction is measured.
* `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll` →
  **`control_inplace_ry_stateprep_rail_i1_seed.ll`**. Committed by Track C
  explicitly as a retirement-triggered decline whose note names the exact stream
  to re-derive; that stream is what is asserted.

⚠ **A HISTORY BLOCK MAY NOT QUOTE A `RUN:` OR `CHECK` TOKEN.** lit and FileCheck
match those prefixes as SUBSTRINGS anywhere on a line, so a quoted old directive
becomes a LIVE one — measured (the first spelling of both flips failed on the
quoted decline `CHECK`). The generator strips those lines and says so.

### 4c. INJECTION MATRIX

Seven mutations applied to the LOWERED stream of each accept, every declared
prefix re-run: an injected `cqrt_x` on the rail, an extra `cqrt_free`, the
`_controlled` gate with control and target SWAPPED, the `_controlled` suffix
DROPPED (the arm fires on both branches), an extra uncontrolled `cqrt_ry` on the
condition register, the NEGATED shape's unconditional twin DELETED, and an
injected `cqrt_cswap`.

```
fixtures=15 mutations=97 MISSED=0 DIRTY=0 n/a=8
```

⚠ **The matrix is validated, not assumed**: stripping the `NOX`/count prefixes
from ONE accept makes it read `MISSED=2` (`extra_free`, `extra_ry_on_rail`);
restoring them returns `MISSED=0`. The other five mutations stay caught because
the positional `CHECK-NEXT` stream sees insertions — which is the fixture design
working, not the matrix failing.

---

## §5 e2e — 5 slices + 1 `compare_files` gate, all STRICT stage 2b

| entry | witness |
|---|---|
| `e2e-slice-control-inplace-ry-bool-diamond` | a STATED REDUCTION against the committed COMPARE twin `slice_control_inplace_ry.expected.log`: delete the mint, the strip and the flag's free; rename the flag handle to the register's. **10 trace lines become 7.** |
| `e2e-slice-control-inplace-ry-bool-negated` | + its manual twin + **`e2e-inplace-ry-bool-negated-twin-identical`** |
| `e2e-slice-control-inplace-ry-bool-negated-twin` | `r = cq_theta(r,0.9); if (b) r = cq_theta(r,-0.9);` — BYTE-IDENTICAL to the subject (measured, `diff` empty) |
| `e2e-slice-control-inplace-ry-bool-stateprep` | stated reduction against `slice_control_inplace_ry_stateprep.expected.log` |
| `e2e-slice-control-inplace-ry-bool-stateprep-negated` | **the owner's second region in isolation** |

**NO `compare_files` gate on four of the five, deliberately** — the drbq Inc-4
precedent: their compare twins are already committed and this family's goldens
are those files MINUS THREE LINES, so a byte-identity gate would assert something
FALSE. Each header states its own reduction so a reviewer can re-derive it.

**THE ONE REAL `cmp` GATE IS THE NEGATED PAIR, and it is available only because
of HOW negation is spelled** — Ry additivity produces exactly the stream a
programmer would hand-write, so the two are comparable. ⚠ It is labelled an
INTERNAL-CONSISTENCY gate in the CMake block and in both slice headers: both
halves need l4x4.b to lower and both decline on `main`.

**THE OWNER'S ISOLATED SECOND REGION, read line by line off the golden:**

```
cqrt_alloc_i1(0) -> h0
cqrt_ry_i1(h0, 0x1p-1)
cqrt_alloc_i1(0) -> h1
cqrt_ry_i1(h1, 0x1p-1)
cqrt_ry_i1_controlled(h0, h1, -0x1p-1)
cqrt_measure_i1(h0) -> 0
cqrt_measure_i1(h1) -> 0
```

— exactly the brief's §4 prediction: no `cqrt_x`, no free, seven lines, all gates.

**MEASURED COUNTS at hand-off** (by command, not by adding up hand-backs):
`ls ir-pass/test/*.ll | wc -l` → **1810**;
`ls tests/e2e/*.expected.log | wc -l` → **349**;
`ctest -N` → **396** (`^e2e-` **386**, `^e2e-slice-` **347**, `twin-identical`
**29**). Against `main` 0c7380c those were 1776 / 341 / 387 / 377 / 339 / 28, and
Track C contributes +8 fixtures, +3 goldens and +3 ctest entries of the delta.
`git status --porcelain runtime/ tools/ include/` → **0 lines**: no new runtime
symbol, no YAML row, no header change (owner D3).
`git status --porcelain tests/` after the e2e gate: only the five new `.c`, the
five new `.expected.log`, `CMakeLists.txt` and the one amended slice header — **no
pre-existing golden regenerated.**

---

## §6 CORPUS DIFF — THREE-WAY

`probes/impl/sweep.py`: every fixture through all three binaries, comparing exit
code, the `cq … lowering: <reason> under quantum control` string, and the lowered
stdout. Run against a FROZEN COPY of the final binary
(`cmp`-verified identical to `build/ir-pass/cq-opt` afterwards; the IMPL_f2 §5b
lesson — never relink under a running measurement).

```
files=1784
ORACLE -> F2   rc/diag movers: 23     <- ALL Track C's, none mine
F2 -> SUBJ     rc movers:       2
    control_inplace_ry_reject_raw_i1_cond.ll                 rc=1 bare i1 register condition -> rc=0
    control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll rc=1 bare i1 register condition -> rc=0
F2 -> SUBJ     DIAGDIFF: 0
F2 -> SUBJ     OUTDIFF:  0
```

**Exactly as the brief requires: DECLINE → ACCEPT only, both carrying `bare i1
register condition`, both listed.** The 23 ORACLE→F2 movers are Track C's 19
flips plus its 4 new accepts, every one on the F2 string — attributable to the
base, not to this increment. **0 DIAGDIFF** means no diagnostic string moved
anywhere in the corpus; **0 OUTDIFF** means the 1782 fixtures that did not move
emit BYTE-IDENTICAL lowered IR — which is the witness that the `lowerRotations`
two-pass reordering (§2b part 2) really is a no-op without a rail control.

Non-comment production delta (`git diff -U0`, comment and blank lines filtered):
**+183 / −29** across four files (`ArmClassify.cpp`, `SwapRouteEmit.cpp`,
`RotationLowering.cpp`, `TaintPropagation.h`). **No new runtime symbol, no
`tools/opcode_table.yaml` change, no `include/` change** — every width this path
reaches already has a declared and defined `cqrt_ry_<W>_controlled`.

---

## §6b GATES (Rule 19), in the brief's order, verbatim

1. **`lit --filter` per fixture** — every one of the 28 new/rewritten fixtures
   verified individually as it was written.
2. **`ctest -R ir-pass-lit`** — `1/1 Test #8: ir-pass-lit ... Passed 52.76 sec`.
   Full summary (`lit -s ir-pass/test`):
   `Total Discovered Tests: 1810 · Passed: 1809 (99.94%) · Expectedly Failed: 1
   (0.06%)`, 82.55 s. (The 1 XFAIL is the pre-existing
   `lowering_invert_add_i32.ll`, a Phase-7 tracker.)
3. **`ctest -j6 -R '^e2e-'`** — `100% tests passed, 0 tests failed out of 386`,
   `Total Test time (real) = 1736.62 sec`, including
   `e2e-loop-twin-matrix ... Passed 965.79 sec` — the ONE instrument that can see
   a leaked TEMPLATE-minted rail (H-5 / H-7), with **no cell moved and no
   quarantine churn**. `git status --porcelain tests/` afterwards showed only the
   five new `.c`, the five new `.expected.log`, `CMakeLists.txt` and the one
   amended slice header — **no pre-existing golden regenerated.**
4. **Full `ctest -j6`** (Rule-19 gate moments 1 and 5 — a Rule-13 lowering-core
   change AND a moved accept/decline predicate) —
   `100% tests passed, 0 tests failed out of 396`,
   `Total Test time (real) = 1367.51 sec`.
5. **`cq-opt-equivalence-full`** — run because this increment ADDS a diagnostic
   string (`controlled rotation control handle`, `RotationLowering.cpp`), so the
   routine SAMPLED entry (`--stride 8`) is not enough:
   `cq_opt_equivalence: compared 1810 fixtures, 0 mismatch(es)`.
   (`cq-opt` re-verified `cmp`-identical afterwards — the target's rebuild step
   was a no-op.)

⚠ **NOTHING WAS REBUILT UNDER ANY MEASUREMENT** (the IMPL_f2 §5b lesson: a
`--target` relink makes `build/ir-pass/cq-opt` vanish for a second and kills
anything holding a path to it). The corpus sweep ran against a frozen copy; the
only edit made after the full suite was COMMENT-ONLY, and the rebuilt
`cq-opt` and `libCQPass.so` are **`cmp`-verified BYTE-IDENTICAL** to the copies
the sweep and the suite used — so both results stand for the tree as it is.
No process was ever killed by pattern.

---

## §7 OPEN QUESTIONS AND FOUND-IN-PASSING

**Q1 — H-2 IS LOAD-BEARING AT THIS CONSUMER, AND THE MUTATION IS THE PROOF.**
With `markRailCondRead` disabled at both new sites, `probes/impl/multi/w2`
(two TUs of plain C through the shipped 6.5 recipe) compiles at **`opt` exit 0,
verify-clean**, with

```
cq_template_icmp_ne_i32_hl(%out, 0) -> h    <- x's rail
cqrt_ry_i1(h, 0.25)                         <- b  = θ(x,.25)
cqrt_ry_i1(h, 0.9)                          <- b3 = θ(x,.9)  ** SAME RAIL **
cqrt_ry_i32_controlled(h, h2, 0.9)          <- controlled on Ry(.9)Ry(.25)|x>
```

i.e. the arm fires controlled on a register the source's condition does not name
— F-B1R2-1 at a new consumer. With the record in place it declines loudly. Both
rungs are pinned (`w2` rung (iii), `w3` rung (ii)).

**Q2 — FOUND IN PASSING, PRE-EXISTING, NOT MINE: a 6.5 classical-call-arm region
IMMEDIATELY followed by a flat control region declines `control flow`.**
`lowerControlRegions`' hcrg precedence graph resolves `A.Pred == B.MergeBB` only
when BOTH regions are `BranchRegion`/`PhaseKickback` (`sequentialChainAlias`'s
`reorderable()`); a `ClassicalCallArm` `B` is an unresolvable alias and
`declineRegion` fires. **MEASURED ON `main` WITH THE COMPARE TWIN**
(`probes/impl/multi/w1c_caller.c` — `control flow` on ORACLE, F2 and here), so it
is arm-class-independent and predates every branch in this session. It cost real
work here: the H-2 fixtures had to interpose an opaque classical diamond
(`w2`/`w3`) to move the rail region out of that block. ⚠ **NOW FILED** (round-1
review F-3, which re-measured it independently and confirmed the mechanism by
reading `SwapRouteEmit.cpp:2459`'s `sequentialChainAlias` → `reorderable()`):
**bd `test_C_libtooling-35t0`**, P2, pre-existing on `main` 0c7380c. The line
"Not filed — out of brief" is superseded; it stays visible because the reason it
was not filed at hand-back (out of brief) is the reason a reviewer had to find it
twice.

**Q3 — `t10` IS NOT THE F-1b-1 CLASS AT `-O1`, so the fixture SCOPE §4.1 asked
for would have pinned nothing.** Its seed is the constant `false`, which `-O1`
const-folds into BOTH siblings' arg-0, making them two SOURCE thetas on two
SEPARATE rails; the program is correct and ACCEPTS (measured: two
`cqrt_alloc_i1`, the gate on the one the branch names). The real sibling shape
needs a TAINTED seed — `probes/impl/p1_sibling_theta_real.c`, which is what
`..._reject_rail_sibling_theta.ll` is built from. The lesson is SCOPE's own, one
level down: a probe measured only through the `bare i1` gate says nothing about
what is behind it.

**Q4 — `t16b` ACCEPTS where SCOPE §2.5 predicted an F2 collision, and that is
Track C, not a hole.** An `i1` seed under an `i1` condition collides on BOTH
edges by construction; the 2026-09-11 narrowing excludes values on the
CONDITION'S OWN BACKWARD WIRE, and the rail IS the condition. The α theorem
covers it — the RIVAL (`if (b) b = cq_theta(b, θ)`) is refused, measured, at
`state prep merged with a quantum register` (`probes/impl/p3`). Pinned as
`control_inplace_ry_stateprep_rail_i1_seed.ll`, whose header names both walls.

**Q5 — R4 IS A BACKSTOP ON THIS PATH, NEVER THE FENCE THAT FIRES, and the header
of `..._reject_rail_cond_wire.ll` says so.** For a rail, an arm gate on the
condition's own wire is refused by rung (iii) several clauses before R4's
`railWireClosure` intersection is computed. R4 still runs (`if (!StatePrep)`);
the absence of `rotation arm on a condition wire` in this family must not be read
as evidence it was dropped. Whoever widens rung (iii) inherits R4's obligation.

**Q6 — THE TWO-ARM RAIL IF/ELSE AND THE Ry-STEM ANGLE SELECT ARE DEFERRED, not
refused on physics.** The if/else stream is `ry(h,B); cry(h_b,h,−B); cry(h_b,h,A)`
— three gates, NO SUBTRACTION AT ALL, which is numerically strictly better than
the angle select's `A−B` and is worth recording as the option for retiring the
Inc-2b constant-arms-only narrowing later. Pinned as
`..._reject_rail_ifelse.ll`; the angle-select half is **l4x4.a** and
`control_angle_select_reject_rail_ry.ll` now carries a note saying the increment
split and which half owns it.

**Q7 — RECORDS NOT UPDATED HERE, because the brief scoped §5 to this file.**
`CLAUDE.md`, `ROADMAP.md`, `retire-swap-route-PRD.md` / `control-in-place-PRD.md`,
and the bd issues (`l4x4` → `l4x4.a`/`.b`/`.c`, plus the memory
`retire-swap-route-3qlq`) all still describe 1b-C as one unbuilt increment and
still cite the two renamed fixtures by their old names. Two LIVE references I DID
fix, because a dangling path in a shipped header is a defect I introduced:
`tests/e2e/slice_control_inplace_ry_stateprep_bool.c` and
`ir-pass/test/control_inplace_ry_stateprep_bool_seed_int_cond.ll`. The rest are
dated session records and were deliberately left alone.

---

## §8 ROUND-1 RULE-13 REVIEW (`review_l4x4b_r1.md`, verdict CLEAR-WITH-ITEMS) — the fix

Five items (F-1..F-5) plus the H-9 documentation item. **One of them was a wrong
unitary and the other five are records.** The review's two headline questions —
does the whole-DAG spine ever free the entangled control register, and can any
reader be placed between the negation's two gates — were both established ABSENT,
structurally and by measurement, so nothing below is a re-litigation of the
mechanism.

**Q8 — F-1's RESIDUAL AND THE OWNER OPTION THAT REMOVES IT. Read this before
widening or narrowing the negated form.**

What shipped: a non-finite **CONSTANT** angle on the negated rail arm now declines
`rotation angle` (`ArmClassify.cpp:3090`, the shared `constantAngleIsNonFinite`);
a **RUN-TIME** angle keeps accepting.

The argument for that split, in full, because "we could not fence it" is not one:

* The negated form emits the user's ONE angle into TWO gate slots —
  `ry(h_r, θ)` unconditionally and `cry(h_b, h_r, −θ)` — so the `b = 1` branch,
  where the source is the IDENTITY, composes `Ry(−θ)·Ry(+θ)`. That is `I` for
  every FINITE θ and NaN otherwise.
* **`fneg` cannot manufacture a non-finite value from a finite one.** It flips one
  sign bit. This is the whole difference from Inc-2b's by-difference form, whose
  `fsub` overflows to `inf` from two perfectly ORDINARY FINITE arms (measured
  there at `±8.98846567431158e307`) — which is why that increment's clearance
  blocker **F-11 ruled run-time arms out** and why **its structure does not
  transfer here**. There is no class of well-formed input this compiler cannot
  see.
* So the ONLY failing input is an angle that was ALREADY non-finite — an
  ill-formed CQ program in EVERY spelling. `Ry(NaN)` lands on the taken branch of
  the compare twin too, and an uncontrolled `cq_theta(q, inf)` lowers to
  `cqrt_ry_<W>(h, inf)` on every binary in the tree (the distinction
  `control_angle_select_reject_inf_arm.ll`'s header already draws). What the
  negated form ADDS is corruption of the UNTAKEN branch of that already-broken
  program. For a constant the compiler can see it, so it declines; for a run-time
  value it cannot, and refusing every run-time angle to protect a program that is
  broken anyway would be a total over-decline of the shipped accept class
  (Rule 17).

**THE RESIDUAL, stated plainly: a run-time angle that is non-finite AT RUN TIME
produces `Ry(−∞)Ry(+∞)` on the branch the source leaves alone.**

**THE OWNER OPTION THAT REMOVES IT ENTIRELY — NOT BUILT, and deliberately not**
(Rule 17's other half: do not smuggle a design change into a review fix).
`SCOPE_l4x4.md` §2.3 **option B**, the bd `r9e5` 1b-B.1 `CopyRailRoot` ancilla
with the `cqrt_x` bracket **ON THE ANCILLA** — never on the user register, which
Inc 1b forbids:

```
bf = cqrt_alloc_i1(0); cqrt_cnot(h_b, bf); cqrt_x(bf);
cqrt_ry_<W>_controlled(bf, h_r, θ);
cqrt_x(bf); cqrt_cnot(h_b, bf); cqrt_free(bf)
```

**4 extra gates + 1 ancilla, and it fires exactly ONE rotation**, so it is exact
for EVERY angle — non-finite and run-time alike — and it would also retire the
one-content-arm fence (§1 row `2954`), because anti-control stops needing
additivity. The cost beyond gates is plumbing: `CondTreeEmit`'s `CopyRailRoot` is
written for `emitCondNetwork`, which `classifyArms`' path does not use. **Owner
decision, with `fg9k` / `54ur` as the other customers for the same mechanism.**

**Q9 — F-4: TWO OF THIS SESSION'S OWN PROBES DID NOT MEASURE WHAT THEIR HEADERS
CLAIMED, and the §2.6 CLASSICAL-CALL and EQ-FOLD rows have NO dedicated fixture.**
Measured on the fix binary: `impl/p5_classical_call_arm_rail.c` has **0 `br i1`
and 2 `select i1`** after `-O1` — the `noinline const` callee's arm folds to a
`select i32`, so `classifyClassicalCallArm` is never reached and the program is
compiled by bd `r9e5`'s 1b-B.1 rail DATA-SELECT (`cqrt_alloc_i1; cqrt_cnot;
2 × cqrt_copy_i32_controlled; cqrt_x; cqrt_cnot; cqrt_free`). `impl/p6_eqfold_rail.c`
contains no equality at all and emits `cqrt_rz_i1` — the Inc-1b branch-phase
KICKBACK. Both probe headers now carry the measurement and say outright that they
pin neither §2.6 row; **`probes/README.md` says the same.** What actually fences
those two classes is `classifyClassicalCallArm`'s own `isa<CmpInst>` early return
(unchanged, verified by reading) and `declineRailClass()` at the eq-fold accept
site — **read, not measured, and now recorded as such rather than as coverage.**
A probe that measures a different lowering is worse than no probe, because it
reads like coverage: this is the DER lesson one level down, and it is the second
time in this session's records (§7 Q3, `t10`).

**Q10 — F-5: the VALUE class on a rail has TWO EXITS.** `t16_i1_stateprep`
(`_Bool r; if (b) r = cq_theta(0, 0.9);` — the `int` overload leaves an `icmp ne`
in the arm) declines **`value-arm swap-route`**, from the `isValueChangingOp(Base)`
clause ABOVE the §2.6 re-decline, not `bare i1 register condition`. Still loud,
still refusing bd `fg9k`'s class, and the disposition is unchanged by this fix —
but `SCOPE_l4x4.md` §2.6's one-cell-per-class table read as though the row always
answers the one string, and a future `fg9k` reviewer greping for it would have
found a hole that is not there. Pinned now by
`control_swap_reject_value_rail_cond_early_clause.ll` beside the existing
`control_swap_reject_value_rail_cond.ll`; SCOPE §2.6 carries an ERRATA block that
also warns the caution is NOT individually measured for the other DECLINE rows.

**Q11 — H-9: the spine's exclusion of the control register has a SECOND, STRONGER
reason, and the increment's record rested on the weaker one.** §3 above argues
from `preservesBasisUnderRecord`'s `_controlled` disqualify list. True — but a
rail leaf is BY DEFINITION a `cq_theta_i1` result, so its register ALWAYS carries
an **uncontrolled `cqrt_ry_i1`**, which that predicate refuses by the decisive
corollary at its own header (cond = ∅ and not trivial on `|0⟩`), **independently
of every row in the `_controlled` list**. Written at both sites
(`ChainWalk.cpp`'s `preservesBasisUnderRecord` header and the
`if (N.contains("_controlled")) return false;` bail in `isInPlaceGateOn`), because
it is the argument that survives a future widening of that list — the day a new
`_controlled` stem is admitted there, the six emitters named at that site need
re-reading and a bare-`_Bool` control does not.
