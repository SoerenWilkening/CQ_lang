# SCOPE — bd `test_C_libtooling-r9e5`, sub-increment 1b-B.2: the VALUE arm and the 6.5 CLASSICAL-CALL arm on a bare `_Bool` (rail-root) condition

Session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-10, branch `3qlq-inc1b-b-rail-select`, measured at
`87d0699` (the branch tip at the time of writing; `git status --porcelain` showed only this
untracked directory, so every measurement below is against the **landed `main` binary**
`build/ir-pass/cq-opt`, not against B.1's in-progress tree).

**READ-ONLY.** Nothing under `ir-pass/`, `tests/` or `tools/` was touched. Probes live in
`/private/tmp/.../scratchpad/scope_b2/` (not committed; every one is transcribed below).

Companion: `BRIEF_B1.md` (sub-increment B.1, the 4.4 DATA select on a rail — the mechanism B.2
inherits). Every line number below is as of `87d0699`; B.1 moves `SelectClassify.cpp`,
`SelectMergeEmit.cpp`, `CondTreeEmit.{h,cpp}` and one `ArmClassify.cpp` helper, so re-grep before
editing.

---

## 0. HEADLINE — measure first, and the measurement changes the shape of the increment

Two facts came out of the probe family, and both are load-bearing for what B.2 should be.

### 0.1 From plain C at `-O1`, a VALUE arm on a bare-`_Bool` condition almost always arrives as a `select`, i.e. as **B.1's** shape and not as a diamond at all

`clang -O1`'s `SimplifyCFG::FoldTwoEntryPHINode` speculates a cheap arm into a `select`, and a
bare i1 condition is the *cheapest possible* condition — there is no compare to hoist, so the whole
speculation budget goes to the arm. InstCombine/Reassociate then collapses a constant-only
arithmetic chain to ≤ 2 instructions before that fold is even asked, so "more source statements"
does not help. MEASURED (all with
`clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, then `build/ir-pass/cq-opt -passes=cq-lowering`):

| probe | source arm | `br i1` in `-O1` IR | what it is |
|---|---|---|---|
| `v1` | `if (b) a = a + 3;` | **0** | `select i1 %b, i32 %3, i32 %2` |
| `v2` | `if (b) a = a+3; else a = a*2;` | **0** | one `select` |
| `w1` | 4 ops `a+3; a*7; a+11; a*13` | **0** | reassociated to `mul`+`add`, then one `select` |
| `w4` | 4 ops in **both** arms | **0** | two 2-op chains, one `select` |
| `x1` | 3 ops that do **not** fold (`a*n; a+n; a^5`, runtime `n`) | **0** | one `select` |
| `y1` | **6** ops (the `slice_control_value_diamond.c` chain) | **1** | a REAL diamond |

So the *only* plain-C value-arm-diamond shape is the one the shipped e2e slice already uses and
whose header already says so: *"a single-op or short (≤4 cheap ops) value arm FOLDS TO A TAINTED
SELECT at `-O1`; only a longer linear chain survives as a clean br-diamond"*
(`tests/e2e/slice_control_value_diamond.c`, the "WHY A 6-OP CHAIN" paragraph). That sentence was
written for the compare condition and is **equally true, and for the same reason, for a rail**.

**Consequence:** B.1 alone already makes `v1`, `v2`, `w1`, `w3`, `w4`, `w5`, `x1`, `x3`-shaped
programs — *including the owner's own file* — compile. B.2's VALUE half buys the ≥ 5-op arm and
the hand-IR spelling, nothing the owner has yet written.

### 0.2 The 6.5 CLASSICAL-CALL arm on a rail IS plain-C reachable and its compare twin ALREADY ACCEPTS

MEASURED:

* `x2_classical_call_noinline.c` — `__attribute__((noinline, const)) static int f(int x)`,
  `bool b = cq_theta(...); int x = arg_of(); int y = 5; if (b) y = f(x);` — is a REAL
  `br i1 %b` diamond (`brs=1, sel=0`) and declines
  `cq controlled lowering: bare i1 register condition under quantum control`,
  anchored (`CQ_CTRL_DBG=1`) on `%1 = tail call zeroext i1 @cq_theta_i1(...)` — i.e.
  `declAnchor(Region)`, i.e. **`ArmClassify.cpp:2126-2131`**, reached because
  `classifyClassicalCallArm` returned `NotApplicable` at **`ArmClassify.cpp:4542`**.
* `x3_classical_call_int_twin.c` — the identical program with `int q = cq_theta(5,.2); if (q > 3)`
  — **exits 0** and emits the shipped 6.5 stream (mint · out-rail · two X-bracketed
  `cqrt_copy_i32_controlled` · `_unc` strip · one `cqrt_free`).
* The call must be `noinline` to survive: with an ordinary `static int f(int x){return x*3+1;}` and
  a constant argument `-O1` const-folds the whole thing (`v6` → `select i1 %1, i32 22, i32 5`), and
  with a runtime argument it inlines (`w3` → `mul`/`add` then a `select`).

**Consequence:** the 6.5 half is a genuine capability gap with a working twin and a one-token
reproducer. It is also by far the cheaper half (see §3).

---

## 1. Every site that assumes a `CmpInst` condition, and what a rail root needs instead

The rail ladder to mirror is `classifyPhaseKickback`'s **step 5b** (`ArmClassify.cpp:3913-3944`)
plus its wire question at `:4036-4046`. Three questions, no more:

* **(i) tainted** — `Taint.Tainted.count(Rail)` (defence in depth; `cq_theta_i1` *is* the source);
* **(ii) not measured before the read point** — `railMeasuredBeforeBranch`
  (`ArmClassify.cpp:1825-1852`, file-local; B.1 generalises it to a `ReadPoint`);
* **(iii) the wire question** — `railCondWireDisposition` (`ArmClassify.cpp:1797-1810`), which is
  `condWireDisposition` MINUS the same-block positional prong and MINUS the `ShareCondFlag` clause,
  with the DT prong (`DeclineNow` → decline; `None`/`ProvenPostRegion` → accept).

And **nothing else**: `condDataUseDisposition` / `HasDataUse` / `ShareCondFlag` have **no subject**
for a rail (nothing is minted from the register, so there is no flag to share), exactly as
`classifyPhaseKickback:3985` records with its `if (!IsTree && Cmp)` guard.

### 1.1 `ArmClassify::classifyArms` (`ir-pass/src/ArmClassify.cpp:2112-3459`)

| line | site | what it does today | what a rail root needs |
|---|---|---|---|
| **2124-2131** | `if (!isa<CmpInst>(Region.Condition))` → `kBareRailCondReason` | THE GATE. Every rail-condition diamond/if-else dies here. | The one site that must move. Widen to `isa<CmpInst> \|\| isCondRailLeaf`, and **re-decline per ARM CLASS** further down (§1.1a). |
| **2141** | `comparePredLowerable(cast<CmpInst>(...))` | predicate has a template | **SKIP** — a rail has no predicate and no mint. |
| **2159-2186** | `HasDataUse` loop over `Region.Condition->users()` + `condDataUseDisposition(cast<Instruction>(...), ...)` → `Region.ShareCondFlag = true` | the ziov shared-flag path | **SKIP ENTIRELY** for a rail. A rail's other users (a `cq_measure`, a compare, arithmetic, a second region) are ORDINARY — the register is the user's. Note the `cast<Instruction>` is *type-safe* on a `CallInst` but the *semantics* are wrong: it would classify the rail's own `cq_measure` as a flag data-lineage. Replace with rung (ii), `railMeasuredBeforeBranch(Rail, Region.Pred, Taint, DT)` → `condition measured before the control route`. |
| **2195** | `condProvenance(Region.Condition, Taint, Prov)` | backward tainted provenance | **UNCHANGED, and already correct.** MEASURED by reading `condProvenance` (`:229-259`): it inserts `V` when tainted and then `if (isThetaCall(I)) continue;` — so for a bare rail `Prov == {rail}` exactly, which is what `classifyPhaseKickback:4022` relies on. |
| **2201-2206** | `condWireDisposition(Region, Taint, Prov, DT)` → `condition predates a non-diagonal gate` | the wire question | Dispatch on the root: `RailCond ? railCondWireDisposition(...) : condWireDisposition(...)`, spelled EXACTLY as `classifyPhaseKickback:4036-4041` does. `condWireDisposition` returns `DeclineNow` unconditionally for a rail today (`:1723-1727`, `Cond->getParent() != R.Pred` is false but the positional scan window is `Cond->getNextNode() … BI`, and worse the P5 loop would scan the whole gap) — do **not** just leave it. |
| **2210-2222** | `DeferredWireGate` + the `declineArm` re-speller | keeps every downstream decline's string byte-identical when P1 defers | **UNCHANGED** — condition-agnostic wrapper. |
| **2059-2110** (called at **2318**) | `straightThroughConstFoldHandle` | `dyn_cast_or_null<ICmpInst>(Region.Condition)` | **BENIGN MISS** — returns null for a rail, so the ordinary path runs. ⚠ There *is* a rail analogue (the branch pins `b` to `true`/`false` on its edges, exactly the F2 story) and it is **deliberately not built**: an unbuilt re-anchor can only OVER-DECLINE. Say so in the comment so a later widener does not read the miss as a proof. |
| **2734** | `dyn_cast<ICmpInst>(Region.Condition)` — F2's literal fast path | STATE PREP only (`if (StatePrep)`) | Out of B.2's scope: state prep is **1b-C** (bd `l4x4`) and must keep declining. |
| **2883** | `railWireClosure(Region.Condition, Taint, BackwardOnly, …, CondRails)` — R4's disjoint-wire proof | IN-PLACE ROTATION arm only | Same: **1b-C**. Note it *would* work on a rail (`railWireClosure` takes a `Value *`), which is exactly why the arm-class re-decline of §1.1a must be explicit rather than implicit. |
| **3455** | the P1 fence `DeferredWireGate && (SawValueArm \|\| !(SawPhaseArm \|\| SawRotationArm))` | value arms keep the position-free reading | **UNCHANGED IN FORM, and it is the interesting one.** For a rail root the `railCondWireDisposition` `ProvenPostRegion` accept is what makes `y4` (`if (b) {6 ops} b = cq_theta(b,-0.5);`, the S†) lowerable at all — and P1 currently REFUSES it for `SawValueArm`. Read §3 hazard H-4: this must be argued, not inherited. |

**Condition-agnostic and carrying over UNCHANGED** (verified by reading; none of them touch
`Region.Condition`):

* `walkPhaseSpine` (`:129`), `armBlockIsPureSpine` (`:160`), `taintedAngleGate` (`:1511`),
  `walkValueChain` (`:1413`), `valueArmIsPureChain` (`:1465`) — all arm-block-bounded;
* the chain's whole fence stack at `:3155-3330`: the fp-angle fence, the integer/`widthHasReversibleCopy`
  fence, the chain-bottoms-outside-the-arm fence, base-identity (`non-routable value multiplexer`),
  the Rule-8 fan-out/stray-op fence, the Q+Q-link defer (`value-arm swap-route`);
* **the §3c clobber check** (`:3253-3263`): `diagonalAliasHit(Routed, Prov)` with
  `Prov == {rail}`. Carries over **verbatim and correctly**: the rail is in `Prov` by
  `condProvenance`, so a value chain whose routed base IS the rail hits `Hit == Routed` and
  declines `arm rewrites a condition operand` on a diamond (or `control flow` on an if/else) with
  no change at all. It is *vacuous from plain C* for the same reason as the compare case, but it is
  live for hand IR and it is the fence that keeps 1b-C's clobber shapes out;
* `Region.Shadow` / `ShadowFalse` recording at `:3332-3343` and the `SawValueArm` flag — pure arm
  bookkeeping.

#### 1.1a The re-decline partition — the single most important design obligation

`classifyArms` classifies **six** arm classes and 1b-B is only two of them. Widening the gate at
2124 without a per-class re-decline silently hands 1b-C (bd `l4x4`) and the eq-fold path a rail
condition they were never cleared for. The partition, with the sites that must fire:

| arm class | set at | rail disposition in B.2 | measured today |
|---|---|---|---|
| PHASE (`cq_phi` spine) | `:2352` `SawPhaseArm` | **DECLINE `kBareRailCondReason`** — a register-carrying `cq_phi` spine no longer exists (D1); `classifyPhaseKickback` pre-peels the real thing. | unreachable from C |
| EQ-FOLD (`tryEqFoldArm`) | `:2366` | **DECLINE** — D2/D8's polarity proof is written over an `ICmpInst`. | unreachable from C |
| IN-PLACE ROTATION | `:3111` `SawRotationArm` | **DECLINE `kBareRailCondReason`** — this is 1b-C. Pinned TODAY by `control_inplace_ry_reject_raw_i1_cond.ll`, which must stay green. | `v5_clobber_theta.c` (`if (b) b = cq_theta(b,.3)`) → `bare i1 register condition`, anchored on the rail |
| STATE PREP | `:2445` `StatePrep` | **DECLINE `kBareRailCondReason`** — 1b-C. And note the drbq Inc-4 F2 ruling already says an `i1` seed collides on both edges, so this is doubly out. | HANDOFF Q6 |
| **VALUE** | `:3343` `SawValueArm` | **ACCEPT** (B.2b) | `y1`/`y2`/`y3`/`y4` → declines at 2129 |
| **CLASSICAL CALL** | `classifyClassicalCallArm`, `:4542` | **ACCEPT** (B.2a) | `x2` → declines at 2129 |

The cheapest sound spelling: keep the 2124 gate but make it `RailCond`-aware, and add ONE clause at
each of the four `Saw*`/`StatePrep` accept sites — `if (RailCond) { declineArm(declAnchor(Region),
kBareRailCondReason); return Declined; }`. Four sites, each next to the flag it reads, mirroring
how homogeneity is already enforced "at EVERY accept site, not just written at one" (the
`SawRotationArm` comment at `:2260-2278` makes exactly this argument, and records that the
one-directional version was wrong).

### 1.2 `ArmClassify::classifyClassicalCallArm` (`ir-pass/src/ArmClassify.cpp:4527-~5040`)

| line | site | what a rail root needs |
|---|---|---|
| **4542-4544** | `if (!isa<CmpInst>(Region.Condition) \|\| !comparePredLowerable(cast<CmpInst>(...))) return NotApplicable;` | Split: `isCondRailLeaf` → skip `comparePredLowerable` (no predicate) and fall through; a non-compare non-rail → `NotApplicable` as today. |
| — | (the rail ladder) | ADD rungs (i)/(ii)/(iii) here. This classifier asks **no** condition question beyond 4542 — verified by `grep` over its whole body: the only other `Cond`-ish tokens are in comments. So the ladder is three new `if`s, not a re-audit. |
| **4801-4810** | the §3c-vacuity note (`(void)StraightThrough`) | **UNCHANGED and stronger for a rail.** The argument is "the call result and every input are NON-TAINTED, hence disjoint from the condition's all-tainted provenance by construction". A rail condition makes `Prov == {rail}` and the call's args are classical, so the disjointness is if anything more obvious. Update the prose to name the rail. |
| **4790-4798** | the `freezeDischargesHoistedArg` / `noundef` clause | condition-agnostic — unchanged. |
| everything else | purity + totality (`isSpeculatableTotalCallee`), the diamond-shape gates, the classical-result gate | condition-agnostic — unchanged. |

### 1.3 `SwapRouteEmit::emitValueRegion` (`ir-pass/src/SwapRouteEmit.cpp:294-585`)

Called from the dispatcher at **`:962`**, which derives `Cond` at **`:920`**
(`dyn_cast_or_null<CmpInst>(R.Condition)`) and bails LOUDLY at `:922-932` when it is null — so a
rail-condition value region accepted by `classifyArms` would today die in that bail. Both must move.

| line | site | what a rail root needs |
|---|---|---|
| **294** | `void emitValueRegion(const ControlRegion &R, BranchInst *BI, CmpInst *Cond, …)` | `Value *Cond` (rail or compare). Every use below is then either a `diagnoseUnderControl` anchor (fine on any `Instruction`) or a compare-only fence to guard. |
| **307-310** | `if (R.ShareCondFlag) diagnoseUnderControl(Cond, "condition used outside the branch")` | **Structurally dead for a rail** once §1.1's `HasDataUse` skip lands (`ShareCondFlag` is never set). Keep as the Rule-1 backstop. |
| **316, 323, 339, 345, 381, 397** | `diagnoseUnderControl(Cond, "control flow")` plan-shape bails | anchor only — needs `cast<Instruction>(Cond)` or `dyn_cast`. Unchanged behaviour. |
| **447-450** | `taint.Tainted.count(Cond->getOperand(0)) && …getOperand(1)` — the Q+Q-condition decline | **GUARD with `isa<CmpInst>`.** A rail has no operands; this would read the `cq_theta_i1` seed and angle. For a rail the question has no subject (one register, one control) — skip it. |
| **486-489** | `!comparePredLowerable(Cond) \|\| !compareFlagMintable(Cond, taint)` — the F-V1-2 pre-flight mint check | **GUARD with `isa<CmpInst>`.** The rail analogue of "can the flag be minted?" is "does `wd.allocFn("i1")` resolve and is `csyms.cnotFn()` available?" — ask B.1's own `CopyRailRoot` resolvability, pre-mutation, or the region hoists and flattens before the ancilla mint fails. **This is the F-V1-2 finding repeating one condition-kind over; do not skip it.** |
| **524** | `SelectInst::Create(Cond, TrueVal, FalseVal, "vmerge", BI)` | **UNCHANGED** — a `Value*` i1 is exactly what `SelectInst::Create` wants, and the rail is an i1. |
| **543-547** | the ORDER note: `flattenRegion` before `emitSelectRegion` | **Already safe.** `flattenRegion` erases `R.Condition` only when `use_empty() && !isCondRailLeaf(Cond)` (`RegionFlatten.cpp:96`, the 3qlq.4 guard). And the rail is not use-empty anyway (the new `select` uses it). |
| **~583-585** | `S.Kind = SelectRegion; S.Merge = Sel; S.Condition = Cond; emitSelectRegion(S, …)` | **UNCHANGED, and this is the whole design.** `emitSelectRegion` re-derives the tree with `collectCondTree` (`SelectMergeEmit.cpp:96`), gets `RailLeaves = {rail}`, and B.1's `CopyRailRoot` mint does the rest. The value arm inherits B.1's emitter **verbatim**, exactly as Inc 2 inherited 4.4's — and its witness is the same one: **byte-identity with the manually pre-hoisted `select` twin**, which after B.1 lands is a program the *B.1 binary itself* already lowers. |
| **920** | `auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);` (dispatcher) | Widen to `Value *` with the loud bail preserved for "neither compare nor rail". ⚠ **`Cond` is also passed to `emitInPlaceRotationRegion` (`:975`) and used by the phase path below (`:1133`, `:1147`, `:1246`).** Do NOT widen those — dispatch the rail check so those paths still see a `CmpInst *` or are unreachable. |

### 1.4 `ClassicalCallArmEmit::emitClassicalCallArmRegion` (`ir-pass/src/ClassicalCallArmEmit.cpp:82-272`)

| line | site | what a rail root needs |
|---|---|---|
| **85** | `auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);` + `bailLoud` at 86-87 | `Value *`; keep the loud bail for neither-kind. |
| **74** | `bailLoud`'s `dyn_cast_or_null<Instruction>(R.Condition)` | already `Instruction`-generic — unchanged. |
| **130** | `const DebugLoc DL = Cond->getDebugLoc();` | unchanged (`Instruction`). |
| **197-200** | `Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/false, /*before=*/BI); if (!Flag) return;` | **REPLACE with `emitCondNetwork(R.Condition, Tree, wd, csyms, taint, /*Before=*/BI, DL, /*AllowQQLeaves=*/false, Net)` + `Flag = Net.Root`**, with `CondNetDisp::MintDiagnosed → return;` (byte-identical to the `if (!Flag) return;`) and `Malformed → bailLoud(R)`. |
| **259-261** | `lowerCompareToFlag(Cond, …, /*inverse=*/true, …, /*railToStrip=*/Flag); freeFn(Flag);` | **REPLACE with `stripCondNetwork(Net, wd, csyms, taint, /*Before=*/BI, DL, /*AllowQQLeaves=*/false)`.** |
| — | `collectCondTree` | ADD one call before step 1, `collectCondTree(R.Condition, Tree, /*AllowLogicalSelect=*/false)`; a false return is `bailLoud`. |

**The byte-identity claim, established BY READING the code (the brief asked; no rebuild was done):**
for a bare `CmpInst` root, `collectCondTree` yields `Leaves={Cmp}`, `Nodes={}`, `RailLeaves={}`.
`emitCondNetwork` (`CondTreeEmit.cpp:113-189`) then (a) skips the `AllocI1` resolution entirely
(`if (!Tree.Nodes.empty())`, `:116`), (b) hits the `dyn_cast<CmpInst>` leaf arm at `:169` and calls
`lowerCompareToFlag(Leaf, wd, taint, qqWidth = AllowQQLeaves ? qqSelectLeafWidth(Leaf,taint) :
StringRef(), /*inverse=*/false, /*before=*/Before)` — **with `AllowQQLeaves=false` that is the
identical call to `ClassicalCallArmEmit.cpp:197`, argument for argument** — and (c) sets
`Out.Root = F`. `stripCondNetwork` (`:192-232`) with no nodes runs only the leaf loop:
`lowerCompareToFlag(LF.first, …, qqWidth={}, /*inverse=*/true, /*before=*/Before, /*negate=*/false,
/*railToStrip=*/LF.second)` then `freeFn(LF.second)` — **the identical pair to
`ClassicalCallArmEmit.cpp:259-261`**. Insertion point is `BI` in both. ⚠ **`AllowQQLeaves` MUST be
`false`.** `emitSelectRegion` passes `true` (the bd `adia` policy); passing `true` here would give a
Q+Q 6.5 condition a mint it does not have today — a widening as a side effect of a mechanism change,
which is the trap `emitValueRegion:441-450` documents in its own words.

### 1.5 Sites that need NO change (verified)

* `RegionFlatten.cpp:96` (flat), `:189`/`:193` (nest) — the `!isCondRailLeaf(Cond)` guards already
  land, added by Inc 1b for exactly this reason.
* `SelectMergeEmit.cpp:111-114` — the `RailLeaves` drift guard. **B.1 replaces it** (its §2 says
  invert it: a rail root that reached the emitter without an ancilla bails loudly). B.2 adds no
  further change there.
* `CondTreeEmit.cpp:160-168` (`isCondRailLeaf(V) → FlagOf[V] = V`) and `:188` (`RootIsRail`) — B.1
  extends these with `CopyRailRoot`; B.2 is a pure consumer.
* `Specialization.cpp:288` — already refuses any tree with `RailLeaves`.

---

## 2. The minimal design

### 2.1 B.2a — the 6.5 classical-call arm (SMALL, and it is the half with the customer)

1. `ArmClassify.cpp:4542` — admit a rail root; add the three-rung ladder (tainted /
   `railMeasuredBeforeBranch` / `railCondWireDisposition`), reusing B.1's `ReadPoint`-generalised
   helper with `ReadPoint = Region.Pred->getTerminator()`.
2. `ClassicalCallArmEmit.cpp` — `Value *Cond`; swap the direct `lowerCompareToFlag` mint/strip pair
   for `collectCondTree` + `emitCondNetwork(AllowQQLeaves=false)` + `stripCondNetwork`. The stream
   between them is untouched: out-rail alloc, `materializeCopySource`, two X-bracketed
   `cqrt_copy_<W>_controlled`, RAUW, `flattenRegion`.
3. Nothing in `classifyArms`, `SwapRouteEmit`, `SelectClassify`, `SelectMergeEmit`,
   `AngleSelectEmit`, the runtime, the YAML or `include/`.

**Target stream**, read off `x3`'s measured lowered IR with the mint/strip pair substituted (the
only two lines that change):

```
%h_b  = cqrt_alloc_i1(false) ; cqrt_ry_i1(%h_b, 0.5)   ← the user's rail
%2    = call fastcc i32 @f(i32 %x)                      ← hoisted, unconditional
%bf   = cqrt_alloc_i1(false)                            ┐ B.1's CopyRailRoot mint
        cqrt_cnot(%h_b, %bf)                            ┘
%out  = cqrt_alloc_i32(0)
%selop= cqrt_alloc_i32(%2)          ; cqrt_copy_i32_controlled(%bf, %selop, %out)
        cqrt_x(%bf)
%selop1=cqrt_alloc_i32(5)           ; cqrt_copy_i32_controlled(%bf, %selop1, %out)
        cqrt_x(%bf)
        cqrt_cnot(%h_b, %bf)                            ┐ B.1's strip
        cqrt_free(%bf)                                  ┘
        cqrt_measure_i1(%h_b) ; cqrt_measure_i32(%out)
```

Two `cqrt_x` on the **ancilla** `%bf`, never on `%h_b`; two `cqrt_cnot` with `%h_b` as a READ-ONLY
control; one `cqrt_free`. Byte-identical to `x3`'s golden apart from `icmp_sgt_i32_hl`↔`alloc_i1;cnot`
and `icmp_sgt_i32_hl_unc`↔`cnot`.

### 2.2 B.2b — the value arm (LARGER blast radius)

1. `ArmClassify.cpp:2124-2131` — admit a rail root; hoist the ladder to just after it (before
   `Prov` is built, so `condProvenance` still runs unchanged); skip 2141 and 2159-2186; dispatch
   2201 to `railCondWireDisposition`.
2. `ArmClassify.cpp` — the **four re-declines** of §1.1a at the phase / eq-fold / rotation /
   state-prep accept sites, each `kBareRailCondReason`.
3. `SwapRouteEmit.cpp:294` — `Value *Cond`; guard 447-450 and 486-489 behind `isa<CmpInst>`, and
   add the rail pre-flight (`wd.allocFn("i1")` + the cnot symbol resolve) so the F-V1-2 property is
   preserved for the new condition kind.
4. `SwapRouteEmit.cpp:920/962` — widen the dispatcher's `Cond` derivation for the VALUE branch only;
   the rotation branch at `:975` and the phase path at `:1133`+ keep a `CmpInst *`.
5. `emitSelectRegion` at `:583-585` is called **verbatim** — B.2b writes no merge of its own, which
   is the Rule-14 point and is why its clearance is B.1's plus the classifier's.

**Witness**, exactly Inc 2's argument one condition-kind over: byte-identity between
`if (b) { 6-op chain }` and its manually pre-hoisted `select` twin
(`p = b ? R(p) : p` with the chain written straight-line before it), which **B.1's binary already
lowers**. So the comparison is against the *previous* compiler's stream, not against itself. Four
`compare_files` gates would mirror
`e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical`.

---

## 3. Size estimate and hazards

### 3.1 Size

| | production lines | files | fixtures | slices/goldens |
|---|---|---|---|---|
| **B.2a** (6.5) | **~35-50** (3 rungs + a ~15-line mint/strip swap + comments; the comments will be 3-4× the code, as is house style) | 2 (`ArmClassify.cpp`, `ClassicalCallArmEmit.cpp`) | ~10 (4 accept / 6 decline) | 2-3 |
| **B.2b** (value) | **~60-90** (the gate + ladder + 4 re-declines + 3 emitter guards + the dispatcher split) | 3 (`ArmClassify.cpp`, `SwapRouteEmit.cpp`, + the `ArmAnalysis.h` export B.1 already makes) | ~22 (10 accept / 12 decline) | 6-8 + 4 twin gates |

No new runtime symbol, no YAML change, no `include/` change (owner D3) in either half. `ir-pass-lit`
would go 1738 → ~1770; `ctest -N` 377 → ~390 (B.2b's four `compare_files` gates plus the slices).

### 3.2 Hazards — every one is a place where a rail's OTHER users meet the hoist or the spine

**H-1 — the register's disposition when it is DEAD after the region (SHARED WITH B.1, and B.1 must
answer it first).** After the merge, `%h_b`'s only users are the two `cqrt_cnot(h_b, bf)`. The
register is `Ry(θ)|0⟩ ≠ |0⟩`, so freeing it is a hidden measurement (Rule 6). MEASURED by reading:
`ChainWalk.cpp:833-844` lists `cqrt_cnot` among the users that **DISQUALIFY** a rail from
`preservesBasisUnderRecord` ("any `_controlled` gate or route … — Phase-4 owns the rail … a Rule-6
SAFE LEAK"), and `Uncomputation.cpp:661-668` puts `cqrt_cnot` on the mutation side of
`preservesBorrowedParent`. So the spine should leave it allocated — but **that is a reading, not a
measurement**, and it is exactly the shape B.1's `..._rail_dead_register.ll` fixture is built to
pin. B.2 inherits whatever B.1 measures; if B.1 finds the spine *does* close the DAG there, B.2
inherits the defect at two more emitters.

**H-2 — the value chain's FINAL rail is left ALLOCATED AND DIRTY (PRD §0 E1), and the rail
condition adds a second retained register.** `emitValueRegion`'s own header (`:566-587`) argues
soundness from clause (b): *"no CQ-EXPRESSIBLE CONTINUATION can observe the difference, because
`out`'s own retained label already records `R(p_old)`… and the ABI mints no in-place Q+Q gate on
`out`"*. With a rail condition the surviving registers are `(h_b, p_old, out)` instead of
`(q, p_old, out)`. **The argument carries** — the chain runs unconditionally on `p` and is
independent of `b`; `b` is touched only as a cnot control — but it is a NEW instantiation of a
clause that is a fact about the shipped ABI, and the Rule-13 round must re-derive it rather than
cite it. In particular: `cqrt_cnot(h_b, bf)` **is** an in-place Q+Q gate on `bf`; clause (b) is
about `out`, so it is untouched, but a reviewer will (rightly) ask.

**H-3 — a chained Ry on the rail AFTER the region (the S†, `y4`).** MEASURED: `y4` declines
`bare i1 register condition` today. Under B.2b it would reach `railCondWireDisposition`, which
returns `ProvenPostRegion`, and then **P1 at `:3455` REFUSES it because `SawValueArm` is set**. So
`y4` would still decline, now on `condition predates a non-diagonal gate`. Two possible
dispositions, and **the increment must not pick one by accident**:
 * keep P1's value-arm refusal (an over-decline; the S† is the Grover cascade's own idiom and the
   owner has already written it in `k3_flat_sdagger.c`); or
 * argue the widening. P1's argument for the phase/rotation side is "copies nothing, replays
   nothing, allocates no work rail", and a value arm **does** copy — but with a RAIL root there is
   no `icmp_inv` strip reading the register's basis at all: the strip is `cqrt_cnot(h_b, bf)`, which
   reads the same wire the copies read, at the same point. That is a genuinely different argument
   from the compare case and it needs its own derivation. **Do not fold it into B.2 silently.**
   File it, or make it the increment's explicitly-argued centrepiece.
 The 6.5 half has the identical question (`z5`-shaped programs), and `classifyClassicalCallArm` has
 no P1 wrapper at all — so B.2a would ACCEPT the S† where B.2b declines it. **That asymmetry is a
 finding waiting to happen**; decide it once, in one place.

**H-4 — IN-LOOP. Keep declining, and note the fence that fires is not the one you expect.**
MEASURED: `y5` (a 6-op value diamond on an invariant rail inside `for (i<3)`) declines
`bare i1 register condition` at `classifyArms` — meaning `flatRegionRollableInLoop` ADMITTED it and
set `R.InLoop = true` (`ControlDetect.cpp:625-628`). If 2124 widens, the next fence is
`ControlDetect.cpp:668-673` (`R.InLoop && ClassArm == Value` → `control flow inside a loop body`),
which is correct and must be left alone. For 6.5, `ControlDetect.cpp:645` **skips
`classifyClassicalCallArm` entirely when `R.InLoop`** — also correct, also must be left alone.
⚠ And the COMPARE twin has no accepting form either: `z1` (the same loop with `if (q > 5)`)
declines `condition predates a non-diagonal gate` at `%3 = icmp sgt i32 %1, 5` — the documented
LICM-hoisted-invariant-condition over-decline (CLAUDE.md row W). So there is nothing to be
twin-identical *to*, and an in-loop e2e pair for B.2 would have no baseline. **Do not build one.**

**H-5 — the C-1 in-loop leak family (`taint.ClaimedRailRoots`, `InPlaceRailOps`,
`InLoopFlattenedPreds`).** Not reached by B.2 while H-4's two loop fences stand — but the moment
either is narrowed, a rail-condition value region inside a loop mints a `cqrt_alloc_i1`+`cnot` pair
per activation with nothing discharging it, which is the F-L7-2 / F-R1-1 / F-C1 shape verbatim, and
**stage 2b is structurally blind to it** (a leaked TEMPLATE-minted rail has no `cqrt_alloc` to
count — here it *does* have one, `alloc_i1`, which is a small mercy but not a fence). Record this in
the PRD as the re-opening condition.

**H-6 — the rail read by the value chain itself.** MEASURED and it is a *non*-hazard from plain C:
`y3` (`if (b) { p = p + b; … }`) has `-O1` fold `b` to `1` on the true edge, so the emitted chain is
`add %4, 5` and **never reads the rail** (compare `y1`'s `add %4, 15`). The hazard is hand-IR only
(a `zext i1 %b` inside the arm), where it is caught by the §3c/`diagonalAliasHit` check only if the
chain's *base* is the rail — a `zext` OPERAND is not. Needs a decline fixture and a decision: the
cleanest is that `walkValueChain`'s Q+Q defer (`Chain.HasQQ` → `value-arm swap-route`, `:3326`) will
catch a tainted second operand, which the `zext` of a tainted rail is. **Verify that by fixture, do
not assume it.**

**H-7 — `HasDataUse` is not merely inapplicable, it is actively wrong if left in.** For a rail,
`Region.Condition->users()` contains the `cq_measure_i1`, so `HasDataUse` is TRUE for the owner's
own idiom, and `condDataUseDisposition` would then adjudicate the register as a *flag lineage*.
Depending on the shape it returns `ShareOk` (setting `ShareCondFlag`, which `emitValueRegion:307`
then turns into `condition used outside the branch`) or `MeasuredEarly`/`Unowned`. **Every outcome
is a wrong answer about the wrong object.** The skip is mandatory, not an optimisation.

**H-8 — a second region on the same rail (`z3`, `z5`).** `if (b) { chain } if (b) cq_phi(.9);`
mints an ancilla-copy flag in region 1 and (after Inc 1b) fires the kickback directly on the rail in
region 2. Emission ORDER across sequential regions is `lowerControlRegions`' Kahn sort (bd `hcrg`);
the two regions do not share a flag, so nothing is aliased — but the trace ORDER is the property to
pin, and `..._rail_two_regions.ll` is on B.1's fixture list for the select. B.2 owes the value and
6.5 spellings.

**H-9 — `emitValueRegion`'s Q+Q and mint pre-flights (`:447`, `:486`) are the F-V1-2/F-V1-9
findings, and guarding them behind `isa<CmpInst>` DELETES a fence for the new kind.** Replace, do
not skip: the rail's mint can fail too (`wd.allocFn("i1")` null, or the cnot symbol unresolvable),
and it fails **after** the hoist / select-build / RAUW / flatten unless it is asked pre-mutation.
This is the single most likely place for B.2b to reintroduce a mutate-then-decline.

### 3.3 Probe / fixture families

**DECLINE fixtures (each mirroring its string character-for-character on a `RUN: not …` line; a
`DS_Error` decline writes 0 bytes to stdout so IR negatives are vacuous — say so in the header):**

| fixture | shape | string |
|---|---|---|
| `control_swap_reject_value_rail_measured_before.ll` | `cq_measure(b)` before the branch | `condition measured before the control route` |
| `..._rail_measured_sidepath.ll` | classically-guarded measure that can precede (F-1b-2) | same |
| `..._rail_sibling_theta.ll` | `b=θ(t); c=θ(t); if (b) {chain}` — the F-1b-1 class | `condition predates a non-diagonal gate` |
| `..._rail_chained_between.ll` | `%b=θ(u); %c=θ(%b,·); br i1 %b` | same |
| `..._rail_zext_in_chain.ll` | H-6: the arm chain reads `zext i1 %b` | measure it — expected `value-arm swap-route` (Q+Q defer) |
| `..._rail_clobber.ll` | the chain's base IS the rail (§3c) | `arm rewrites a condition operand` |
| `..._rail_inloop.ll` | H-4 | `control flow inside a loop body` |
| `..._rail_trunc_cond.ll` / `..._rail_phi_cond.ll` | a derived / loop-carried i1 is NOT a rail leaf | `control flow` (the discriminator; bd `boi6`/`r903`) |
| `control_inplace_ry_reject_raw_i1_cond.ll` | 1b-C — **must stay green with `kBareRailCondReason`** | `bare i1 register condition` |
| `control_classical_call_arm_reject_rail_measured_before.ll` (+ sidepath, sibling-theta) | the 6.5 mirrors | as above |
| `control_classical_call_arm_reject_rail_inloop.ll` | H-4's 6.5 half | `control flow inside a loop body` |
| a **state-prep** and an **eq-fold** rail decline | §1.1a rows 1/2/4 | `bare i1 register condition` |

**ACCEPT fixtures** — each with whole-file negatives in their OWN prefixes (`NOROUTE-NOT: cqrt_cswap`,
**`NOX-NOT: cqrt_x(i32 %h_b`** — no `cqrt_x` on the REGISTER, the non-negotiable — `NOUNC-NOT` where
applicable) and exact counts in their own prefixes (`XCNT`, `FCNT`, `CNCNT`, `RYCNT`), derived from
the pass output and never guessed. Run the injection matrix (an injected `cqrt_x(i32 %h_b …)`, an
extra `cqrt_free`, an extra `cqrt_ry` on the register, a `cqrt_cswap`, a rail handle in a classical
immediate slot) and require each to redden ≥ 1 prefix in EVERY accept — the Inc-1b/eqpx lesson is
that the first run of that matrix reads MISSED.

* `control_swap_value_rail_diamond.ll` (`y1`), `..._rail_ifelse.ll` (`y2`),
  `..._rail_mixedops.ll`, `..._rail_polarity.ll` — the four twin subjects;
* `..._rail_post_ry.ll` (`y4`) — **only if H-3 is decided as an accept**; otherwise it is a decline
  fixture;
* `..._rail_two_regions.ll` (`z3`), `..._rail_dead_register.ll`, `..._rail_i8/i64_widths.ll`;
* `control_classical_call_arm_accept_rail_i32.ll` (`x2`), `..._rail_onward_arith.ll`,
  `..._rail_nonI32_cast.ll`, `..._rail_frozen_arg.ll`.

**e2e (all STRICT stage 2b):** `slice_control_value_bool_{diamond,diamond_twin,ifelse,ifelse_twin}.c`
+ two `compare_files` gates; `slice_control_classical_call_bool.c` + its `int` twin (a **reduction**
of the compare golden, so **no** `compare_files` gate — the Inc-4 precedent: a gate would assert
something false).

**Probes to transcribe into `probes/` (prefix `t`)**, with the `main` 87d0699 verdict recorded:

| probe | shape | `-O1` | `main` 87d0699 |
|---|---|---|---|
| `v1` | `if (b) a = a+3;` | `select` | `bare i1 register condition` @ the select (`SelectClassify:968`) |
| `v2` | `+3` / `*2` if-else | `select` | same |
| `v3` | `if (b) a = a+b;` | no control at all | **exit 0** |
| `v4` | `if (b) b = !b;` | folded to `false` | `cq_measure_<sfx> operand not recognized` |
| `v5` | `if (b) b = cq_theta(b,.3);` | diamond, `phi i1` | `bare i1 register condition` @ the rail (**1b-C**) |
| `v6` | 6.5 with a const arg | const-folded to `select` | `bare i1 register condition` @ the select |
| `v7` | `v1` in a loop | `select` in the body | `loop-carried tainted value crosses iterations` |
| `v8` | `v1` then `b=θ(b,-.5)` | `select` | `condition predates a non-diagonal gate` |
| `w2` | `if (b) a = a/n;` runtime `n` | **diamond** | `bare i1 register condition` @ the rail; ⚠ its compare twin `x5` declines `value arm op that cannot run unconditionally` — **not a B.2 customer** |
| `x2` | 6.5, `noinline const` callee, runtime arg | **diamond** | `bare i1 register condition` @ the rail (`ArmClassify:2129`) |
| `x3` | `x2`'s `int` compare twin | diamond | **exit 0** — the 6.5 stream |
| `y1`-`y5` | 6-op value chain: diamond / if-else / reads-rail / S† / in-loop | **diamonds** | all `bare i1 register condition` @ the rail |
| `y6` | `y1`'s `int` compare twin | diamond | **exit 0** — 24 lowered lines |
| `z1` | `y6` in a loop | diamond in body | `condition predates a non-diagonal gate` @ the icmp (**row W**) |
| `z2` | measure `b` before the region | diamond | `bare i1 register condition` (would become `condition measured before the control route`) |
| `z3` | value region then kickback on one rail | 2 diamonds | `bare i1 register condition` |
| `z4` | sibling theta on the rail's parent | diamond | `bare i1 register condition` (would become the wire string) |
| `z5` | 6.5 then kickback on one rail | 2 diamonds | `bare i1 register condition` |

Commands used throughout:
`/usr/local/opt/llvm@19/bin/clang -I<repo>/include -include CQ.h -O1 -emit-llvm -S P.c -o P.s1.ll`
then `build/ir-pass/cq-opt -passes=cq-lowering -S P.s1.ll -o P.s2.ll` (and `CQ_CTRL_DBG=1 … 2>&1 |
grep CQ_CTRL_DBG` for the decline anchor).

---

## 4. Recommendation

**FILE B.2 as its own increment. Do NOT build it in this session after B.1's review.** Four reasons,
in order of weight:

1. **B.2's entire lowering is B.1's `CopyRailRoot` mint, and B.1 is not yet reviewed.** Both halves
   are pure consumers: B.2a swaps `lowerCompareToFlag` for `emitCondNetwork`, B.2b hands the region
   to `emitSelectRegion` verbatim. If B.1's round finds a defect in the CNOT-copy flag (H-1 is the
   live candidate), B.2 propagates it to two more emitters before anyone has looked at one. The
   epic's own record is unambiguous about this: eight silent miscompiles over six adversarial rounds
   on one function, **two of them introduced by a fix** and one found by a round reviewing a
   *different* increment. Stacking an un-cleared mechanism is how that count got to eight.
2. **The VALUE half has almost no plain-C customer, and none of the owner's.** §0.1 is measured:
   every short value arm — the owner's program included — is a `select` that **B.1 already fixes**.
   B.2b buys the ≥ 5-op chain and hand IR. That is real (`y1`-`y4` are honest programs) but it is
   not urgent, and Rule 16's phase discipline says do not bundle it into the increment that ships
   the thing the owner asked for.
3. **`classifyArms` is the wrong function to widen opportunistically.** It is 1348 lines with six
   arm classes and roughly thirty declines; four of those classes (phase, eq-fold, in-place rotation,
   state prep) belong to **1b-C** (bd `l4x4`) and must keep declining. Getting that partition wrong
   is an over-accept in the most-fenced function in the pass, and the file's own `SawRotationArm`
   comment records that the one-directional version of exactly this kind of check was already wrong
   once ("Luck is not a fence").
4. **H-3 is a real open question, not a detail.** The S† after a value region is the Grover
   cascade's own idiom, the owner has already written it, and B.2a and B.2b would answer it
   *differently* by accident (6.5 has no P1 wrapper; the value path does). That deserves its own
   derivation and its own owner question — which is precisely what an increment boundary is for.

**If the owner wants one half now, take B.2a (6.5) and not B.2b.** It is ~35-50 production lines in
two files, adds no fence to `classifyArms` at all (three rungs at one `return NotApplicable`), has a
plain-C reproducer whose compare twin already accepts, and its emitter change is provably a refactor
(§1.4). It should still wait for B.1's clearance, and it should carry H-3's answer explicitly.

**Filing.** Split the bead: `r9e5` → **`r9e5.a`** (6.5 classical-call arm on a rail; depends on B.1
cleared) and **`r9e5.b`** (value arm on a rail; depends on `r9e5.a` for the H-3 ruling). Record in
the PRD §14 draft: §0.1's measurement (the value arm is a `select` from C), H-3 as an owner
question, and H-5 as the re-opening condition for the loop fences.
