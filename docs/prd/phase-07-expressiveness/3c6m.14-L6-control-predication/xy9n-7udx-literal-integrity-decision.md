# Literal integrity — bd xy9n + bd 7udx

**Status:** SHIPPED, branch `3c6m.14-control-l6`, 2026-08-09.
**Scope:** one new TU (`ir-pass/src/LiteralIntegrity.{h,cpp}`) plus call sites in
`CQLoweringPass.cpp`, `RegionFlatten.cpp`, `PredMuxFlatten.cpp`,
`AbortParkEmit.cpp`, `GuardedStoreArmEmit.cpp`, `Fp80Union.cpp`. **No frozen
symbol, no YAML edit, no new runtime template, no new gate sequence.** **24** new
lit fixtures (966 → 990), and `Specialization.cpp` also carries a fence — see §5b. **Successor to** `u1rp-poison-family-decision.md`, whose Rule-13 round
filed both tickets and whose framing this document assumes throughout.

Both defects are **PRE-EXISTING and BASE-identical** — neither was caused by
`fb30245`, and both were reproduced by that round's judge rather than by the
orchestrator. Every number below was **re-measured this session** against a BASE
plugin rebuilt from a clean worktree at `fb30245`, whose `sha256` reproduces the
recorded pre-change hash **bit-for-bit**
(`1e38ace79618df97f2b243d79c7fe382ee5301945c1dc3b803bf799a00a0e7a3`).

---

## 1. THE DECISION, AND THE COUNT THAT FORCED IT

bd xy9n was filed against the **4.4 select** surface, with a fix direction of
"refuse a literal undef/poison operand at the 4.4 select classify gate". The
open question was whether that is enough or whether the same physics lives on
other surfaces — and the answer changes the target: N per-surface gates, or ONE
module-wide guard.

**Measured first, before any code was written.** The decisive single measurement
took five minutes and needed no agent: the pairing break reaches with **no
control flow of any kind**.

```llvm
define void @slice(i32 %x) {
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = add i32 %q, poison        ; dead terminal
  ret void }
```

emits, on BASE, `opt` exit 0 and `opt -verify` clean:

```
%h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 poison)
call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 poison)
```

No branch, no select, no switch, no region, no cone proof — just the Phase-5
whole-DAG LIFO spine. A select-local gate would not have touched it.

A reach-gated census then mapped the full surface list. **Every row below has an
accepting CONTROL** (the same module with a defined literal), so each is a
one-token delta against a working baseline, not a shape that happened to decline.

| # | surface | owner | carries it? | notes |
|---|---|---|---|---|
| 1 | whole-DAG LIFO spine, **NO control** | `Uncomputation`/`ChainWalk`/`EmitInverse` | **YES**, 9/9 rows | `icmp _hl`, `fcmp _hl`, non-terminal, `and`/`xor`, mixed-width cast chain, **the `_lh` literal-LEFT slot**, both spellings |
| 2 | 4.1 phase arm + if/else | `SwapRouteEmit` | **YES** | the tainted-`br` compare literal. The arm **angle** does NOT pair (a phase arm's `Rz` is emitted once) |
| 3 | 4.2 value arm (method-B) | `SwapRouteEmit` | **YES** | arm head **and** terminal literals — method-B reverse-plays the arm, so both are re-read |
| 4 | 4.3 depth-2 nested route | `NestedRouteEmit` | **YES** | both the outer and the inner flag compare |
| 5 | 4.4 select (int + fp) | `SelectMergeEmit` | **YES** — bd xy9n | f64, f80, the OR-tree condition, and a **multiplier** row: ONE source literal into FOUR emitted slots over TWO flag rails |
| 6 | 4.5 switch — **VALUE shape only** | `SwitchValueEmit` | **YES** | the other three shapes decline first for unrelated reasons, and a `switch` case value cannot even be spelled `poison` (LLVM parse error) |
| 7 | 6.5 classical call under quantum control | `ClassicalCallArmEmit` | **YES** | the condition compare literal |
| 8 | Phase-6 specialization | `Specialization`/`BennettWrap` | **YES** | incl. the **cross-function** clone/twin pair — see §3 |
| 9 | 7.3 loops (Case B) / 7.4 break reverse-play | `LoopLowering`/`BreakReversePlay` | **YES** | 4 `_unc` rows + the `cqrt_addc`/`cqrt_xorc` re-emission rows |
| 10 | 7.5 QRAM | `QramLowering` | **YES** | the derived tainted index. A *raw* literal in the gep slot is already fenced (`kMsgStore`), and a poison `memset` fill byte by `kMsgQramInit` |
| 11 | 7.6 output tape | `IOSinkLowering` | **YES** | the written value, and the controlled write's flag-mint compare |

**Eleven surfaces.** The single shared mechanism is
`EmitInverse`'s operand copy (`Forward->getArgOperand(i)`), which every surface
with an adjoint uses. `grep -niE 'poison|undef|PoisonValue|UndefValue'` over
`ControlDetect.cpp`, `ArmClassify.cpp`, `SwapRouteEmit.cpp`,
`RegionTreeDetect.cpp`, `NestedRouteEmit.cpp`, `RegionFlatten.cpp` and
`EmitInverse.cpp` returns **zero hits** — there was no fence to extend anywhere
except in `PredMuxFlatten`'s cone proof, which by construction only runs on a
poison-shielded select-form inside a claimed PredMux region.

**So: ONE late module-wide guard, not eleven per-surface gates.** The property
that buys is *surface-independence by construction* — the guard sits at the
emitted-call layer, so a twelfth surface cannot forget it. Two of the measured
rows are ones a per-surface or per-function fix would have missed outright: the
`_lh` literal-LEFT slot (row 1) and the cross-function Phase-6 clone/twin pair
(row 8).

---

## 2. THE THRESHOLD IS TWO SLOTS, AND MEASUREMENT MOVED IT THERE

The first draft refused **any** emitted gate operand carrying a literal
undef/poison. That draft was **wrong**, and the corpus said so.

| population | modules | `undef`/`poison` **anywhere** | the guard's own predicate: an emitted gate operand |
|---|---|---|---|
| `ir-pass/test/*.ll` | 966 (451 accepted) | 10 | **0** |
| e2e stage-1 | 257 (239 accepted) | 26 | **1** |
| openlibm `-O1` | 251 (251 accepted) | 56 | **0** |

Measured twice — by the orchestrator and, independently, by a census agent — with
the same answer. **openlibm carries ZERO taint sources, so all 251 modules take
the pass's passthrough early-out: that layer is a shape census with NO FENCE
POWER** and must be quoted that way.

The one hit is not a probe. It is `tests/e2e/slice_libm_real_nexttoward`, a
shipped slice with a committed golden:

```
%selop = call i32 @cqrt_alloc_f64(double undef)
call void @cqrt_copy_f64_controlled(i32 %h_cmp85, i32 %selop, i32 %out86)
```

`clang -O1`'s **own** stage-1 output emits `select i1 %c, double undef, double %v`
for the dead early-exit merge edge of nexttoward's `x == y` test, and the
4.4/kjd1 fp-select merge materialises that `undef` as a rail seed. Structurally:
**985** emitted calls in that module, **exactly one** undef-bearing slot,
`double undef` appears **exactly once** module-wide, and `%selop` is **never
freed**.

**Why one slot is sound — and state it on the RIGHT invariant.** The defect is a
PAIRING break. *An earlier version of this section said "one slot is one
`IMPLICIT_DEF` materialisation, so there is no second read to disagree with", and
the Rule-13 round MEASURED THAT FALSE:* `undef` may take a different value at every
DYNAMIC read, and one static slot inside a rolled loop gave SIX reads with TWO
distinct values.

The conclusion survives on a stronger invariant the round verified instead: **CQ
never builds an adjoint by re-executing the forward site.** Every adjoint is a FRESH
STATIC CALL (`EmitInverse`'s `CreateCall`/`CreateFNeg`/`CreateNeg`,
`BreakReversePlay`'s `clone()`), so a forward and its adjoint are always two
DISTINCT static slots and any real pairing is always ≥2. A lone slot therefore has
no adjoint at all: nothing claims to invert it, so no `cqrt_free` asserts `|0⟩` on
its behalf, Rule 6 is untouched (the rail is left allocated, exactly as Rule 6
prescribes for a rail not provably `|0⟩`), and repeated dynamic reads of it are
precisely what the source's `undef` already licenses.

**The threshold's hardest case, attacked deliberately: a one-slot undef rail that
IS freed.** The nexttoward argument leans partly on `%selop` never being freed, so
the obvious attack is a one-slot shape where the rail *is*. It exists:

```llvm
%q = call i32 @cq_theta_si32(i32 undef, double 2.500000e-01)   ; the SEED slot
%d = add i32 %q, 7                                              ; dead terminal
```
lowers, on BOTH plugins byte-identically, to `cqrt_alloc_i32(i32 undef)` … and a
closing `cqrt_ry_i32(%h, -2.500000e-01)` + **`cqrt_free(i32 %h)`** on the
undef-seeded rail. `free_pairing_check.py` reports 2/2 verified, 0 unproven.

**It is still sound, and the reason generalises.** `cqrt_alloc_<W>(seed)` initialises
the rail to `|seed⟩`, so `cqrt_free` never meant "`|0⟩`" in the absolute sense on an
allocated rail — it means the rail was restored to the basis value it was allocated
with, which is what the checker proves by cancelling the `Ry`. With ONE
materialisation the seed is unknown-but-FIXED, so "restored to its initial value"
is still a well-defined, satisfied claim; the defined-seed case
`cqrt_alloc_i32(i32 %x)` has exactly the same shape. Two materialisations is what
would break it — allocate against `L1`, restore against `L2` — and that is two
slots, which declines. So the threshold is not an artefact of nexttoward's
never-freed rail; it tracks the actual invariant.

(Note in that same output that `cqrt_ry_i32(%h, 2.5e-01)` is correctly inverted to
`-2.5e-01`. `EmitInverse`'s `CreateFNeg`/`CreateNeg` only degenerates on poison,
where `fneg poison` and `sub 0, poison` fold back to `poison` and the negation
vanishes silently — a second, independent reason those shapes must decline, and one
that would make the adjoint wrong even under a single materialisation.)

This is the **bu96 doctrine** applied to the literal spelling. bu96 declines to
fix a poison-generating `ConstantExpr` because a `Constant` is uniqued into ONE
link-time relocation, so its forward and adjoint agree. Same discriminator, same
answer: **reason from pairing, never from LangRef refinement** — refinement
("poison permits any value") is true of *both* kinds and is therefore not what
makes the two-slot case wrong.

The threshold is pinned by `lowering_accept_undef_literal_single_slot.ll`, a
seven-line reduction of the nexttoward shape that lowers identically. **Raising
the threshold to one slot turns that fixture red — which is precisely the
regression that would have broken a shipped golden.**

Counting is **per module, not per function**, because Phase-6 mints the forward
clone `@__cq_q_<f>_<mask>` and its uncompute twin `@__cq_q_<f>_<mask>_unc` as two
separate functions; the census measured that exact cross-function pair (row 8), so
a per-function count would have had a hole with a probe already sitting on it.

Counting is **spelling-independent**, also deliberately. The obvious spelling —
"refuse a literal undef/poison in an `_unc`/`_inv` adjoint" — misses the rotation
case entirely, because a rotation's adjoint is the **same symbol with a negated
angle** and `fneg poison` folds back to `poison`:

```
call void @cqrt_rz_i32(i32 %h_op, double poison)
call void @cqrt_rz_i32(i32 %h_op, double poison)   ; the "adjoint"
```

Two textually identical lines, no `_unc` anywhere in the module.
`lowering_reject_undef_literal_paired_rz_angle.ll` pins that.

---

## 3. PLACEMENT, AND WHY IT IS COMPLETE THERE

`declineUnpairedUndefLiterals(M)` runs **after `uncompute`**, in **both** pipeline
entry points (twin-pipeline parity, WI-1.12 — miss the second and a unit-level
caller silently keeps the defect). That is the only position that provably sees
every emitted call, forward **and** adjoint.

Completeness there rests on one verified fact: **the pass never synthesizes an
`undef`/`poison`.** There is no `UndefValue::get`, `PoisonValue::get` or
`getUndef` anywhere in `ir-pass/src` or `ir-pass/include`; the only constant the
pass mints is `Constant::getNullValue`, i.e. zero. So every literal undef/poison
in an emitted slot was copied out of the input module and is already present by
the time the guard runs.

Declining after mutation costs nothing observable: `LLVMContext::diagnose` on
`DS_Error` calls `exit(1)` under `opt`'s default handler — **measured: exit=1,
`stdout_bytes=0`** — so the "lower nothing" posture of Rule 1 holds observably.
Both guards nevertheless return `bool` and every caller bails, because a guard
whose correctness depends on `exit` inside a callee breaks silently on a host that
installs its own diagnostic handler.

---

## 4. bd 7udx — A DIFFERENT DEFECT CLASS, AND MUCH WIDER THAN THE TICKET

**Do not merge this row with the poison family.** The source program is
**WELL-DEFINED**: no UB, no refinement argument, nothing to excuse the
divergence. And the round's own framing needed one **correction** the census
supplied: forward and adjoint carry the **same** wrong value, always — every
erasing stage runs strictly before `lowerRotations`/`lowerOps`/`uncompute`, so
this is a **uniform wrong-constant miscompile (wrong unitary)**, not a
forward/adjoint divergence. The rail pairing is genuinely intact, which is exactly
why `free_pairing_check.py` reports STRICT CLEAN.

Mechanism: `BasicBlock::~BasicBlock()` (LLVM 19) replaces every `BlockAddress` of
a destroyed block with `inttoptr (i32 1 to ptr)`, which folds through a
`ptrtoint` to `i32 1`. **That RAUW is module-wide on the `BlockAddress`
constant**, so the corruption is not confined to the region, nor to emitted
quantum operands:

* in-region compare → `cq_template_icmp_sgt_i32_hl(%h, i32 1)`;
* a bare `store ptr blockaddress(@f, %arm), ptr @slot` in a **different,
  untouched function** → `store ptr inttoptr (i32 1 to ptr)`, while the compare
  beside it keeps its correct literal;
* **worst measured case:** a live `indirectbr` destination erased out from under a
  still-live computed `goto` — the compiled program transfers control to address
  1, with `opt` exit 0 and verify clean, on a path with no quantum semantics in it
  at all.

### Breadth, measured

A non-perturbing injector (append a holder function whose
`store ptr blockaddress(@F, %BB)` takes a block's address, leaving the lowered
function byte-identical) over all 966 fixtures: **164** fixtures had an accepting
control and ≥1 target → **448** (fixture, block) variants → **308 corrupt**, 105
clean, 35 decline. **126 of 164 fixtures corrupt at least one block.**

**The load-bearing negative:** not one of those 35 declines mentions
`blockaddress` or address-taken — 33 are an unrelated specialization purity
rejection the injected store perturbs, 1 a loop-carried taint, 1 a classical-phi
escape. There was **no blockaddress fence anywhere in the pass** except
`LoopUnrollPrepass.cpp:211`, which is a *silent non-claim* covering only a loop
**header**.

### The site list, measured rather than assumed

| site | doomed set | status |
|---|---|---|
| `flattenRegion` | arms + **merge** | guarded — covers 4.1, 4.2, the 4.5 eq-folded diamond, 6.5, 7.6 |
| `flattenRegionTree` | Mid + InnerArm + shared Merge | guarded (4.3) |
| `flattenSwitchRegion` | every arm + Merge | guarded (4.5) |
| `PredMuxFlatten` | `R.Topo \ {Entry}` — **widest**, an arbitrary acyclic sub-CFG | guarded **at claim** |
| `AbortParkEmit` | the sink arm | guarded |
| `GuardedStoreArmEmit` | the arm only (its merge survives) | guarded |
| `Fp80Union` → `removeUnreachableBlocks(F)` | unreachable-from-entry | guarded via the `Function&` overload |
| `LoopLowering` | — | **not exposed**: rolls in place, erases only instructions (13 fixtures clean) |
| `Specialization` | — | **not exposed**: mints a new function; `MergeBlockIntoPredecessor` runs on clone blocks whose addresses are not taken |
| `ByRefInline` | — | **not exposed**: `Callee->eraseFromParent()` is gated on `use_empty()`, and a `BlockAddress` **is** an operand-use of the Function |

Two of those sites were **not in the ticket and not in the orchestrator's own
first pass** — `Fp80Union`'s `removeUnreachableBlocks` (measured corrupting) and
`AbortParkEmit`. The `Fp80Union` one matters beyond fp80: `foldConstantConesInFunction`
is called by `PredMuxFlatten` after **every** flatten, so it is a second,
independent route from the PredMux surface to a block erase.

`PredMux`'s guard sits at **claim**, not inside `RegionFlattener::run()`, on
purpose: `flattenPredMuxRegions` returns `true` unconditionally after `run()`, so
an early bail inside `run()` would spin the caller's
`while (flattenPredMuxRegions(...))` fixpoint on a host that swallows `DS_Error`.

### Scope, and the control that keeps it honest

The guard is keyed on the **blocks about to be erased**, per site — not on the
function, and not on "in region". `PredMuxFlatten`'s merge **survives** (it is the
branch target) while `flattenRegion`'s merge is **erased**, so "in region" is not
a sound characterisation of the exposed set.

`control_swap_accept_blockaddress_outside_region.ll` is the required accept
control: a `blockaddress` naming a surviving block still lowers, with its address
intact in **both** the forward gate and the adjoint. Without it the guard could
quietly be re-spelled as "decline any function containing an address-taken block",
over-declining every computed `goto` — and since the corpus population of
`blockaddress` **and** `indirectbr` is **ZERO** across all 1,474 modules, no
measurement and no golden would ever have noticed.

---

## 5. WHAT THIS DOES NOT CLOSE

* **The two guards are not one guard.** Guard 1 is about PAIRING (two reads of one
  per-use literal); guard 2 is about ERASURE (one wrong constant read
  consistently). A future refactor that unifies them will get one of the two
  wrong.
* **`freeze` is NOT a laundering channel, and the guard correctly stays silent on
  it** — attacked and found sound rather than assumed. `%f = freeze i32 poison`
  feeding a tainted `add` emits `cq_template_add_i32_hl(%h, i32 %f)` and its
  `_unc(%h_op, %h, i32 %f)` — the operand is an `Instruction`, not a `Constant`,
  so `valueCarriesUndef` is false by design and no slot is counted. That is
  RIGHT, not a hole: `freeze` exists precisely to fix an arbitrary value, so the
  single `%f` def is read twice with the SAME value and the adjoint really is the
  inverse. Verified byte-identical to the `freeze i32 7` control on both plugins.
  Anyone tempted to "strengthen" guard 1 by looking through a `freeze` to its
  operand would be introducing an over-decline, not closing a hole.
* **bd bu96 stays DECLINE-TO-FIX**, on the pairing argument above, and its
  re-opening conditions are unchanged (`definedOpAfterFlagDrop` widened to admit
  `load`/`getelementptr`; stage 3 stops being `-O0`, bd `szpr`; any emitter placing
  a non-tainted `Value*` in a handle slot).
* **A ConstantExpr in a gate slot is accepted by design**, and
  `control_swap_accept_blockaddress_outside_region.ll` now witnesses that live —
  the same uniqued `ptrtoint (ptr blockaddress …)` appears in the forward gate and
  its adjoint, one relocation, pairing intact.
* **`LoopUnrollPrepass`'s U8 check covers only the loop HEADER.** Whether a
  non-header loop block can be erased by `llvm::UnrollLoop`'s own internals was not
  established.
* The 4.5 switch's **PHASE / DATA-MUX / eq-folded** shapes decline for unrelated
  reasons today, so guard 1 is not the thing protecting them; if any of those
  declines is later widened into an accept, the guard becomes load-bearing there
  and no fixture pins it yet.
* Guard 1 **over-declines two unrelated single-use undefs in one module** (it
  counts slots, not pairs-by-identity). Direction is safe, and the over-decline
  direction was measured too rather than waved at — counting the
  `= select i1 …, undef/poison` shape that generates this hit, per translation
  unit:

  | corpus | TUs | with 0 | with 1 | **with ≥2** |
  |---|---|---|---|---|
  | openlibm `-O1` | 251 | 250 | 1 (`ld80-s_nexttoward`) | **0** |
  | e2e stage-1 | 257 | 256 | 1 (`slice_libm_real_nexttoward`) | **0** |
  | `ir-pass/test` | 966 | 962 | 4 (all of them `*_reject_*` fixtures) | **0** |

  So the triggering shape does not occur twice in a single TU anywhere in the
  entire openlibm surface — the over-decline has measured population **zero**, not
  merely "expected zero". (The two `nexttoward` rows independently cross-check each
  other: the e2e slice reproduces the real `ld80/s_nexttoward.c` body, and both
  land on exactly one.) Tightening the count to per-`Constant` identity would need
  its own red-green pair and buys nothing today.

---

## 5a. THE RULE-13 ROUND — FIVE DEFECTS INSIDE THE FIX UNDER REVIEW

Seven adversarial lenses plus a judge. **Two returned `BLOCK`.** Every finding below
was reproduced by the orchestrator on the pinned plugins before being fixed, and
each fix was then re-verified against the lens's own probe.

*This is the FOURTH consecutive round on this file to find a fresh defect inside the
fix under review* (3c6m.14.1 → 3c6m.14.2 → u1rp → this). Three of the five are the
unforgivable direction.

| # | defect | direction | fix |
|---|---|---|---|
| 1 | An `undef` ONE classical instruction above the slot: guard 1 counts literals, so `%c = xor i32 undef, 7` feeding `cq_template_mul_i32_hl(%a, %c)` counted ZERO — and `Specialization::synthUncomputeTwin`'s `CloneFunctionInto` **duplicates** that computation into the twin, so clone and twin each read `undef` independently (trace: `mul_i32_hl(h0, 73903)` vs `mul_i32_hl(h0, 7)`) | **over-accept** | `findUndefOperandInBody` fence at the DUPLICATION site |
| 2 | `getCalledFunction()` is null for a call through a `GlobalAlias`, and `EmitInverse` mints every `_unc` twin via `getOrInsertFunction`, which returns whatever `GlobalValue` bears the name — so an aliased adjoint was invisible and the full xy9n break shipped at `opt` exit 0 | **over-accept** | test the called OPERAND's own name (NOT `stripPointerCasts`, which reopens it) |
| 3 | `declineAddressTakenUnreachableBlocks` PREDICTED `llvm::removeUnreachableBlocks`'s deletion set with a DFS walk. LLVM 19 runs `markAliveBlocks` FIRST, which **mutates** — a store to null, a `noreturn` call, an `llvm.assume(false)` becomes `unreachable` — so the real set is a strict SUPERSET. Three independent triggers still shipped the corruption | **over-accept** | `removeUnreachableBlocksChecked`: watch `WeakTrackingVH`s, call the real utility, decline if a watched block died. **Nothing is modelled** |
| 4 | `hasAddressTaken()` is a REFCOUNT. `CloneFunctionInto` does `VMap[OldBBAddr] = BlockAddress::get(NewFunc, CBB)`, which bumps the CLONE's refcount with ZERO users — so every Phase-6 clone of a callee with an address-taken block declined. **31 of 1460** injected corpus variants flipped from a correct BASE lowering to a loud decline | over-decline | require `BlockAddress::lookup(BB)` to have a non-empty use list |
| 5 | Two INDEPENDENT single slots declined — reproduced from REAL openlibm source, two libm cells in one TU (an ordinary multi-slice), each slot individually the shape the accept fixture certifies | over-decline | count PER FUNCTION |

**#3 is the one to remember.** A guard that *models* a mutating LLVM utility is a
hole waiting to open on the next release, and the model was wrong in the direction
that ships a miscompile. Observing the outcome has no such failure mode.

**#5 also refutes the lens's own suggested fix.** It proposed keying on `Constant`
identity; `undef`/`poison` are UNIQUED PER TYPE, so every `double undef` in a module
is one `Constant *` and identity-keying would have reproduced the same
over-decline. Verify a suggested fix, not just a finding.

### Claims retracted rather than defended

* **"One slot is one materialisation"** — MEASURED FALSE. One static slot inside a
  rolled loop is read once per trip; the trace shows one `cqrt_rz_f64` slot yielding
  SIX dynamic reads with TWO distinct values. The conclusion survives on a stronger
  invariant the round verified instead: **CQ never builds an adjoint by re-executing
  the forward site** (`EmitInverse`'s `CreateCall`/`CreateFNeg`/`CreateNeg`,
  `BreakReversePlay`'s `clone()`), so a pair is always ≥2 STATIC slots.
* **"the only constant the pass mints is `Constant::getNullValue`"** — false: 16
  `ConstantInt::get` + 8 `getTrue`/`getFalse` sites, and `SwitchDataMuxEmit.cpp:194`
  mints a NON-zero XOR-delta straight into a `cqrt_copy_<W>_controlled` slot. The
  inference it supported was redundant anyway — placement-last makes provenance
  irrelevant. (An intermediate correction of this very sentence introduced a *new*
  false number, `ConstantFP::get`, which has ZERO real sites. The round caught that
  too.)
* **"worst MEASURED case: a live `indirectbr` destination erased, so the program
  jumps to address 1"** — asserted by the surface census, **NOT reproducible** by the
  round, which argued structurally that it may be unreachable here: every erase site
  requires the doomed block's predecessors to be in-region or unreachable, and an
  `indirectbr` edge IS a predecessor edge. Now recorded as **UNPROVEN**. The measured
  corruption of ordinary classical pointer data stands on its own and is enough.
* **The `rz` row's harm** — `Rz` is DIAGONAL, so the rail's populations are untouched,
  it IS restored to `|0⟩`, and the following `cqrt_free` is LEGITIMATE (this
  project's own Rule 5, verbatim). The violation is a wrong x-DEPENDENT RELATIVE
  phase — a wrong unitary (Rule 2), not a Rule-6 hidden measurement. Two different
  failure modes, one guard, and the fixture headers now say which is which.
* **"Specialization is NOT exposed" / "the `@slot` store carries the second
  channel"** — both false as written; the first was finding #4, and the second
  described a store that did not exist in the fixture (`@slot` was a dead global). A
  real non-perturbing holder is now there.

### What the round could NOT break

* No over-accept on the two-slot threshold survived, including the prompt's own
  suggested probe (a one-slot `cqrt_alloc_<W>(undef)` seed on a rail that IS freed —
  it reaches, and it is sound: `cqrt_alloc(seed)`/`cqrt_free` brackets mean "restored
  to its birth basis value", ~26k such brackets exist across 2968 lowered modules
  with defined non-zero seeds).
* **The lift is behaviour-neutral, proven mechanically not by reading:** both function
  bodies are character-for-character identical after comment-stripping and brace
  matching; `llvm-nm` shows exactly ONE external definition of each with no `_ZN2cq`
  symbol in `opt` or `libLLVM` able to interpose; all **102** `control_predmux_*`
  fixtures are verdict-, stdout-sha256- and stderr-identical BASE vs SHIP.
* **The site census holds at SEVEN.** 153 candidate hits over `ir-pass/src`
  classified by receiver type; exactly 7 destroy a `BasicBlock` and all 7 are
  guarded. No eighth.
* Guard 1's walk is complete on the instruction-kind and symbol-family axes: all 118
  call-emission sites in the pass are `IRBuilder::CreateCall` (no `invoke`, no
  `callbr`, no `CallInst::Create`), and no emitted gate symbol falls outside the
  three prefixes.
* `freeze poison` is not a laundering channel (§5).

## 5b. THE DELTA ROUND — the fixes were themselves defective

The first round's five fixes were written DURING that round, so no lens had seen
them. A second focused round (3 lenses) reviewed only that delta, and the first
round's JUDGE — adjudicating in parallel — returned **BLOCKED** on 8 must-fixes.
Between them they found **four more defects, two of them in the unforgivable
direction, both inside fixes built to close over-accepts.**

| # | defect | direction |
|---|---|---|
| 1 | **The twin fence was one level too deep.** `ensureTwin` returns as soon as a `<clone>_unc` DEFINITION exists, BEFORE calling `synthUncomputeTwin` — so a fence inside `synthUncomputeTwin` never ran when the twin was pre-supplied, and the outer wrap called a forward clone and an adjoint twin each carrying their own `%c = xor i32 undef, 7`. `opt` exit 0, verify clean, free-pairing 4/4. **The bd xy9n defect shipped past the fence built to stop it.** | **over-accept** |
| 2 | **A deterministic SIGSEGV in the fix.** `removeUnreachableBlocksChecked` held the `!dbg` anchor as a raw `Instruction *` across `removeUnreachableBlocks(F)`. `markAliveBlocks` reaches `changeToUnreachable(I)`, which ERASES `I` — and `Fp80Union` passes the entry block's FIRST instruction, exactly the erased one for the store-to-null and `llvm.assume(false)` triggers. Exit 139, 3/3 runs, on valid input BASE lowered. (The `noreturn` trigger does NOT crash — there the rewrite lands on the call's SUCCESSOR — so any future change must be retested against the other two spellings.) | crash |
| 3 | **`use_empty()` is the wrong observability test.** A `BlockAddress` referenced only from METADATA has no Uses, so the guard skipped it while the erase still rewrote the reference. Not turned into an executable divergence (every realistic runtime carrier IS a real Use), but the guard's stated invariant is "nothing can observe the erase", and metadata observes it. | scope gap |
| 4 | **The twin fence scanned only the clone's own body.** Put the undef-bearing computation in a `noinline` classical helper the clone CALLS and the twin duplicates the CALL: two distinct static sites sharing ONE `undef` slot, read twice dynamically. The body-only scan returned null. Not exhibited at the shipped `-O1` stage 1 (which inlines such a helper back into the caught form), so reported UNSURE — closed anyway, because over-declining is the safe direction. | **over-accept (structural)** |

Fixes: #1 the fence moved to `ensureTwin`'s ENTRY — *put the guard where the
property is decided, not where the mechanism is implemented*, which is the same
lesson bd 7udx's erase-site placement had already taught and this change failed to
apply; #2 a `WeakTrackingVH` re-derived after the call, plus a no-`!dbg`
diagnostic so the no-anchor path can never return "declined" silently; #3
`isUsedByMetadata()` added to both copies of the predicate; #4 the scan made
transitive over directly-called defined callees, bounded by a `Function*` visited
set (sound because `SpecializeReject::scanBody` already proves every reachable
callee pure and acyclic).

### More retracted claims

* **The gep-folding "reason 2"** for `slotCarriesUndef` — *false*. Only the
  TRAILING-index and `i8` spellings fold; `ptrtoint (ptr getelementptr inbounds
  ([4 x i32], ptr @g, i64 undef, i64 1) to i32)` reads back VERBATIM. The
  STRUCTURAL reason (the early return exits only the GlobalValue's own recursion
  level, so the parent's loop reaches the sibling) is the only one that holds — and
  the judge verified that shape is still caught.
* **The `MergeBlockIntoPredecessor` rationale** — the old "clone blocks whose
  addresses are not taken" was wrong for the same reason finding #4 of the first
  round was. It now rests on two true grounds: the clone-block `BlockAddress` is a
  user-less VMap artifact, AND `llvm::MergeBlockIntoPredecessor` independently
  refuses any `hasAddressTaken()` block.
* **"every caller consumes the bool"** — `removeUnreachableBlocksChecked` returns
  `true` for both "changed" and "declined", so no caller *can* distinguish, and
  `Fp80Union` discards it by design. Amended rather than defended.
* **"count SLOTS, not calls" justified by an aliased-operand compare** — no emitted
  symbol in the frozen ABI takes two LITERAL slots (`_hl`/`_lh` one, `_qq` none,
  alloc one, ry/rz one, xorc/addc one), and the arm that restricts to one slot per
  call leaves every fixture green. Softened to what is true.

### The verification that caught a verification

The first arm-kill run reported `got=RED` on 6 of 6 arms — and `witness=RED` on all
6 too, because `lit --filter` matches the full display name (`CQ IR-pass :: foo.ll`)
and the driver anchored with `^`, selecting ZERO tests. Every row was a false RED
from a harness that ran nothing. **The unrelated witness fixture is the only reason
that was caught**, and the driver now asserts the discovered-test count as well.
That is the single strongest argument for the witness-row discipline in this
document.

## 5c. THE GATES, AS NUMBERS

**BASE-vs-SHIP differential — BYTE-NEUTRAL on the entire measured population.**
BASE `1e38ace7…` (rebuilt from a clean worktree at `fb30245`, reproducing the
recorded pre-change sha256 bit-for-bit), SHIP `abcf06b7…`:

| corpus | scanned | verdict moved | lowered-IR moved |
|---|---|---|---|
| `ir-pass/test/*.ll` (pre-change snapshot) | 966 | **0** | **0** |
| e2e stage-1 | 257 | **0** | **0** |
| openlibm `-O1` | 251 | **0** | **0** |

Run twice by two independently written scripts — the orchestrator's and the delta
round's regression lens's — with the same answer. Note the 966 is the PRE-change
fixture snapshot, so a verdict move there would be a genuine regression on an
existing fixture, not one of this change's own new files.

**Arm-kill: 11 arms, 10 OK on the first attempt, 1 fixed.** Every row ran an
unrelated WITNESS fixture (`lowering_basic.ll`, GREEN in all rows), asserted the
mutant `.so` sha256 CHANGED, deleted the object files rather than touching sources,
and asserted the restore reproduced the clean `.so`. The v2 driver's unmutated
worktree build reproduced the repo `.so` bit-for-bit.

| arm | reverts | fixture it must redden | got |
|---|---|---|---|
| D1 | the `GlobalValue`-address skip | `…accept_undef_literal_global_init_pad` | OK |
| D2 | the called-OPERAND callee test | `…reject_undef_literal_paired_alias_unc` | OK |
| D3 | per-function → per-module counting | `…accept_undef_literal_two_functions` | OK |
| D4 | the `BlockAddress` use test | `spec_accept_blockaddress_clone_artifact` | OK |
| D5 | the twin fence entirely | `spec_reject_twin_undef_dup` | OK |
| D6 | observe → predict the deletion set | `…reject_blockaddress_markalive` | OK |
| D7 | the twin fence's PLACEMENT | `spec_reject_twin_undef_dup_pretwin` | OK |
| D8 | the `isUsedByMetadata` clause | `…reject_blockaddress_metadata_only` | OK |
| D9 | transitive → body-only scan | `spec_reject_twin_undef_dup_transitive` | **fixed after a MISMATCH** |
| D10 | the `WeakTrackingVH` anchor | `…reject_blockaddress_markalive_entry` | OK |

**Other gates:** 990 lit fixtures green; `gen_templates.py --check` clean;
`slice_libm_real_nexttoward` driven end to end under SHIP — `free_pairing_check`
STRICT **218/218 verified, 0 violations, 0 unproven**, and its committed golden
**byte-identical**.

## 5d. THREE FIXTURES OF MINE PINNED NOTHING, AND THAT IS THE PATTERN TO CARRY

Not one of these was found by the positive suite; each needed an arm-kill or a lens.

* `lowering_fp80_reject_blockaddress_unreachable.ll` (first body) — GREEN with the
  `Fp80Union` guard call deleted: another site's guard satisfied it. Found by the
  fixture-power lens. Replaced with a probe whose ONLY block erasure is that site's.
* The **D8** arm — aimed at `…blockaddress_diamond_arm.ll`, whose address sits in a
  `store`, i.e. a real Use. Removing the metadata clause leaves it green. Found by
  the orchestrator while reading the arm list.
* The **D9** arm — aimed at `spec_reject_twin_undef_dup.ll`, whose undef sits
  DIRECTLY in the clone body, so a body-only scan still finds it. Found by the
  arm-kill MISMATCH.

**The generalisation, because three instances is a pattern and not bad luck: when an
arm and its fixture share an author, the fixture gets chosen for TOPICAL RESEMBLANCE
rather than for DISCRIMINATION.** Aim an arm from the MUTATION's semantics — "what
must stop being true?" — never from the fixture's name. And a fourth instance of the
same family: the first arm-kill driver reported 6/6 REDs from a `lit --filter` that
selected ZERO tests, caught only by the unrelated witness row.

## 6. METHOD NOTES WORTH CARRYING

* **The decisive measurement was the cheapest one.** Five minutes of hand-written
  probes established "no control flow at all", which alone forced the module-wide
  shape. The 8-agent census that followed refined 3 surfaces into 11 and found two
  erase sites the orchestrator had missed — but it did not change the decision.
  Take the cheap decisive measurement first.
* **A population scan is a design input, not a formality.** The single e2e hit is
  what moved the threshold from one slot to two. A guard shipped without that scan
  would have broken a committed golden.
* **Pin the plugins, and rebuild BASE from a clean worktree.** Every census
  verifier independently discovered that the orchestrator had rebuilt
  `build/ir-pass/libCQPass.so` under them mid-run, and each controlled for it by
  building its own pre-change plugin. A differential against a live build
  directory is not a differential. The BASE rebuild reproducing the recorded
  pre-change `sha256` bit-for-bit is what makes the pin trustworthy.
* **The non-perturbing holder is the right probe form for an erasure defect.**
  Appending a separate function that merely takes a block's address leaves every
  proof, gate and classifier in the lowered function byte-identical, so a decline
  cannot be blamed on the edit. Editing the region body instead produced two
  false NO-REACH results before this technique was adopted.
* **`switch` case values cannot be spelled `poison`** — LLVM's parser rejects it
  ("case value is not a constant integer"), which is why three of the four 4.5
  shapes have no reaching probe on that channel.
* Carried forward from the u1rp round and used again here: a mutation that does
  not change the file is not a control; delete the object file rather than
  `touch`ing the source, and assert the `.so` hash changed; an arm-kill row needs
  an unrelated **witness** fixture; `opt` emits the first `DS_Error` and exits, so
  one decline assertion per fixture; FileCheck parses directives out of prose.
