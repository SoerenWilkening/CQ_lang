# SCOPE — bd `test_C_libtooling-l4x4`, sub-increment 1b-C: the in-place controlled-Ry arm, the controlled STATE PREP, and the Ry-stem ANGLE SELECT on a bare `_Bool` (rail-root) condition

Session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-11, measured at **`main` 0c7380c**
(`git status --porcelain` empty, so every verdict below is the **landed `main` binary**
`build/ir-pass/cq-opt`, not an in-progress tree).

**READ-ONLY.** Nothing under `ir-pass/`, `include/`, `runtime/`, `tests/` or `tools/` was
touched. Probes live in `probes/` beside this file, with their own `README.md` and the exact
commands; the scratch copies are in
`/private/tmp/.../scratchpad/l4x4/`.

Companions: `../session-3qlq4/` (Inc 1b — the bare `_Bool` condition for `cq_phi`, the rail
ladder this increment mirrors), `../session-r9e5/BRIEF_B1.md` + `SCOPE_B2.md` (1b-B.1, the
4.4 DATA select on a rail; B.2's scoping, which shares `classifyArms`' first gate with this
increment and is the reason §2.6 exists).

Every line number is as of 0c7380c. `bd r9e5`'s landing (d33a34a) moved `ArmClassify.cpp`,
`SelectClassify.cpp`, `CondTreeEmit.{h,cpp}` and `SelectMergeEmit.cpp`; re-grep before editing.

---

## 0. HEADLINE — measure first, and three of the measurements change the shape of the increment

The bd description scopes 1b-C as three shapes with one lowering: *"`cqrt_ry_<W>_controlled(h_b,
h, θ)` with the REGISTER as the control; no mint/strip/free."* That is right, and the probe
family adds four facts the description could not have:

1. **The `if/else` half is not a diamond at all.** From plain C at `-O1` it is an **angle
   select**, so it belongs to `AngleSelectEmit`'s Ry stem, not to
   `emitInPlaceRotationRegion`'s two-arm path (probe `t2`). That half is also **by far the
   cheapest** — `AngleSelectEmit` already has the rail branch written for the phase stem
   (`AngleSelectEmit.cpp:185`, `Value *Flag = RailCond ? Cond : lowerCompareToFlag(…)`) and the
   Ry stem emits **no `cqrt_x` at all** (measured on `t2c`).
2. **`if (!b)` is plain-C reachable and it is the increment's one genuine design decision.**
   The compare twin lowers a negated arm with a `cqrt_x(flag)` **bracket** (measured, `t7c`),
   and Inc 1b's non-negotiable invariant is *never a `cqrt_x` on a user register*. The phase
   path escapes through the diagonal identity `X·P(θ)·X = e^{iθ}·P(−θ)`; **a controlled Ry has
   no such identity**. §2.3 enumerates the options and recommends one.
3. **The IN-LOOP rail form is a capability the COMPARE form structurally cannot express** —
   and therefore has no twin to be byte-identical to. `t5` (invariant `b`, loop-carried `r`)
   reaches `classifyArms`; its compare twin `t5c` declines `condition predates a non-diagonal
   gate`, because `-O1` LICM-hoists the invariant compare out of the loop and
   `condWireDisposition`'s P4 prong (`Cond->getParent() != R.Pred`, `ArmClassify.cpp:1729`)
   refuses a cross-block condition. `railCondWireDisposition` (`:1803`) deliberately **has no
   P4 prong**. That is CLAUDE.md row W with its subject removed.
4. **"Ry on the condition's own wire" is not caught by R4/S8 from plain C.** `-O1` folds the
   arm's `cq_theta(b, θ)` to `cq_theta_i1(i1 true, θ)` — a **STATE PREP**, for which R4 and R6
   are *skipped* (`ArmClassify.cpp:3147`, `if (!StatePrep)`). The fence that actually fires on
   the compare twin is **F1's second clause**, `state prep merged with a quantum register`
   (`ArmClassify.cpp:2836`). Probe `t6` / `t6c`. Scoping a "clobber" decline onto R4 would pin nothing.

### 0.1 The measurement table

All rows: `clang -O1 -Iinclude -include CQ.h -emit-llvm -S` → `build/ir-pass/cq-opt
-load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S`; the anchor from
`CQ_CTRL_DBG=1`. `brs`/`sel` are `br i1` / `select` counts in the stage-1 IR.
Diagnostics are quoted without the `cq controlled lowering: ` prefix and the
` under quantum control` suffix.

| probe | shape | `-O1` | `main` 0c7380c | anchor / site |
|---|---|---|---|---|
| `t1` | **(1)** in-place Ry arm, register disjoint from `b` | diamond, `brs=2` | `bare i1 register condition` | the rail — `ArmClassify.cpp:2389-2395` |
| `t1c` | its COMPARE twin (the shipped drbq Inc-1 flagship) | diamond | **ACCEPT**, 10 gate lines | — |
| `t2` | **(2)** the `if/else` twin | **`select i1 %1, double 0.9, double 0.3`**, `brs=0 sel=2` | `bare i1 register condition` | the SELECT — `ArmClassify.cpp:5662` (S4) |
| `t2c` | its COMPARE twin | angle select | **ACCEPT** — `ry(h1,0.3)` + `ry_i32_controlled(f,h1,0x3FE3333333333334)`, **no `cqrt_x`** | — |
| `t3` | **(3)** state prep, `int` seed 7 | diamond; merge Pred incoming `i32 7` | `bare i1 register condition` | the rail |
| `t3c` | its COMPARE twin (drbq Inc-4 shape) | diamond | **ACCEPT** — `alloc_i32(7)` + `ry_i32_controlled(f,h1,0.9)` | — |
| `t4` | **(4)** an `i1` ROTATED register under an `i1` condition (two rails) | diamond, `cq_theta_i1(i1 %2, 0.9)` — genuinely CHAINED | `bare i1 register condition` | the rail |
| `t5` | **(5)** Ry arm in a classically-bounded loop, `b` INVARIANT | loop; rail in ENTRY, `br` in the header, `r` a header φ | `bare i1 register condition` | the rail |
| `t5c` | its COMPARE twin | loop | `condition predates a non-diagonal gate` — **row W**, the LICM-hoisted invariant compare | `icmp` |
| `t6` | **(6)** Ry ON the condition's own wire | diamond; arm folds to `cq_theta_i1(i1 true, 0.9)` = a STATE PREP | `bare i1 register condition` | the rail |
| `t6c` | its COMPARE twin | same fold | `state prep merged with a quantum register` — **F1 clause 2**, NOT R4 | `theta` |
| `t7` | **(7)** negated `if (!b)` | **orientation-B** diamond (`br i1 %1, merge, arm`) | `bare i1 register condition` | the rail |
| `t7c` | its COMPARE twin | diamond | **ACCEPT** — `cqrt_x(f)` … `ry_i32_controlled` … `cqrt_x(f)` | — |
| `t8` | **(8)** the S† after the region | diamond + post-region `cq_theta(b,−0.5)` | `bare i1 register condition` | the rail |
| `t8c` | its COMPARE twin | diamond | **ACCEPT** — strip, free, then `cqrt_ry_i32(%h,−0.5)` | — |
| `t9` | **(9)** `b` MEASURED before the branch | diamond | `bare i1 register condition` (the gate pre-empts rung (ii)) | the rail |
| `t10` | **(10)** SIBLING theta on `b`'s parent rail (the F-1b-1 class) | diamond, `brs=1` | `bare i1 register condition` (the gate pre-empts rung (iii)) | the rail |
| `t11` | `b` DEAD after the region | diamond | `bare i1 register condition` | the rail |
| `t11c` | its COMPARE twin | diamond | **ACCEPT**; `%h` is **never freed** — a Rule-6 safe leak | — |
| `t12` | in-loop, `b` LOOP-**VARIANT** (rotated in the body) | header **φ** condition | `control flow` — **NOT a rail leaf** (bd `boi6`) | — |
| `t13` | TWO sequential regions on one rail (Ry arm, then a kickback) | 2 diamonds | `bare i1 register condition` | the rail |
| `t14` | the rail also read as DATA after the region (`r + (int)b`) | diamond | `bare i1 register condition` | the rail |
| `t15` | DERIVED rotated base (`r = p*5`) — the Inc-1 structural-freeze shape | diamond | `bare i1 register condition` | the rail |
| `t16b` | `i1` STATE PREP (`cq_theta((_Bool)0, θ)`) under a rail | diamond | `bare i1 register condition` — and F2 collides by design, §2.5 | the rail |
| `t17` | **f64** rotated register under a rail | diamond | `bare i1 register condition` | the rail |
| `t18` | COMPOUND condition `b && q > 5` + Ry arm | `select i1` condition, `brs=1 sel=1` | `control flow` — a `select i1` is not a rail leaf | — |
| `t18c` | its COMPARE twin | same | `control flow` — **compound is out for BOTH spellings** | — |
| `t19` | if/else rotating TWO DIFFERENT registers | folded | `control flow` (R3, one base) | — |
| `t20` | angle select with the rail defined in a DIFFERENT block | select | `bare i1 register condition` (S6 would then over-decline — H-6) | the SELECT |
| `t21` | Ry-stem angle select on an invariant rail INSIDE a loop | select in the body | `bare i1 register condition` (S7 would then say `control flow inside a loop body`) | the SELECT |
| `t22` | angle select with RUN-TIME arms | select | `rotation angle` — **unchanged by 1b-C** (the Inc-2b clearance narrowing fires first) | — |
| `t23` | rail measured AFTER the region + a data use of the merge (`r*3`) | diamond | `bare i1 register condition` | the rail |
| `t24` | R6: a pre-region record (`mark = r`) read after | diamond | `bare i1 register condition` | the rail |
| `t24c` | its COMPARE twin | diamond | `stale rail record read past a controlled Ry` — R6 | the reader |

**Reading of the table.** Ten of the eleven ACCEPT-candidate shapes (`t1 t2 t3 t4 t5 t7 t8 t11
t13 t14 t15 t17 t23`) die at ONE of two sites — `ArmClassify.cpp:2389` for a `br` diamond and
`ArmClassify.cpp:5662` for an angle select — and nothing downstream of either has been asked
about a rail. That is the whole increment: two gates, one ladder, two emitters, and a decline
partition for the five arm classes that are NOT 1b-C's.

---

## 1. Every site that assumes a `CmpInst`, and what a rail root needs instead

The ladder to mirror is `classifyPhaseKickback`'s **step 5b** (`ArmClassify.cpp:4178-4210`) plus
its wire question at `:4305-4311`, exactly as 1b-B.1 mirrored it at the select
(`SelectClassify.cpp:812-851`). Three rungs, no more:

* **(i) tainted** — `Taint.Tainted.count(Rail)` (defence in depth; `cq_theta_i1` *is* the source);
* **(ii) not measured before the READ POINT** — `railMeasuredBeforeReadPoint`
  (`ArmClassify.cpp:1915`), asked over `railWireNamesBackward`'s wire closure (`:1868`) and
  **not** over `Rail->users()` — the round-1 F-B1R1-1 widening;
* **(iii) the WIRE question** — `railCondWireDisposition` (`:1803`), which is
  `condWireDisposition` MINUS the P4 cross-block prong, MINUS the P5 positional scan and MINUS
  the `ShareCondFlag` clause, with the DT prong (`DeclineNow` ⇒ decline; `None` /
  `ProvenPostRegion` ⇒ accept).

And nothing else: `condDataUseDisposition` / `HasDataUse` / `ShareCondFlag` have **no subject**
for a rail — nothing is minted from the register, so no flag can be shared or outlive the
region (the same argument `classifyPhaseKickback` records with its own `HasDataUse` guard at
`ArmClassify.cpp:4250-4257`, and `SelectClassify.cpp:840-851` restates).

### 1.1 `ArmClassify::classifyArms` (`ir-pass/src/ArmClassify.cpp:2379-3459`)

| line | site | today | what a rail root needs |
|---|---|---|---|
| **2389-2395** | `if (!isa<CmpInst>(Region.Condition))` → `kBareRailCondReason` | **THE GATE.** Every rail-condition diamond dies here (measured on 13 probes). | Widen to `isa<CmpInst> \|\| isCondRailLeaf`, insert the three rungs immediately after, and **re-decline per ARM CLASS** below (§2.6). |
| **2406** | `comparePredLowerable(cast<CmpInst>(…))` → `control condition has no template` | predicate has a template | **SKIP** — a rail has no predicate and nothing is minted from it. |
| **2425-2444** | the `HasDataUse` loop over `Region.Condition->users()` + `condDataUseDisposition` → `Region.ShareCondFlag` | the ziov shared-flag path | **SKIP ENTIRELY.** For a rail this is not merely inapplicable, it is *wrong about the wrong object*: `t1`'s rail has a `cq_measure_i1` user, so `HasDataUse` is TRUE for the increment's own flagship and the register would be adjudicated as a flag lineage. Replace with rung (ii). (H-7.) |
| **2460** | `condProvenance(Region.Condition, Taint, Prov)` | backward tainted provenance | **UNCHANGED and already correct.** `condProvenance` inserts `V` when tainted then `if (isThetaCall(I)) continue;`, so for a bare rail `Prov == {rail}` exactly — which is what makes S8/R4 work below. |
| **2468-2470** | `condWireDisposition(…)` → `condition predates a non-diagonal gate` | the wire question | Dispatch on the root: `RailCond ? railCondWireDisposition(…) : condWireDisposition(…)`, spelled EXACTLY as `classifyPhaseKickback:4310-4311` does. `condWireDisposition` returns `DeclineNow` unconditionally for a rail (P4: the rail's block is the pred for `t1` but is the ENTRY block for `t5`, and P5 would scan the whole gap). |
| **2483-2490** | `DeferredWireGate` + the `declineArm` re-speller | keeps downstream strings byte-identical when P1 defers | **UNCHANGED** — condition-agnostic wrapper. |
| **2324** (called at **2587**) | `straightThroughConstFoldHandle` — `dyn_cast_or_null<ICmpInst>` | the 4.5 eq-fold re-anchor | **BENIGN MISS**, returns null. There IS a rail analogue (the branch pins `b` on its edges) and it is deliberately NOT built: an unbuilt re-anchor can only OVER-decline. Say so at the site so a later widener does not read the miss as a proof. |
| **2661-2663** | `inPlaceRotationArmTheta(…, StatePrep)` | the ARM recognizer | **UNCHANGED** — arm-block-bounded, never touches `Region.Condition`. |
| **2673-2695** | R2 tainted angle / R7 `ShareCondFlag` / R7 `AnglePhi` | | R2 unchanged; the `ShareCondFlag` clause becomes structurally dead for a rail (kept as the Rule-1 backstop). |
| **2713-2765** | the if/else state-prep split (`allocates two rails` / `beside a chained or phase arm`) | owner ruling | **UNCHANGED** — arm-side. |
| **2801 / 2836 / 2879** | **F1**, three clauses | seed is `ConstantInt`/`ConstantFP`, equals the merge's Pred incoming bit-for-bit, and matches the callee suffix's width | **UNCHANGED and it is the fence that does the work** — it is what declines `t6` (merge Pred incoming is the TAINTED rail ⇒ `state prep merged with a quantum register`). Verified by the compare twin `t6c`. |
| **3000 / 3029** | **F2**, the literal fast path + `f2SeedPinnedByLiveRegister` | the edge-pinned-seed fence | **UNCHANGED, and it works for a rail with no edit at all** — §2.5. The fast path's `dyn_cast<ICmpInst>` misses (benign); the semantic half reads `BI->getCondition()` (`ArmClassify.cpp:1203`) and enumerates every tainted integer value dominating `BI`, which for a rail condition includes the rail itself, pinned to `{1}`/`{0}` on the two edges. |
| **3070-3158** | **R4** `railWireClosure` ×3 + the `CondRails` intersection | disjoint physical wires | **UNCHANGED and correct for a rail**: `railWireClosure` takes a `Value *`, and with `Prov == {rail}` the condition side is exactly the rail's backward closure. ⚠ SKIPPED whole for a state prep (`if (!StatePrep)`, `:3147`) — which is why `t6` needs F1 and not this. |
| **3161-3330** | **R6** (`:3161`) + R7's loop half (clauses (b)/(b′)) | stale record / rollability | **UNCHANGED**. R7 (b) asks whether some `BaseWire` member is a header φ; for `t5` it is (`%10`). (b′) calls `railPhiRootMint`. Both are questions about the ROTATED register, not the condition. §2.4. |
| **3720** | the P1 fence `DeferredWireGate && (SawValueArm \|\| !(SawPhaseArm \|\| SawRotationArm))` | value arms keep the position-free reading | **UNCHANGED IN FORM**, and it is what makes `t8` (the S†) lowerable: `railCondWireDisposition` returns `ProvenPostRegion` and `SawRotationArm` is set, so P1 admits it. Note this is the drbq Inc-3 widening (`SawRotationArm` added to the disjunct) already in the tree — 1b-C inherits it and adds nothing. |

### 1.2 `ArmClassify::classifyAngleSelect` (`ir-pass/src/ArmClassify.cpp:~5600-6040`)

| line | site | what a rail root needs |
|---|---|---|
| **5644** | `if (!Tree.Nodes.empty() \|\| Tree.Leaves.size() + Tree.RailLeaves.size() != 1)` | **UNCHANGED** — already counts rail leaves. |
| **5655-5657** | `RailCond = !Tree.RailLeaves.empty()`; `Cond` is the rail | **UNCHANGED** — already written. |
| **5661-5664** | `if (RailCond) { if (!IsPhase) { diagnoseUnderControl(Sel, kBareRailCondReason); return Declined; } … }` | **THE GATE.** Delete the `!IsPhase` decline; add rungs (ii) and (iii) for both stems (rung (i) is already there just below it). |
| **5694-5700** | S5 — `abiWidthHasControlledRotation` | **UNCHANGED.** MEASURED: the set is `{i1,i8,i16,i32,i64,f16,f32,f64,f80}` (`OpcodeSupport.cpp:300`) and `cqrt_ry_i1_controlled` … `cqrt_ry_f80_controlled` are all DECLARED AND DEFINED (`runtime/cq_runtime.h:229-237`). **No new frozen symbol** (owner D3), at any probe width including `t4` (i1) and `t17` (f64). |
| **5837-5897** | S7's three loop prongs (`:5839`, `:5894`) | **UNCHANGED** — `t21` must keep declining `control flow inside a loop body`. |
| **5910-5925** | **S6** — `Cond->getParent() == T->getParent()`, `Cond->comesBefore(Sel)`, and the positional theta scan over `(Cond, T)` | ⚠ **THE ONE PLACE THE RAIL NEEDS A DIFFERENT QUESTION.** Asked of a rail this is a *position* test on a `cq_theta_i1` DEFINITION, which for `t20` sits in another block — `NotApplicable` ⇒ the caller reports `rotation angle`, the wrong reason, and for a cross-block rail it is a pure over-decline (H-6). The rail analogue is rung (iii) (`railCondWireDisposition`-style, i.e. `findNonDiagonalWireGate` with the DT prong at `EmitPoint = T`), exactly the split `railCondWireDisposition` makes against `condWireDisposition`. Recommendation: ship the over-decline in the increment, pin it with a fixture that says so, and file the widening. |
| **5947-5955** | the `IsPhi \|\| IsPhase` early accept | **UNCHANGED** (the shipped rail path). |
| **5959-5986** | **S8** (`railWireClosure` at `:5978`, the decline at `:5985`) — R4 over `condProvenance` + `railWireClosure(Cond, …)` | **UNCHANGED and correct for a rail.** `railWireClosure` takes a `Value *`; `condProvenance` of a rail yields `{rail}`. This is the clause that declines "the angle select rotates the condition's own register". |
| **6011-6026** | **S9** — R6 with `T` as the barrier | **UNCHANGED** — a question about the ROTATED register only. |

### 1.3 `SwapRouteEmit` (`ir-pass/src/SwapRouteEmit.cpp`)

| line | site | what a rail root needs |
|---|---|---|
| **920** | `auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);` in `emitRegion`, with the loud bail at `:922-932` | **MUST MOVE** — a rail-condition region accepted by `classifyArms` dies here today. Widen to `Value *` with the loud bail kept for "neither compare nor rail". ⚠ `Cond` is also handed to `emitValueRegion` (`:962`) and used by the phase path (`:1134`, `:1202`, `:1235`, `:1272`); dispatch so those still see a `CmpInst *` or are unreachable for a rail. |
| **641** | `void emitInPlaceRotationRegion(const ControlRegion &R, BranchInst *BI, CmpInst *Cond, …)` | `Value *Cond`. Every use below is a `diagnoseUnderControl` anchor (fine on any `Instruction`) or one of the two compare-only steps. |
| **660, 675, 692, 706, 713, 735** | the `diagnoseUnderControl(Cond, "control flow")` plan-shape bails | anchor only — `cast<Instruction>(Cond)`; behaviour unchanged. |
| **728-731** | **step 1** `Value *Flag = lowerCompareToFlag(Cond, …); if (!Flag) return;` | **`Flag = RailCond ? Cond : lowerCompareToFlag(…)`** — byte-for-byte the substitution `emitPhaseAngleSelect` already ships at `AngleSelectEmit.cpp:185`. **Nothing is minted.** |
| **776-789** | **step 2** the per-arm hoist + the `cqrt_x(Flag)` **bracket** for a negated arm | ⚠ **THE DESIGN DECISION.** A `cqrt_x` on a user register is forbidden (Inc 1b). See §2.3. |
| **785** | `taint.ControlledRotations[G.first] = Flag;` | ⚠ **H-1 lives here.** The map value is a raw `Value *` (`TaintPropagation.h:164-166`) and the rail is a `@cq_theta_i1` CALL that `lowerRotations` RAUWs to an `i32` handle and then ERASES. §2.2. |
| **785** (same line) | — | **ADD `markRailCondRead(taint, Flag, G.first)`.** The hoisted theta IS the region's first `cqrt_*` read of the rail (it becomes the controlled gate). Omitting it re-opens F-B1R2-1 with no diagnostic anywhere (H-2). |
| **819-824** | **step 3** the strip `lowerCompareToFlag(…, inverse=true, railToStrip=Flag)` + `cqrt_free(Flag)` | **SKIP BOTH for a rail** — the register is the user's, there is nothing to strip and freeing it would be a hidden measurement (`Ry(θ)|0⟩ ≠ |0⟩`, Rule 6). The `taint.DischargedFlagGates` insert has no subject either. |
| **903-906** | **step 4** `MergePhi->replaceAllUsesWith(Gates.back().first)` (M-β), `scrubTaint`, erase, `flattenRegion` | **UNCHANGED.** M-β is correct for the Ry stem for the reasons at `:836-899`, and it is a *correctness requirement* for a state prep. `flattenRegion` already refuses to erase a rail condition (`RegionFlatten.cpp:96`, the 3qlq.4 guard). |

### 1.4 `AngleSelectEmit` (`ir-pass/src/AngleSelectEmit.cpp`) — the Ry stem

| line | site | what a rail root needs |
|---|---|---|
| **281-288** | `RailCond = isCondRailLeaf(CondI)`; the shape bail | **UNCHANGED** — already admits a rail. |
| **315-319** | `if (RailCond) { diagnoseUnderControl(Sel, kBareRailCondReason); return; }` | **THE GATE.** Delete; fall through to the Ry stem with `Cond` as a `Value *`. |
| **320** | `auto *Cond = cast<CmpInst>(CondI);` | `Value *`; guard the compare-only uses below. |
| **439-445** | step 0b's S4 semantic re-ask (`LTainted == RTainted \|\| !comparePredLowerable \|\| !compareFlagMintable`) | **GUARD with `isa<CmpInst>`** and substitute the rail form the phase stem already uses (`AngleSelectEmit.cpp:143-149`: `if (!taint.Tainted.count(Cond)) { diagnose("control flow"); return; }`). This is the F-V1-2 lesson one condition-kind over — do not merely skip it. |
| **447-498** | step 1, the `A − B` difference + `angleSelectArmsAdmissible` | **UNCHANGED**, including the constant-arms-only clause (2c). `t22` keeps declining `rotation angle`. |
| **~485-500** | step 2, the unconditional twin `T0` (registered at `:499`) | **UNCHANGED** — this is also the mechanism §2.3 option A reuses for the negated diamond. |
| **506-521** | **step 3** the flag mint | **`Flag = RailCond ? CondI : lowerCompareToFlag(…)`.** |
| **531-533** | step 4 `T->setArgOperand(0, T0); T->setArgOperand(1, D); taint.ControlledRotations[T] = Flag;` | **UNCHANGED** apart from H-1's handle question; **ADD `markRailCondRead(taint, Flag, T)`** (the phase stem's sibling is at `:211`). |
| **535-575** | **step 5** the strip (`:566`) + `cqrt_free` | **SKIP BOTH for a rail** — same argument as §1.3. |
| **251** | `if (!isCondRailLeaf(Cond) && Cond->use_empty()) { … erase … }` | **UNCHANGED** — already rail-aware. |

### 1.5 Sites that need NO change (verified by reading)

* `RegionFlatten.cpp:96` / `:189` / `:193` — the `!isCondRailLeaf(Cond)` guards, added by Inc 1b.
* `RotationLowering.cpp:318-322` — the controlled mint itself. `controlledRotationFn` is gated
  on the same `abiWidthHasControlledRotation` the classifier asks (one fence, two askers), and
  it takes whatever `Ctrl` the map holds. **Only H-1 touches this file.**
* `ChainWalk.cpp:319` `railCarriesControlledRotation` — §2.7; **no change, and the reason is
  load-bearing**.
* `ControlDetect.cpp` — the in-loop scope fences and `flatRegionRollableInLoop` already admit
  `t5` (measured: it reaches `classifyArms`).
* `Specialization.cpp:288` — already refuses any tree with `RailLeaves`.

---

## 2. The design

### 2.1 The target streams, read off the measured compare twins

**Shape A — the flat DIAMOND, un-negated (`t1`).** Ten gate lines become five:

```
%h_b = cqrt_alloc_i1(false)  ; cqrt_ry_i1(%h_b, 0.5)        ← the user's rail, untouched
%h1  = cqrt_alloc_i32(7)     ; cqrt_ry_i32(%h1, 0.25)
       cqrt_ry_i32_controlled(%h_b, %h1, 0.9)                ← the REGISTER as the control
       cqrt_measure_i1(%h_b) ; cqrt_measure_i32(%h1)
```

Against `t1c`'s golden this is the **REDUCTION**: delete the mint
(`cq_template_icmp_eq_i32_hl`), delete the strip (`…_hl_unc`), delete the `cqrt_free`, and
substitute `%h_cmp` → `%h_b`. Three deletions and one rename — the drbq Inc-4 witness form
(§4.3).

**Shape B — the controlled STATE PREP (`t3`).** `t3c`'s stream minus the same three lines:
`alloc_i1;ry_i1` for the rail, then `%h1 = cqrt_alloc_i32(7); cqrt_ry_i32_controlled(%h_b,
%h1, 0.9)`.

**Shape D — the Ry-stem ANGLE SELECT (`t2`).** `t2c`'s stream minus the same three lines:
`cqrt_ry_i32(%h1, 0.3)` unconditional, then
`cqrt_ry_i32_controlled(%h_b, %h1, 0x3FE3333333333334)`. **No `cqrt_x` anywhere**, measured.

**The control is always ONE qubit.** `isCondRailLeaf` is a `cq_theta_i1` result, so the rail is
a `cqrt_alloc_i1` — exactly the width a minted compare flag has. Nothing about
`cqrt_ry_<W>_controlled`'s semantics changes: the gate is still "controlled-Ry(θ) on each of
the W qubits of arg-1, controlled on the single qubit arg-0" (`docs/backend.md:1187`, the
tensored reading). 1b-C changes **who arg-0 is**, and nothing else.

### 2.2 H-1 — the control operand must be the rail's **HANDLE**, and the map cannot carry it today

`taint.ControlledRotations` is `DenseMap<const CallInst * /*theta*/, Value * /*flag*/>`
(`TaintPropagation.h:164-166`), a **raw `Value *`**. `lowerRotations` reads it at
`RotationLowering.cpp:226-228` and emits `CreateCall(CRy, {Ctrl, Handle, Angle})` at `:321`,
where `CRy` is typed `void(i32, i32, double)`.

For a compare condition `Flag` is a `cq_template_icmp_*_hl` result — already an `i32` handle,
minted by the emitter *before* `lowerRotations` runs. **For a rail, `Flag` is the
`@cq_theta_i1` CALL**, and two things then go wrong depending on the order `lowerRotations`
visits `taint.ThetaCalls`:

* **rail lowered FIRST** (program order, which is what `t1`/`t3`/`t2` all give): by the time
  the arm's theta is processed the rail's theta has been `replaceAllUsesWith(Handle)`-d and
  pushed onto `ToErase`. `It->second` still points at that call — an `i1` value with no uses,
  erased at the end of the loop. The emitted controlled call would take an **`i1` in an `i32`
  slot** and hold a use of a **soon-to-be-erased** instruction.
* **rail lowered SECOND**: the call is built with an `i1` operand and the later RAUW repairs
  it. A transient that heals — but only by luck of iteration order.

Neither is silent (the verifier catches the type, and the erase-with-a-use is an assert/abort),
so this is a **build-time blocker, not a miscompile risk** — but it is the drbq Inc-1
`Value *`-set-goes-stale shape wearing a new hat, and it must be fixed by construction:

* **(a) `WeakTrackingVH`** for the map's value type. It tracks RAUW, so the entry *becomes* the
  `i32` handle the moment the rail's theta is lowered. This is precisely why
  `TaintSet::RailCondReads` is already a `WeakTrackingVH` (`TaintPropagation.h:308-315`, and
  its comment names "a stage between `lowerControlRegions` and `reverifyRailCondReads` that
  RAUWs a `cq_theta_i1`"). Still order-dependent, and a nulled handle must be a **loud**
  decline, never a fall-through to the uncontrolled gate (which fires the arm on both branches
  — a wrong unitary; `RotationLowering.cpp:232-246` already states that posture for its
  sibling bail).
* **(b) resolve at USE time**: in `lowerRotations`, if `Ctrl` is not an `i32`, look it up as a
  theta whose handle this same loop has already produced, and if it has not, **process the
  rail's theta first** (a deterministic two-pass: lower every rail named in
  `ControlledRotations` before the arms that name them).

**Recommendation: (b), with (a) as belt-and-braces.** (a) alone leaves the correctness of a
Rule-13 core emitter resting on `taint.ThetaCalls` iteration order, which is exactly the kind
of unwritten dependency this project's record says goes stale.

### 2.3 H-3 — NEGATION: four options, and the recommendation

`t7` is plain-C reachable (`clang -O1` gives an orientation-B diamond) and `t7c` shows the
compare form spends a `cqrt_x(Flag)` **bracket** on it (`SwapRouteEmit.cpp:781`, `:788`). Inc
1b's invariant forbids that on a user register, and — unlike the phase path — **there is no
diagonal identity to fall back on**: `X·P(θ)·X = e^{iθ}P(−θ)` works because `P` is diagonal, and
`Ry` is not.

**Option A — anti-control by Ry ADDITIVITY (recommended).** Emit the arm's rotation
*unconditionally* and cancel it under the flag:

```
cqrt_ry_<W>(h_r, θ)                     ; b = 0 → Ry(θ)
cqrt_ry_<W>_controlled(h_b, h_r, −θ)    ; b = 1 → Ry(θ)·Ry(−θ) = I
```

* **Exact, and for a stronger reason than the Inc-2b by-difference form.** `−θ` is an IEEE
  `fneg`, which is exact; there is **no `fsub`**, so the whole `½ ulp(A−B)` / `kAngleSelect
  MaxRoundingRad` / non-finite-difference fence has **no subject** and the constant-arms-only
  narrowing does not need to be imported. The identity is width-safe because `cqrt_ry_<W>` is
  **tensored** (`backend.md:1187`): each of the W qubits independently sees `Ry(θ)Ry(−θ) = I`.
* **No ancilla, no `cqrt_cnot`, no `cqrt_free`, no new symbol.**
* **The mechanism already exists**: it is `AngleSelectEmit` step 2's unconditional twin `T0`
  with `B = θ, A = 0` — clone the hoisted theta, give the clone angle `θ`, chain the original
  onto it with angle `−θ`, and record `ControlledRotations[T] = rail`. Rule 14 reuse, not a
  new emission.
* **Cost:** one extra gate; the register is relabelled on **both** branches rather than one.
  That is already the accept class's own posture — R6 refuses every post-region read of the
  pre-Ry record (`t24`), and the freeze (`railCarriesControlledRotation`) still fires because
  the controlled gate is still there.
* **For a two-arm if/else diamond** (hand-IR only — plain C folds to an angle select, `t2`) the
  same trick gives `ry(h,B); cry(h_b,h,−B); cry(h_b,h,A)` — **three gates, still no
  subtraction**, which is strictly better-behaved numerically than the angle select's
  `A−B`. Worth recording even though nothing reaches it from C.
* **Must carry the undef/poison clause.** `fneg undef` is undef; reuse
  `valueCarriesUndef`/`angleSelectArmsAdmissible`'s clause (1) rather than re-spelling it.

**Option B — the B.1 `CopyRailRoot` ancilla.** `bf = cqrt_alloc_i1(0); cqrt_cnot(h_b, bf);
cqrt_x(bf); cry(bf, h_r, θ); cqrt_x(bf); cqrt_cnot(h_b, bf); cqrt_free(bf)`. Reuses the
Rule-13-cleared 1b-B.1 mechanism verbatim and works for any arm class and any polarity
uniformly. Costs an ancilla and four gates, and `CondTreeEmit`'s `CopyRailRoot` is written for
`emitCondNetwork`, which `classifyArms`' path does not use — so it is *more* plumbing than
option A, not less. Keep it in reserve for the day a non-rotation arm class needs anti-control.

**Option C — decline negation** (`bare i1 register condition` on the `R.ArmNegated` arm). Over-
declines a shape `clang -O1` produces from `if (!b)`, which Rule 17 posture argues against for
the increment's own target shape.

**Option D — swap the arms.** Not available: a diamond has one content arm; there is nothing to
swap it with.

**Recommendation: A.** It is the cheapest, it is exact, it reuses an existing emission, and it
is the only option that emits *nothing at all* on the user's register beyond a read-only
control.

### 2.4 The IN-LOOP form (`t5`) — a capability with no twin

`t5` reaches `classifyArms`, so `flatRegionRollableInLoop` has already proved the CFG half
(`ControlDetect.cpp:635`). What is left is drbq Inc 3's R7 loop clauses
(`ArmClassify.cpp:3161-3330`):

* **(b)** some member of `BaseWire` is a `PHINode` in `L`'s header — **holds for `t5`** (`%10 =
  phi i32 [%2, %0], [%14, %13]` is the rotated register's header φ);
* **(b′)** that φ is one `collapseFlattenedLoopRails` will CLAIM, asked by calling
  `railPhiRootMint` — the external incoming peels to a classical-arg-0 `cq_theta` mint
  dominating the header, which `%2 = cq_theta_si32(i32 7, 0.25)` is.

Both are questions about the ROTATED register and neither mentions the condition, so **they
carry unchanged**. The condition's own question is rung (iii), and `railCondWireDisposition`
answers `None` for `t5` (no gate on `b`'s wire anywhere).

⚠ **There is nothing to be byte-identical to.** The compare twin `t5c` declines (row W), so the
usual rolled-vs-hand-unrolled `compare_files` gate has no *oracle* — the only available witness
is **rolled == hand-unrolled under the 1b-C binary itself**, which is an internal-consistency
gate (the `e2e-*-loop-twin-identical` family's form) and must be *labelled* as one. That is the
same instrument `e2e-phase-bool-loop-twin-identical` uses for Inc 1b, so the precedent exists —
but Inc 1b's rolled form has a *compare* sibling and this one does not.

⚠ **H-5 rides here**: the C-1 in-loop leak family (`taint.ClaimedRailRoots`,
`InPlaceRailOps`, `InLoopFlattenedPreds`) is the record of eight silent miscompiles over six
adversarial rounds on `markIfRailLocal`'s neighbourhood, every one of them a loop-INVARIANT
rail meeting a loop-CARRIED one. `t5` is *exactly* that mixture — an invariant `_Bool` condition
and a carried `int` register — which is the sub-grid-F axis of `tools/loop_twin_matrix.py`.
**Budget the twin matrix for this shape explicitly.**

### 2.5 F1 / F2 for a rail condition — measured, and the `i1` seed collides BY DESIGN

* **F1 needs no edit and it is doing real work.** For `t6` (`if (b) b = cq_theta(b,θ)`) `-O1`
  folds the arm to `cq_theta_i1(i1 true, θ)`, so the shape is a STATE PREP whose merge Pred
  incoming is the **tainted rail** — F1's second clause, `state prep merged with a quantum
  register` (`ArmClassify.cpp:2836`). Confirmed on the compare twin `t6c`. Do **not** scope the
  clobber decline onto R4/S8: R4 is *skipped* for a state prep (`:3147`) and would pin nothing.
* **F2 needs no edit either.** The semantic half `f2SeedPinnedByLiveRegister` (`:1195`) reads
  `BI->getCondition()` (`:1203`), never `Region.Condition`, and enumerates every tainted
  **integer** value dominating `BI` (`:1256-1263`). A rail condition *is* such a value, and LVI
  pins it to `{1}` on one edge and `{0}` on the other.
  * an **`i32`/`f64` seed** (`t3`, `t17`) does not collide: the test is `Constant *` **pointer
    identity** against the seed, and `i1 true` is not `i32 7`.
  * an **`i1` seed** (`t16b`) **always** collides, on both edges, because an `i1` has only two
    values. This is the **HANDOFF Q6** fact and it is *not new to 1b-C*: the same collision
    already put the `i1` state-prep width OUT for every condition kind (round-3 finding
    F-R3-8; the shipped pins are `control_inplace_ry_reject_stateprep_i1_flag_pinned.ll` and
    `..._i1_arm_flag.ll`). 1b-C **inherits** it and must say so in a fixture rather than
    discovering it in a round.
* The literal fast path (`dyn_cast<ICmpInst>`, `:3000`) misses for a rail. Benign: the semantic
  half subsumes it, and a miss can only over-decline.

### 2.6 The re-decline partition — shared with bd `fg9k` / `54ur`, and it must be written once

`classifyArms` classifies **six** arm classes and 1b-C is two of them. Widening the gate at
`ArmClassify.cpp:2389` without a per-class re-decline silently hands the value arm (bd `fg9k`)
and the eq-fold path a rail condition nobody cleared them for.

| arm class | flagged at | 1b-C disposition | measured today |
|---|---|---|---|
| PHASE (`cq_phi` spine) | `SawPhaseArm` | **DECLINE `kBareRailCondReason`** — a register-carrying `cq_phi` spine no longer exists (D1) and `classifyPhaseKickback` pre-peels the real thing | unreachable from C |
| EQ-FOLD (`tryEqFoldArm`) | — | **DECLINE** — D2/D8's polarity proof is written over an `ICmpInst` | unreachable from C |
| **IN-PLACE ROTATION** | `SawRotationArm` (`:3376`) | **ACCEPT** (shapes A/B of §2.1) | `t1 t4 t5 t7 t8 t11 t13 t14 t15 t17 t23 t24` |
| **STATE PREP** | `StatePrep` | **ACCEPT**, with F1/F2 unchanged (§2.5) | `t3`; `t16b` declines at F2 |
| VALUE | `SawValueArm` | **DECLINE `kBareRailCondReason`** — bd `fg9k` (1b-B.2b) | `SCOPE_B2.md` §0.1 |
| CLASSICAL CALL | `classifyClassicalCallArm` | **DECLINE** (its own `isa<CmpInst>` early return, untouched) — bd `54ur` (1b-B.2a) | `SCOPE_B2.md` §0.2 |

The cheapest sound spelling is the one `SCOPE_B2.md` §1.1a proposes from the other side: make
the 2389 gate `RailCond`-aware and add ONE clause at **each** `Saw*` / `StatePrep` accept site
(`if (RailCond) { declineArm(declAnchor(Region), kBareRailCondReason); return Declined; }`),
mirroring how homogeneity is already enforced *at every accept site, not written once*
(`ArmClassify.cpp:2528-2545` and `:2631-2633`, whose comment records that the one-directional version of exactly
this check was already wrong once — *"Luck is not a fence"*).

⚠ **COORDINATION.** 1b-C and 1b-B.2b (`fg9k`) widen the **same line**. Whichever lands first
pays for the partition and the other inherits it. They should not be built in parallel worktrees
against the same `classifyArms`.

> ### ⚠ ERRATA (added 2026-09-11 by the l4x4.b round-1 Rule-13 FIX agent — review finding F-5)
>
> **The table above has ONE cell per class and the world has TWO exits per class. Read
> the `kBareRailCondReason` spellings as "the disposition", NEVER as "the string".**
>
> The VALUE row reads *"DECLINE `kBareRailCondReason`"*. That is right about the
> DISPOSITION (refused, loudly, and filed as bd `fg9k`) and **wrong as a claim about the
> emitted string**: several value-specific clauses in `classifyArms` sit ABOVE the §2.6
> re-decline, so a rail region that trips one exits there instead. **MEASURED, from plain
> C at `-O1`** (probe `t16_i1_stateprep`, `_Bool r; if (b) r = cq_theta(0, 0.9);` — the
> `int` overload leaves an `icmp ne` in the arm as the merge incoming):
>
> ```
> cq controlled lowering: value-arm swap-route under quantum control
> ```
>
> — from the `isValueChangingOp(Base)` clause, not from `declineRailClass()`. The
> hand-IR `add`-chain spelling of the same class DOES answer `bare i1 register condition`
> (`control_swap_reject_value_rail_cond.ll`, measured). **Both exits are now pinned**, the
> second by `control_swap_reject_value_rail_cond_early_clause.ll`, whose header records
> the discriminating mutation.
>
> **The same caution applies to the other DECLINE rows and has NOT been individually
> measured for them** — `declineRailClass()` is the LAST word for a rail region, not the
> first, and any class-specific clause above it can speak first. A future `fg9k` / `54ur`
> reviewer who greps for `bare i1 register condition` and finds a rail region declining
> with something else has found this errata, not a hole; what must be true is only that
> **every** exit is loud, which is what the `RUN: not` inversion in each fixture pins.
>
> Two further corrections to this section's *"measured today"* column, from the same
> review (finding F-4): the CLASSICAL-CALL and EQ-FOLD rows are **"unreachable from C"**
> in a stronger sense than the column suggests, and the two probes that were written for
> them measure a DIFFERENT lowering — `impl/p5` is folded by `-O1` into bd `r9e5`'s rail
> DATA-SELECT (0 `br i1`, 2 `select i1`) and ACCEPTS, and `impl/p6` is the Inc-1b branch-
> phase KICKBACK and ACCEPTS. Neither row has a dedicated fixture; both probe headers now
> say so.

### 2.7 The structural freeze with a LIVE user register as the control — read exactly

`ChainWalk::railCarriesControlledRotation(H)` (`ChainWalk.cpp:319-347`) walks `H->users()` and
keeps only calls for which `isInPlaceGateOn(G, H)` is true; for `cqrt_ry_<W>_controlled` that
predicate (`ChainWalk.cpp:260-262`) requires **VOID, arity exactly 3, and
`G->getArgOperand(1) == H`**. So:

* **arg-1 (the TARGET, `h_r`) is FROZEN** — unchanged by 1b-C. Same rail, same gate, same
  reason: a controlled gate's adjoint needs its control.
* **arg-0 (the CONTROL, `h_b`) is NOT frozen by this predicate** — `isInPlaceGateOn` answers
  false for it (arg-1 ≠ `h_b`), then the generic `if (N.contains("_controlled")) return false;`
  bail refuses it outright.

What happens to `h_b` instead, read off the three predicates that decide a rail's fate:

* `isTerminalHandle(h_b, taint)` (`ChainWalk.cpp:718-737`) — the controlled gate is not an
  in-place gate on `h_b`, not a measure sink, not an output sink, not a copy-out sink, so the
  loop hits `return false`. **`h_b` is NOT a terminal ⇒ the whole-DAG spine never claims it.**
* `preservesBasisUnderRecord` (`:835-846`) — its disqualify list names *"any `_controlled` gate
  or route (`cqrt_cswap`/`cqrt_x`/`cqrt_cnot`/`cqrt_toffoli` — Phase-4 owns the rail)"*, so
  `h_b` is disqualified and is never an M-B interior candidate either.
* **Net: `h_b` is LEFT ALLOCATED, never freed — a Rule-6 safe leak.**

**That is exactly the disposition the compare form already gives its condition register**, and
it is MEASURED, not argued: `t11c` (`q` never measured) accepts and `%h` appears in **no**
`cqrt_free`. So 1b-C introduces no new leak class; it gives the *user's* register the treatment
the *flag's* source register already gets.

⚠ Two things a reviewer will ask, and both should be answered in the source rather than left
implicit: (i) `h_b` is `Ry(θ)|0⟩ ≠ |0⟩`, so a free would be a hidden measurement — the leak is
the **required** direction, not a shortfall; (ii) if `h_b` is also MEASURED (`t1`, the flagship)
its `cqrt_measure_i1` is an ordinary sink and nothing changes.

### 2.8 The `RailLadderProven` tripwire — reuse the field, widen its contract

`ControlRegion::RailLadderProven` (`ControlPlan.h:519`) exists for exactly this obligation: it
is set by `classifySelectRegion` on accept iff the tree carries a rail leaf
(`SelectClassify.cpp:1095`), and `emitSelectRegion` REFUSES a rail-carrying tree without it
(`SelectMergeEmit.cpp:130-132`). Its own comment already anticipates a second writer: *"bd `fg9k`
widens that and MUST route a rail through the ladder and set this before handing over."*

1b-C needs the same backstop at **two** emitters — `emitInPlaceRotationRegion` and
`AngleSelectEmit`'s Ry stem — because each has more than one caller path and only the
classifier asks the ladder. **Recommendation: ONE field, contract restated as "some classifier
ran the rail ladder for this region", set at each rail-admitting accept and checked at each
rail-admitting emitter, with `kBareRailCondReason` as the refusal string.** A second field is
the `railOf`/`isAbiQramStore` drift hazard (Rule 14).

### 2.9 `markRailCondRead` — a FIFTH and SIXTH site, and the record is the safety

The 1b-B.1 round-2 fix (`reverifyRailCondReads`, `ArmClassify.cpp:2060`) closes a CONFIRMED
plain-C silent miscompile: the rail ladder's closures are asked at **round-1 taint** inside
`detectControlRegions`, while `lowerRotations` decides chained-vs-source at **FINAL taint**, and
`repropagateControlMerges` re-seeds from the 6.5/4.5 `%out` rails in between. The cure is a
re-verification keyed on **every emitted rail READ**, recorded at the emission site.

There are **four** sites today — MEASURED, `grep -rn 'markRailCondRead' ir-pass/src`:
`CondTreeEmit.cpp:83`, `CondTreeEmit.cpp:241`, `AngleSelectEmit.cpp:211`,
`SwapRouteEmit.cpp:1491`. The header at `ArmAnalysis.h:179-191` says it outright: *"a fifth
emitter that reads a rail and forgets this call silently re-opens F-B1R2-1 with no diagnostic
anywhere."*

**1b-C adds the fifth and the sixth**: `SwapRouteEmit.cpp:785` (the hoisted arm theta, which
*becomes* `cqrt_ry_<W>_controlled(h_b, …)`) and `AngleSelectEmit.cpp:533` (the Ry stem's
rewired consumer). Both read points are still-standing `@cq_theta` calls at
`reverifyRailCondReads`' slot — VERIFIED: the stage runs at `CQLoweringPass.cpp:431` / `:852`,
**before** `lowerRotations` at `:557` / `:880`, which is where thetas are erased.

**This is H-2, and it is the single most likely way 1b-C ships a silent miscompile.**

---

## 3. Hazards (H-n), in the order a reviewer should probe them

**H-1 — the control operand is the rail's pre-RAUW `i1` CALL, not its `i32` handle
(§2.2).** `taint.ControlledRotations`'s value type is a raw `Value *`
(`TaintPropagation.h:164-166`), and `lowerRotations` RAUWs and then erases the rail's theta. Loud
(a verifier type error, or a use of an erased instruction) rather than silent — but it is the
drbq Inc-1 stale-`Value *`-set shape, and the *fix* must not be "rely on iteration order".
**Probe first: build shape A and look at the lowered IR, not the exit code.**

**H-2 — a fifth/sixth `markRailCondRead` site (§2.9).** Forgetting either re-opens
F-B1R2-1 — a CONFIRMED plain-C silent miscompile, `opt` exit 0, verify-clean, stage-2b clean —
with **no diagnostic anywhere**. Evidence: the r9e5 round-2 fix's own FIRST spelling missed a
site (the 4.3 nest's conjunction toffoli), and probe `w5` accepted through it. Two decline
fixtures built from two-TU plain C (a rail derived from a 6.5/4.5 `%out`) are mandatory, each
RED on the pre-1b-C binary.

**H-3 — NEGATION (§2.3).** `t7` is plain-C reachable and the compare form's answer
(`cqrt_x` on the flag) is forbidden here. Whichever option ships, the `cqrt_x`-on-a-user-
register invariant needs a whole-file `NOX-NOT: cqrt_x(i32 %h_b` prefix in **every** accept
fixture, plus an injection-matrix mutation that injects exactly that call — the Inc-1b/eqpx
lesson is that the first run of that matrix reads MISSED.

**H-4 — the `HasDataUse` / `ShareCondFlag` block is actively WRONG if left in (§1.1).** For a
rail, `Region.Condition->users()` contains the `cq_measure_i1` of the flagship program, so
`HasDataUse` is TRUE and `condDataUseDisposition` would adjudicate the user's register as a
*flag lineage*. Every outcome (`ShareOk` ⇒ `rotation arm shares the condition flag`;
`MeasuredEarly`; `Unowned`) is a wrong answer about the wrong object. The skip is mandatory,
and rung (ii) is its replacement — not an optimisation.

**H-5 — the in-loop C-1 leak family (§2.4).** `t5` is the invariant-condition +
loop-carried-register mixture that produced eight silent miscompiles over six adversarial
rounds (`markIfRailLocal`, `invariantRegisterRoots`, `ClaimedRailRoots`, `InPlaceRailOps`,
`InLoopFlattenedPreds`). **Stage 2b is structurally blind to a leaked TEMPLATE-minted rail** and
reported `0 violation(s)` on every broken circuit in that family. The only instrument that can
see it is `tools/loop_twin_matrix.py`; budget it, and expect the rolled/unrolled pair to need a
sub-grid.

**H-6 — S6's positional prong is the wrong question for a rail (§1.2).** Asked of a rail it is a
position test on a `cq_theta_i1` *definition*; `t20` (rail in another block) then returns
`NotApplicable` and the caller reports **`rotation angle`** — a misleading string for a pure
over-decline. Ship the over-decline, pin it with a fixture whose header says so, file the
widening. Do **not** silently substitute rung (iii) without its own round: S6's window
(`Cond → T`, not `Cond → Sel`) exists because the mint happens at the consumer, and the rail has
no mint at all, so the two questions are genuinely different.

**H-7 — the increment ADDS CUSTOMERS to two known-defective paths.** The drbq Inc-3
`e2e-loop-twin-matrix` quarantine holds **29 cells in three classes** (bd `1m5p` class A, bd
`a3z7` class B, bd `3qlq` class C), all of them PRE-EXISTING and all of them exposed by an axis
whose arm rotates a register the condition does not read — which is 1b-C's entire accept class.
"Pre-existing" is true of the defect and FALSE of its population. Expect quarantine churn and
decide up front that a new quarantine cell needs an owner disposition, not a fix inside 1b-C.

**H-8 — the re-decline partition (§2.6) is an over-accept in the most-fenced function in the
pass.** Four classes must keep declining after the gate widens, and the file's own
`SawRotationArm` comment records that a one-directional version of this check was already wrong
once. It is also shared with bd `fg9k`; two increments editing one line is a merge hazard, not
just a design one.

**H-9 — the freeze's arg-0/arg-1 asymmetry (§2.7) must be stated at the site.** The
`ChainWalk.cpp:196-226` comment already warns that *"the next `_controlled` stem admitted here flips
all six [emitters] from 'not a terminal' to 'a terminal' with no diagnostic anywhere"*. 1b-C
admits no new stem, but it makes a **user register** an arg-0 for the first time, and the
`preservesBasisUnderRecord` disqualify list is the only thing standing between that and an M-B
interior discharge. Write it down; the r9e5 round-1 item F-B1R1-3 pattern (one retirement
trigger, two pins) applies.

**H-10 — two RAUW conventions in one file (M-α vs M-β).** `emitInPlaceRotationRegion` uses M-β
(`SwapRouteEmit.cpp:903`, RAUW the merge φ to the LAST HOISTED GATE) and `emitRegion`'s Rz
peephole uses M-α (the base). 1b-C keeps M-β verbatim — it is a **correctness** requirement for
a state prep (M-α would make `r` a classical `i32 7`, a silently classical program) and a
loop-bookkeeping requirement for the in-loop form. Option A of §2.3 adds a gate *before* the
hoisted one, so `Gates.back()` is still the right RAUW target; verify that rather than assume it.

---

## 4. Fixtures, slices and witnesses

### 4.1 DECLINE fixtures

Each mirrors its string character-for-character on a `RUN: not …` line. ⚠ A `DS_Error` decline
writes **0 bytes to stdout**, so every IR-text negative in a decline fixture is VACUOUS — what
pins "no silent lowering" is the `not` inversion plus the string, and each header must say so.

| fixture | shape | string |
|---|---|---|
| `control_inplace_ry_reject_rail_measured_before.ll` | `t9` | `condition measured before the control route` |
| `..._reject_rail_measured_sidepath.ll` | a classically-guarded measure that can precede (F-1b-2) | same |
| `..._reject_rail_measured_parent_name.ll` | the measure names a CHAINED parent of the rail (F-B1R1-1) | same |
| `..._reject_rail_sibling_theta.ll` | `t10` — the F-1b-1 class | `condition predates a non-diagonal gate` |
| `..._reject_rail_chained_between.ll` | `%b=θ(u); %c=θ(%b,·); br i1 %b` | same |
| `..._reject_rail_round2_sibling_theta.ll` | **two-TU plain C**, rail derived from a 6.5/4.5 `%out` (H-2) | same, **from `reverifyRailCondReads`** |
| `..._reject_rail_round2_measured_parent.ll` | the rung-(ii) half of the same window | `condition measured before the control route` |
| `..._reject_rail_on_cond_wire.ll` | `t6`'s UNFOLDED spelling (hand IR, the register live) | `rotation arm on a condition wire` (R4/S8) |
| `..._reject_rail_stateprep_merged_quantum.ll` | `t6` as `-O1` gives it | `state prep merged with a quantum register` (F1) |
| `..._reject_rail_stateprep_i1_seed.ll` | `t16b` | `state prep seed is proven equal to the condition register` (F2) |
| `..._reject_rail_stale_record.ll` | `t24` | `stale rail record read past a controlled Ry` (R6) |
| `..._reject_rail_inloop_iteration_local.ll` | an ITERATION-LOCAL rotated register (R7 (b)) | `control flow inside a loop body` |
| `..._reject_rail_inloop_unclaimed_phi.ll` | a header φ `collapseRailPhisIn` will not claim (R7 (b′)) | same |
| `..._reject_rail_trunc_cond.ll` / `..._reject_rail_phi_cond.ll` | a derived / loop-carried `i1` is NOT a rail leaf (`t12`) | `control flow` — the discriminators for bd `boi6` / `r903` |
| `..._reject_rail_compound_cond.ll` | `t18` | `control flow` |
| `control_swap_reject_value_rail_cond.ll` | §2.6 — the VALUE class must KEEP declining | `bare i1 register condition` |
| `control_swap_reject_eqfold_rail_cond.ll` | §2.6 — EQ-FOLD | same |
| `control_classical_call_arm_reject_rail_cond.ll` | §2.6 — the 6.5 arm (bd `54ur`) | same |
| `control_angle_select_reject_rail_ry_runtime_arms.ll` | `t22` | `rotation angle` (the Inc-2b narrowing, unchanged) |
| `control_angle_select_reject_rail_ry_crossblock.ll` | `t20` — H-6, the intended OVER-DECLINE | `rotation angle`, with the header saying it is an over-decline |
| `control_angle_select_reject_rail_ry_inloop.ll` | `t21` | `control flow inside a loop body` |
| `control_angle_select_reject_rail_ry_cond_wire.ll` | the select rotates the condition's register | `rotation arm on a condition wire` (S8) |
| `control_angle_select_reject_rail_ry_stale_record.ll` | S9 | `stale rail record read past a controlled Ry` |
| `control_angle_select_reject_rail_ry_round2_sibling.ll` | H-2 at the select | `condition predates a non-diagonal gate` |

**FLIP targets** (both named in the bd notes, both currently green on `kBareRailCondReason`):
`control_inplace_ry_reject_raw_i1_cond.ll` → rewrite as the ACCEPT its own header anticipates
(*"Controlling on it directly is a real (3-gate cheaper) capability and is DEFERRED"*), and
`control_angle_select_reject_rail_ry.ll` → likewise. Both should be `git mv`'d out of
`reject_`, following the 3qlq.4 / r9e5 precedent.

### 4.2 ACCEPT fixtures

Each with whole-file negatives in their OWN prefixes and exact counts in their own prefixes,
**derived from the pass output and never guessed** (the drbq Inc-4 lesson: 9 of 20 accepts named
a `%h1` that did not exist, and a positive `COUNT` inside a negative prefix WINDOWS every
negative after it):

* `NOX-NOT: cqrt_x(i32 %h_b` — **the non-negotiable**, no `cqrt_x` on the user register;
* `NOROUTE-NOT: cqrt_cswap`;
* `NOMINT-NOT: cq_template_icmp` and `NOFREE-NOT: cqrt_free` — nothing minted, nothing freed;
* `CRCNT`, `RYCNT`, `ACNT` — exact whole-file counts of `cqrt_ry_<W>_controlled`, `cqrt_ry_<W>`
  and `cqrt_alloc_*`.

Subjects: `control_inplace_ry_rail_{diamond,negated,i1_width,f64_width,derived_base,dead_register,
two_regions,post_ry_sdagger,data_use,measure_after,inloop_invariant}.ll`,
`control_inplace_ry_stateprep_rail_{i32,f64}.ll`,
`control_angle_select_ry_rail_{basic,polarity_control,i8,f64}.ll`.

**Injection matrix** — an injected `cqrt_x(i32 %h_b, …)`, an extra `cqrt_free`, an extra
`cqrt_ry` on the condition register, a `cqrt_cswap`, an `i1` rail handle in the `i32` control
slot, and a *dropped* `_controlled` suffix (the uncontrolled gate = the arm fires on both
branches) — each must redden ≥ 1 prefix in EVERY accept. **Expect the first run to read
MISSED**; that has happened on every increment in this epic that ran it.

### 4.3 e2e slices and what the witness actually is

All STRICT stage 2b.

| slice | witness |
|---|---|
| `slice_control_inplace_ry_bool.c` (`t1`) + `slice_control_inplace_ry_bool_twin.c` (`t1c`) | **a STATED REDUCTION, no `compare_files` gate.** Delete three lines from the twin's golden (the mint, the strip, the free) and rename `%h_cmp` → `%h_b`. This is the drbq Inc-4 precedent exactly: the two goldens differ by a reduction, so a byte-identity gate would assert something FALSE. Commit the twin as a slice in its own right so a reviewer can re-derive it from two files in the tree. |
| `slice_control_inplace_ry_bool_negated.c` (`t7`) + `slice_control_inplace_ry_bool_negated_twin.c` | **a REAL `compare_files` gate**, and it is available for free under option A: the subject `if (!b) r = Ry(r,θ)` and the manual twin `r = cq_theta(r,θ); if (b) r = cq_theta(r,−θ);` must be **BYTE-IDENTICAL**. ⚠ Both lower under the 1b-C binary, so label it an internal-consistency gate, not an oracle gate. |
| `slice_control_inplace_ry_bool_stateprep.c` (`t3`) + twin | reduction, as above |
| `slice_control_angle_select_bool_ry.c` (`t2`) + twin (`t2c`) | reduction (the same three lines) |
| `slice_control_inplace_ry_bool_loop.c` (`t5`) + `..._loop_unrolled.c` | `e2e-inplace-ry-bool-loop-twin-identical` — rolled == hand-unrolled. **The only witness available** (§2.4: the compare twin declines), and it is internal-consistency. |
| `slice_control_inplace_ry_bool_two_regions.c` (`t13`) | trace ORDER across sequential regions (bd `hcrg`'s Kahn sort) |

**IR-size independence** for the loop pair (87-lines-at-K=3 == at-K=1000 style) should be a
recorded MEASUREMENT, not a ctest entry — the 8h7d.5 precedent for
`slice_control_grover_loop_dynamic`.

---

## 5. Cost

| | production lines | files | fixtures | slices / goldens | ctest |
|---|---|---|---|---|---|
| **A** flat diamond, un-negated | ~55-75 (gate + 3 rungs + `Value *Cond` + mint/strip/free skip + `markRailCondRead` + `RailLadderProven`) | `ArmClassify.cpp`, `SwapRouteEmit.cpp`, `ControlPlan.h` | ~14 (6 accept / 8 decline) | 4 | +4 |
| **A′** H-1 (the control handle) | ~15-25 | `RotationLowering.cpp`, `TaintPropagation.h` | 2 | 0 | 0 |
| **B** negation (option A of §2.3) | ~30-45 (the `T0` clone, the `fneg`, the undef clause) | `SwapRouteEmit.cpp` | ~5 (3 accept / 2 decline) | 2 + **1 `cmp` gate** | +3 |
| **C** state prep on a rail | ~8-12 (mostly the accept path falling through) | — (rides A) | ~6 (2 accept / 4 decline) | 2 | +2 |
| **D** Ry-stem angle select | ~35-50 | `ArmClassify.cpp`, `AngleSelectEmit.cpp` | ~10 (4 accept / 6 decline) | 2 | +2 |
| **E** the §2.6 re-decline partition | ~20 (4 clauses + comments) | `ArmClassify.cpp` | 3 decline | 0 | 0 |
| **F** in-loop (§2.4) | ~0 production (R7 (b)/(b′) carry unchanged) — **but all the review** | — | ~4 (2 accept / 2 decline) | 2 + **1 `cmp` gate** + loop-twin-matrix sub-grid | +3 |

**Totals: ~165-225 production lines across 6 files; ~44 fixtures (17 accept / 27 decline);
12 e2e slices; 2 `compare_files` twin gates.** Corpus `ir-pass-lit` **1776 → ~1820**; goldens
**341 → ~353**; `ctest -N` **387 → ~401**.

**No new runtime symbol, no `tools/opcode_table.yaml` change, no `include/CQ.h` change**
(owner D3) — MEASURED: every width 1b-C can reach already has a declared and defined
`cqrt_ry_<W>_controlled` (`runtime/cq_runtime.h:229-237`, nine widths;
`OpcodeSupport.cpp:300`).

**Rounds: THREE adversarial, budgeted up front**, and the probe order is H-2 → H-1 → H-5 →
H-3 → H-8. The record for this neighbourhood is explicit: eight confirmed silent miscompiles
over six rounds on one function, two of them *introduced by a fix* and one found by a round
reviewing a *different* increment; 1b-B.1 itself took three rounds (round 1 CLEAR-WITH-ITEMS,
round 2 **BLOCK**, round 3 CLEAR-WITH-ITEMS) plus an orchestrator-found over-accept before
review. Assume a fourth thing is there.

---

## 6. Recommendation to the owner

**Build 1b-C, and build it in TWO increments in this order.**

1. **`l4x4.a` — the Ry-stem ANGLE SELECT (shape D) alone.** ~35-50 production lines in two
   files. Its emitter change is provably a *substitution* — `AngleSelectEmit` already ships
   `Value *Flag = RailCond ? Cond : lowerCompareToFlag(…)` at `:185` for the phase stem, and the
   Ry stem emits **no `cqrt_x` at all** (measured on `t2c`), so **H-3 has no subject here**. It
   touches `classifyArms` not at all, so **H-8 has no subject either**. It buys the plain-C
   `if (b) r = Ry(r,A); else r = Ry(r,B);` outright. It still owes H-1, H-2 and H-6.
2. **`l4x4.b` — the flat diamond + state prep + negation + in-loop (shapes A/B/C).** This is
   where H-1, H-3, H-5, H-7 and H-8 all live, and where the `classifyArms` gate — shared with bd
   `fg9k` — has to be widened with its five-class re-decline partition.

**Three decisions the owner should make before either starts:**

* **NEGATION (H-3).** Recommendation: **option A**, anti-control by Ry additivity
  (`ry(h,θ); cry(h_b,h,−θ)`). It is exact (`fneg`, never `fsub`, so the Inc-2b rounding fence has
  no subject), width-safe under the tensored `cqrt_ry_<W>`, needs no ancilla and no new symbol,
  and reuses `AngleSelectEmit`'s existing unconditional-twin emission. The alternative worth
  its own line is that it gives the `if/else` diamond `ry(B); cry(−B); cry(A)` — three gates,
  **no subtraction at all** — which is numerically *better* than the angle select's `A−B` and is
  worth recording as an option for retiring the constant-arms-only narrowing later.
* **THE `classifyArms` GATE IS SHARED WITH bd `fg9k`.** Decide which of `l4x4.b` / `fg9k` owns
  the §2.6 partition and sequence them; do not run both in parallel worktrees.
* **THE IN-LOOP HALF (§2.4, H-5) HAS NO ORACLE TWIN.** Its compare sibling declines by row W, so
  the only witness is rolled-vs-unrolled under the new binary. Either accept an
  internal-consistency gate with that label, or carve the in-loop form out into a third
  increment. Recommendation: **carve it out** — it is the shape that produced eight silent
  miscompiles in its neighbourhood, it buys a capability nothing in the tree can cross-check,
  and separating it is exactly what an increment boundary is for.

**Filing.** Split the bead: `l4x4` → **`l4x4.a`** (Ry-stem angle select on a rail) and
**`l4x4.b`** (diamond + state prep + negation), with the in-loop form as **`l4x4.c`** if the
owner takes the carve-out. Record in the PRD: §0.1's four measurements (the `if/else` is a
select; negation is plain-C reachable; the in-loop form has no compare twin; the clobber shape
is caught by F1, not R4), H-1 and H-2 as build-time obligations, and the `i1`-seed collision
(§2.5) as an INHERITED decline rather than a 1b-C omission.
