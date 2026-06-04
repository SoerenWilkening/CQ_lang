# Phase 5 IMPLEMENTATION — IR pass: per-op uncomputation

The build-out plan the [PRD](./PRD.md) promised ("the implementation plan …
lands next session as `IMPLEMENTATION.md` alongside this file"). It is the
binding module layout, test-first sequence, and commit shape for
productionizing the prototype's `cq-uncompute` slice — emitting the adjoint of
each tainted **data** handle's gate chain at its SSA last-use point, then
`cqrt_free`. The PRD's decisions 2.1–2.10 are the contract; this document maps
each to exactly one owning module, with real `file:line` anchors verified
against the tree on 2026-06-04.

## Companion documents

- [`PRD.md`](./PRD.md) — the binding spec (decisions §2.1–2.10, deliverables §3,
  done-criteria §4, out-of-scope §5, risks §6). Every module below cites the
  PRD decision it owns.
- [`ROADMAP.md`](../../../ROADMAP.md) §Phase 5 — phase scope, sequence, and the
  loop-extension forward reference (PRD 2.9).
- [`docs/backend.md`](../../backend.md) §9 (last-use computation, adjoint
  emission, escape detection) / §10 (the `emit_inverse` rule, forward +
  controlled-forward commitment). Deltas vs the PRD are reconciled in §8.
- [`docs/prd/phase-04-controlled-form/PRD.md`](../phase-04-controlled-form/PRD.md)
  §2.9 — the Phase 4 / Phase 5 seam (Phase 4 brackets its own control scratch).
- The Phase 5 prototype — `archive/prototype/cq_pass.cpp` (the `cq-uncompute`
  slice: `PostDominatorTree`-driven last-use + `ReturnInst` escape, bare
  `cqrt_free` with **no** adjoint). This plan supersedes the placeholder.

---

## Status

| Item | State |
|---|---|
| `IMPLEMENTATION.md` (this document) | ✍️ **DRAFT** — 2026-06-04 |
| Code | ⏳ **not started** |
| Phase-4-side prerequisite (Step 0, `TaintSet::FlagTeardown` hook) | ⏳ not started — **mandatory**, see §2.4 / §6 / §7 |

Phase 4 is complete; the seam this phase builds on is in place. Phase 5 is the
first uncomputation work that owns **data** handles.

---

## §1 Module map

Seven entries: **five new** `*.cpp`/`*.h` modules and **two edits**. Every PRD
decision 2.1–2.10 is owned by exactly one module (coverage checklist below).
Every new `.cpp` is under the **400-LOC hard target** (the team treats <400 as a
hard cap; only `ControlDetection.cpp` 1514, `ControlledLowering.cpp` 771,
`MergeDissolution.cpp` 750 legacy files exceed it, and none are touched except
the six-line Step-0 hook in `emitUncompute`). The two densest new modules carry
**named split contingencies** (`EmitInverse`, `FreePoint`) so the cap stays
defensible up front.

| File (`ir-pass/`) | Responsibility | Est LOC | Owns PRD § | Public API (namespace `cq`) |
|---|---|---|---|---|
| `src/EmitInverse.cpp` + `include/EmitInverse.h` | **The standalone reusable adjoint spine.** Given a forward `CallInst` (or ordered list), emit the per-call inverse at a caller-supplied `IRBuilder` insertion point and **return the produced SSA value** for the next reversed link. Dispatch by callee-name suffix (§3). Owns NEITHER selection NOR placement → Phase 7 reuses it on its own bracketed sequence with zero Phase-5 coupling. **Split contingency:** factor the pure name→(stem,width,shape,controlled) decode (parallels `suffixFromName`, `RotationLowering.cpp:36-44`) into a small `InverseDecode.{cpp,h}` helper, leaving `EmitInverse` to own only dispatch+emit; target ~250 with the decoder carved out. | ~250 (decoder carved out) | **2.3** | `Value *emitInverseCall(IRBuilder<> &B, CallInst *Forward, WidthDispatch &wd, ControlledSymbols &csyms, Value *Flag = nullptr);` `void emitInverseChain(IRBuilder<> &B, ArrayRef<CallInst *> ForwardChain, WidthDispatch &wd, ControlledSymbols &csyms, Value *Flag = nullptr);` |
| `src/WidthDispatch.cpp` + `include/WidthDispatch.h` — **EDIT** | Close the two minting seams in the file that already centralizes symbol resolution: (1) add `bool inverse = false` to `dataTemplateFn`/`compareTemplateFn`/`castTemplateFn`, threaded into the already-inverse-aware `dataName`/`compareName`/`castName`; (2) add a width-agnostic `freeFn()` minting `void cqrt_free(i32)`. | ~60 Δ | (plumbing for 2.3 / 2.10; owns no decision) | `dataTemplateFn(..., bool inverse=false)`, `compareTemplateFn(..., bool inverse=false)`, `castTemplateFn(..., bool inverse=false)`; **new** `FunctionCallee freeFn() const;` |
| `src/ChainWalk.cpp` + `include/ChainWalk.h` | **Whole-register forward-chain reconstruction.** No recorded lineage exists (see §2.3), so reconstruct from def-use operand-0 threading. Generalizes `recoverPrepChain` to also match `cq_template_*` data ops and **chase the RAUW reassignment lineage** (`q=q+1; q=q*2` → distinct i32 results). Program-ordered; pure analysis, emits no IR. | ~210 | **2.1** | `struct ForwardChain { SmallVector<CallInst*,8> Calls; Value *Terminal; Value *AllocHandle; };` `ForwardChain recoverForwardChain(Value *Terminal, const TaintSet &taint, DominatorTree &DT);` `bool isTerminalHandle(Value *Handle, const TaintSet &taint);` |
| `src/FreePoint.cpp` + `include/FreePoint.h` | **SSA last-use point + escape classification + diagnostics.** `PostDominatorTree` last-use (2.4); measure-sink exclusion (2.5); escape skip-set + loud diagnostics (2.6); loop-backedge guard (2.9). **Owns the exact diagnostic `Msg` strings** so fixture `CHECK` lines and code cannot drift. **Split contingency:** if it exceeds ~340, peel escape/diagnostic classification (the `FreePointKind::Escaped` path + the three `DiagnosticInfoUnsupported` emitters + their `Msg` strings) into a sibling `EscapeClassify.{cpp,h}`, leaving `FreePoint` owning only the post-dom + measure-exclusion insertion-point computation (cleanly separates 2.6/2.9-diagnostics from 2.4-placement). | ~290 | **2.4, 2.5, 2.6, 2.9** | `enum class FreePointKind { Insert, Measured, Escaped };` `struct FreePoint { FreePointKind Kind; Instruction *At; };` `FreePoint computeFreePoint(Value *Terminal, Function &F, PostDominatorTree &PDT, const TaintSet &taint);` |
| `src/InShadowAdjoint.cpp` + `include/InShadowAdjoint.h` | **Flag-lifetime keep-alive** — the riskiest seam, isolated. Tests in-shadow via `taint.ControlFlag.count(Terminal)`; supplies the controlling flag and the **keep-alive anchor** (the live flag-teardown `CallInst`, read from the new `TaintSet::FlagTeardown` map). | ~150 | **2.7** | `struct InShadowPlan { bool InShadow; Value *Flag; Instruction *KeepAliveAnchor; };` `InShadowPlan classifyInShadow(Value *Terminal, const TaintSet &taint);` |
| `src/Uncomputation.cpp` + `include/Uncomputation.h` | **Thin per-function orchestrator.** Composes the four units + EmitInverse. Owns ONLY the target-set partition (2.2), terminal selection, and emit ordering (2.10). Builds its own `ControlledSymbols csyms(M, wd)`. | ~200 | **2.2, 2.8, 2.10** | `void uncompute(Module &M, WidthDispatch &wd, TaintSet &taint);` |
| `src/CQLoweringPass.cpp` + `CMakeLists.txt` — **EDIT** | Wire `uncompute` as the **last** mutation (2.8) in **both** entry points; add the new sources to the `add_library` list in case-insensitive alphabetical position. | ~12 Δ | **2.8** (slot) | no new public API |

### Coverage checklist (no orphaned PRD decision)

| PRD § | Module |
|---|---|
| 2.1 whole-chain reversal | `ChainWalk` |
| 2.2 data/control partition | `Uncomputation` (target-set subtraction) |
| 2.3 `emit_inverse` | `EmitInverse` (minting support via the `WidthDispatch` edit) |
| 2.4 last-use via PostDominatorTree | `FreePoint` |
| 2.5 measurement terminator | `FreePoint` (exclude `cqrt_measure_` users + `Measured` kind) |
| 2.6 escape + loud diagnostic | `FreePoint` (`Escaped` kind + `DiagnosticInfoUnsupported`) |
| 2.7 in-shadow controlled adjoint + keep-alive | `InShadowAdjoint` (+ Step-0 `FlagTeardown` hook) |
| 2.8 Phase 5 runs last | `Uncomputation` entry + `CQLoweringPass` slot |
| 2.9 acyclic / loop-backedge guard | `FreePoint` |
| 2.10 `cqrt_free` after adjoint | `Uncomputation` |

The `WidthDispatch` edit carries **no** PRD-decision tag deliberately: it is a
pure plumbing seam (the single verified resolver gap + the `cqrt_free` minter);
the decisions it *enables* (2.3 minting, 2.10 free) are owned by `EmitInverse`
and `Uncomputation`. Kept in `WidthDispatch` to preserve the one-place lazy-mint
convention.

### Dependency / ordering note

```
WidthDispatch(EDIT) ──► EmitInverse ──┐
                                      ├──► Uncomputation ──► CQLoweringPass(EDIT)
ChainWalk ────────────────────────────┤
FreePoint ────────────────────────────┤
InShadowAdjoint (needs Step-0 hook) ──┘
```

`EmitInverse` cannot compile until the `WidthDispatch` inverse param + `freeFn()`
land — so the edit is the **smallest first seam** (Step 1). `InShadowAdjoint`
cannot be correct until the Step-0 Phase-4 `FlagTeardown` hook exists (§2.4) — so
that is **Step 0**. `Uncomputation` is the last code module (it depends on all
four units).

### Build wiring (`ir-pass/CMakeLists.txt:43-64`)

The `add_library(CQPass MODULE …)` list (the `add_library` opens at line 43; the
last source `src/WidthDispatch.cpp` is at line 64) is **case-insensitive /
human** alphabetical — **not** strict ASCII: e.g. `CQLoweringPass.cpp` sits at
line 53, after all `Control*.cpp`, where strict ASCII (uppercase `Q` < lowercase
`o`) would place it much earlier. The proposed insertion points are consistent
with that case-insensitive order. Insert, in order:

```cmake
  src/CFGLinearization.cpp
  src/ChainWalk.cpp          # NEW
  src/CompareLowering.cpp
  ...
  src/CQLoweringPass.cpp
  src/EmitInverse.cpp        # NEW
  src/FlagConjunction.cpp
  src/FreePoint.cpp          # NEW
  ...
  src/InShadowAdjoint.cpp    # NEW (after FreePoint, before MeasureLowering)
  src/InverseDecode.cpp      # NEW (if EmitInverse split lands; after InShadowAdjoint)
  src/MeasureLowering.cpp
  ...
  src/TemplateName.cpp
  src/Uncomputation.cpp      # NEW (after TemplateName, before WidthDispatch)
  src/WidthDispatch.cpp
```

`Plugin.cpp` needs **zero change** — it registers only the pass *name* string
`"cq-lowering"` (`ir-pass/src/Plugin.cpp:20-32`), not internal modules. Do **not**
add a `cq-uncompute` pipeline name (that was the prototype's separate pass;
production runs Phase 5 inside `cq-lowering` per 2.8). The LIT harness GLOBs
`*.ll` (`ir-pass/test/CMakeLists.txt:80`), so new fixtures need no per-file
registration.

### Pass-pipeline insertion (`ir-pass/src/CQLoweringPass.cpp`)

Phase 5 slots in as the **last mutation**, after `lowerMeasures` and before
`eraseDeadDecls`, in **both** entry points (the dual-entry-point gotcha — miss
one and unit-level callers diverge):

- `run()` — between line 79 (`lowerMeasures(M, wd, taint);`) and line 80
  (`eraseDeadDecls(M, wd);`): insert `uncompute(M, wd, taint);`.
- `runOnFunction()` — between line 124 (`lowerMeasures(M, wd, taint);`) and line
  125 (`eraseDeadDecls(M, wd);`): insert `uncompute(M, wd, taint);`.

Both paths honor the no-quantum early-out, so a classical module stays untouched.

Add `#include "Uncomputation.h"` to the include block.

**PostDominatorTree acquisition — direct construction, not the AM proxy.**
`Uncomputation::uncompute` constructs `PostDominatorTree PDT(F);` (and
`DominatorTree DT(F);`) directly per non-declaration function, matching the
prevailing in-tree convention of building the tree in place from a block's
parent function: `DominatorTree DT(*region.MergeBB->getParent())`
(`ControlledLowering.cpp:497`), `DominatorTree DT(*region.MergeBB->getParent())`
(`ControlDetection.cpp:781`), `DominatorTree DT(*SwBB->getParent())`
(`ControlDetection.cpp:1031`). This needs `#include
"llvm/Analysis/PostDominators.h"` (verified absent from `ir-pass/` today; header
present at `/usr/local/Cellar/llvm@19/19.1.7/include/llvm/Analysis/PostDominators.h`).

Rationale: Phase 5 is the **only** `PostDominatorTree` consumer and runs once, so
analysis-manager caching buys nothing. The direct route leaves the `run`
signature + no-quantum early-out byte-identical and requires **no** analysis
registration. (The prototype's AM-proxy path at `cq_pass.cpp:259-272` is the
rejected alternative; see §8.)

---

## §2 Data flow

### 2.1 How `TaintSet` + the Phase-4 control-flag map are obtained

There is **no new threading**. `TaintSet taint` is a single local in
`CQLoweringPass::run`, taken by reference through every stage. By the time
`uncompute(M, wd, taint)` runs (last slot), `taint` is in its **final
post-lowering state**, including:

- `taint.Tainted` (`TaintPropagation.h:51`) — the candidate universe of data +
  control handles.
- `taint.BirthOrder` (`TaintPropagation.h:60`) — a flat `Value*→unsigned` mint
  counter (see 2.3 below).
- `taint.HandleWidth` (`TaintPropagation.h:68`) — logical ABI width per handle.
- `taint.MeasureCalls` (`TaintPropagation.h:45`) — but Phase 5 recognizes a
  measured handle by the **lowered** call name `cqrt_measure_` (prefix match),
  since `lowerMeasures` has already rewritten `cq_measure_<sfx>` → `cqrt_measure_<W>`
  by Phase 5's slot.
- `taint.ControlFlag` (`TaintPropagation.h:76`) — the PRD's "control-flag map," a
  `DenseMap<Value*, Value*>` mapping **in-shadow data handle → i32 control
  flag**, populated by Phase 4 at exactly three sites (verified):
  `ControlledSubstitution.cpp:63`, `MergeDissolution.cpp:440`, `:555`.

`Uncomputation` builds its own `ControlledSymbols csyms(M, wd)` — a cheap
holds-references ctor (`ControlledSymbols.h:41`) — so the driver call stays
`uncompute(M, wd, taint)`. We do **not** pass `ControlPlan`: its `ControlRegion`
CFG-block pointers (`Pred`/`Arm`/`MergeBB`, `ControlPlan.h:120-122`) are stale by
Phase 5's slot (detection runs as pure analysis pre-RAUW; the IR is then
RAUW'd-to-handle, merge-dissolved, and linearized — `R.MergeBB` is **erased** at
`CFGLinearization.cpp:62` (`Merge->eraseFromParent();`), reached via the
`linearizeRegion` call at `ControlledLowering.cpp:764`). Phase 5 relies on
`taint.ControlFlag` (survives RAUW) + the recorded `FlagTeardown` (§2.4), not
plan block pointers.

### 2.2 The target-set subtraction (PRD 2.2) — and the direction trap

```
targets = taint.Tainted
          MINUS  image(taint.ControlFlag)   // the flag VALUES (control scratch)
          MINUS  measured                   // a user is a cqrt_measure_ call (2.5)
          MINUS  escaped                     // return / main / cq_invert_* (2.6)
          KEEP   only terminal handles       // isTerminalHandle (ChainWalk)
```

**SUBTRACTION-DIRECTION TRAP (verified, load-bearing).** `taint.ControlFlag`
maps **data-handle → flag**. Subtract its **image** (the flag values), **not**
its **keys**. The keys are precisely the in-shadow **data** handles Phase 5
**owns** and uncomputes in controlled form (2.7); subtracting them would silently
skip every in-shadow case — the exact opposite of intent, and a direct R1
regression. The flag values are also reachable as the arg-0 of every
`*_controlled` / `*_controlled_inv` call and the result of `lowerCompareToFlag`.

`isTerminalHandle` (ChainWalk): a handle is terminal when no **other tainted**
instruction consumes it as a forward operand — its only remaining users are
non-tainted (measure is a sink, return is escape, classical reads). This is what
collapses the reassigned-variable chain (`q=q+1; q=q*2`) to a single terminal so
Phase 5 reverses the whole chain **once** rather than per-SSA (R-whole-chain).

### 2.3 The whole-chain lineage walk (PRD 2.1) — BirthOrder is **not** lineage

**Stated plainly: the PRD 2.1/§6 phrase "walk the handle lineage (`BirthOrder`)
back from the terminal handle" has no backing data structure.** `BirthOrder`
(`TaintPropagation.h:60`) is a flat monotonic `Value*→unsigned` mint counter
used **only** for commutative Q+Q operand canonicalization
(`ArithLowering.cpp:83-90`); it carries no parent pointer and is global, not
per-chain. Written at `RotationLowering.cpp:127`, `ArithLowering.cpp:31`,
`MergeDissolution.cpp:210/381`, etc.

**Decision:** `ChainWalk::recoverForwardChain` reconstructs the chain from
**def-use operand-0 threading** — it does **not** walk `BirthOrder`, and we do
**not** add a lineage map to `TaintSet`. Every lowering step does RAUW-to-handle,
so the forward chain survives as operand-0 threading through `cqrt_*` /
`cq_template_*` calls:

- each **unconditional** gate threads the handle as **operand 0**:
  `cqrt_ry_<W>(h, θ)`, `cqrt_rz_<W>(h, θ)`, `cq_template_<op>_<W>[_hl|_lh](h, …)`;
- a **reassigned** variable produces a **new** result handle per op — the
  emit+RAUW+promote body is `CreateCall` → `setDebugLoc` → `replaceAllUsesWith` →
  `promote` (`ArithLowering.cpp:118-124`, `rewriteBinary`; the rewriter **dispatch**
  loop that calls it is `OpcodeLowering.cpp:94-111`), so the chain is: terminal
  template-result → its operand-0 producer handle → that handle's operand-0
  producer → … → `cqrt_alloc_<W>` mint (`RotationLowering.cpp:122`);
- a **controlled** gate threads the **flag** as arg 0 and the handle as arg 1 —
  the flag-arg-0 ABI is realized by the controlled-data-template `FunctionType`
  `{Flag, Handle, Handle}` (`ControlledSymbols.cpp:35`) and the controlled-rotation
  `FunctionType` `{I32, I32, double}` (`ControlledSymbols.cpp:70-71`);
  `recoverForwardChain` must disambiguate by arg-0 identity, exactly as
  `recoverPrepChain` does (`ControlledLowering.cpp:291`:
  `arg_size()==2 && getArgOperand(0)==Handle`).

This **generalizes** the existing, tested `recoverPrepChain`
(`ControlledLowering.cpp:276-309`, verified rotation-only + single-handle) to
also match `cq_template_*` ops and to chase the RAUW reassignment lineage.
Program order: same block ⇒ `comesBefore` (`:299`), else `DT.dominates` (`:300`),
with **`BirthOrder` as a tie-breaker only** for clang-version-stable,
FileCheck-pinned output. A literal `BirthOrder` walk would mis-order — this is
the corrected reading of PRD 2.1/§6.

### 2.4 The Phase-4-side prerequisite — `TaintSet::FlagTeardown` (mandatory, not optional)

PRD 2.7 keep-alive requires anchoring the controlled data-adjoint **immediately
before** Phase 4's flag teardown. **Verified: that teardown is not discoverable
by SSA dataflow.** `emitUncompute` (`ControlledLowering.cpp:72-112`) emits, for a
plain compare, `lowerCompareToFlag(Cmp, …, inverse=true)` =
`cq_template_icmp_<pred>_<W>[_hl]_inv` over the **condition's data handles**
(`ControlledLowering.cpp:110-111`; operands confirmed in
`CompareLowering.cpp:167-171`) — **not** the flag. So `users(flag)` does not reach
the teardown. And `R.MergeBB` (the anchor source — `UncomputeAt = R.MergeBB ?
R.MergeBB->getFirstNonPHI() : nullptr` at `ControlledLowering.cpp:727`) is
**erased** post-linearization (`CFGLinearization.cpp:62`). A name-scan for the
trailing unconsumed `_inv` is fragile.

**Resolution (Step 0, mandatory):** add a recording hook in Phase 4:

```cpp
// TaintPropagation.h, alongside ControlFlag (line 76):
llvm::DenseMap<llvm::Value * /*flag*/, llvm::CallInst * /*firstTeardown*/> FlagTeardown;
```

populated by a ~6-line change in `emitUncompute` (`ControlledLowering.cpp:72-112`,
keyed by `region.Flag`, recording the **first** instruction it emits at `At`).
`InShadowAdjoint::classifyInShadow` reads `taint.FlagTeardown[ taint.ControlFlag[Terminal] ]`
to get a deterministic `Builder.SetInsertPoint(teardownCall)`. This is **front-loaded
as commit step 0** with a Phase-4 regression fixture proving the teardown still
emits byte-unchanged.

---

## §3 `emit_inverse` contract (PRD 2.3)

`EmitInverse` is **the** standalone reusable spine. It owns **neither selection
nor placement** — the caller supplies an `IRBuilder<>` already positioned at the
insertion point, a forward `CallInst` (or ordered list), and an optional `Flag`.
It dispatches by **callee-name suffix** and **returns the produced SSA value** so
the next reversed link can consume it.

### Per-call inversion recipe

| Forward call shape | Inverse emission | Symbol API | Notes |
|---|---|---|---|
| **Uncontrolled rotation** `cqrt_ry_<W>(h, θ)` / `cqrt_rz_<W>(h, θ)` (arg_size 2, arg0 = handle) | re-emit the **SAME forward symbol** with `B.CreateFNeg(θ)` | `WidthDispatch::ryRtFn(W)` / `rzRtFn(W)` (`WidthDispatch.h:75-76`) | **No** `cqrt_ry/rz_<W>_inv` symbol exists in the runtime; negate the angle on the forward. Void; mints no handle. |
| **Controlled rotation** `cqrt_rz_<W>_controlled(flag, h, θ)` (arg_size 3, arg0 = flag) | `_controlled_inv` twin with the **SAME (un-negated) angle**, flag stays arg 0 | `ControlledSymbols::controlledRotationFn(W, /*inverse=*/true)` (`ControlledSymbols.cpp:57-72`); for an in-shadow Ry disentangle, `controlledRyInvFn(W)` (`ControlledSymbols.cpp:74-89`) | The inversion lives in the `_controlled_inv` symbol, **not** the angle — mirrors `emitChainInv` (`ControlledLowering.cpp:534-536`). **Angle-convention split** vs the uncontrolled case is load-bearing. |
| **Uncontrolled template** `cq_template_<op>_<W>[_hl\|_lh](…)` | the declared `_inv` twin | `WidthDispatch::dataTemplateFn(stem, W, shape, /*inverse=*/true)` (NEW param) | `FunctionType` byte-identical to the forward; only the symbol flips. **Returns a FRESH handle** — thread the returned SSA value to the next link; **not** in-place. |
| **Controlled template** `cq_template_<op>_<W>[…]_controlled(flag, …)` | `_controlled_inv` twin, flag arg 0 | `ControlledSymbols::controlledDataTemplateFn(stem, W, shape, /*inverse=*/true)` (FunctionType `{Flag, Handle, Handle}`, `ControlledSymbols.cpp:35`, already inverse-aware) | Also returns a fresh handle. |
| **Self-adjoint involution** `cqrt_x` / `cqrt_cswap` | emit **as-is** (no `_inv` lookup) | `ControlledSymbols::xFn()` (`ControlledSymbols.cpp:100-108`) / `cswapFn()` (`:110-118`) | `cqrt_x` and `cqrt_cswap` are involutions with **no** `_inv` twin (`ControlledSymbols.cpp:102-103`, `:113`). |

**Toffoli / flag-conjunction is out of Phase-5 scope.** `cqrt_toffoli` does have
an `_inv` twin (`cqrt_toffoli_inv`, `ControlledSymbols::toffoliFn(true)`,
`ControlledSymbols.cpp:96`; runtime `cq_runtime.h:196`) — CCX is mathematically
self-adjoint but every existing uncompute site spells `cqrt_toffoli_inv`
(`ControlledLowering.cpp:20,68`; `ControlFlag.cpp:84`), not a bare re-emit. More
fundamentally, `cqrt_toffoli` (and likewise `cqrt_cnot`) is Phase-4
**flag-conjunction control scratch**, which PRD §2.2/§5 assigns to Phase 4, **not**
Phase 5. They are therefore **excluded** from the Phase-5 emission table; touch
them only if a *data* fixture proves a need (none expected).

ABI width recovery for the reverse walk: parse the **forward callee name**
(`cqrt_<stem>_<W>` / `cq_template_<stem>_<W>…`, the `suffixFromName` pattern at
`RotationLowering.cpp:36-44`) or read `taint.HandleWidth` — **never** the
i32-laundered SSA type (it has lost the logical width; `TaintPropagation.h:63-68`).

### Naming layer — already inverse-aware

`TemplateName::dataName/compareName/castName` each already take `bool controlled,
bool inverse` (verified `TemplateName.h:62-79`) and append `[_controlled][_inv]`
via `ctrlInvSuffix` (`TemplateName.cpp:35-39`). The **only** gap is the resolver
layer: `WidthDispatch::dataTemplateFn` hardcodes `dataName(stem, abiWidth, shape)`
with no inverse arg (`WidthDispatch.cpp:175`, `:208`, `:229`). The edit threads
`inverse` through (the `FunctionType` switch is unchanged — copy the forward
body). On the controlled side `ControlledSymbols` already mints inverse forms, so
no controlled-template minting is new.

### Standalone API + Phase 7 reuse seam

`emitInverseCall(B, Forward, wd, csyms, Flag=nullptr) -> Value*` is the
single-call form Phase 7 (manual `cq_invert_*` inversion, beads
`test_C_libtooling-42t`) reuses on its **own** bracketed sequence with zero
Phase-5 coupling. `emitInverseChain(B, ForwardChain, wd, csyms, Flag=nullptr)`
walks the chain in **reverse** (`Chain[N-1] … Chain[0]`), calling `emitInverseCall`
per link and threading each fresh template result into the next call's operand.
There is **no** existing generic "clone a forward `CallInst` → swap callee"
helper (the closest precedent, `emitChainInv` at `ControlledLowering.cpp:526-537`,
rebuilds from a recovered `PrepStep` chain); Phase 5 writes the clone-args +
swap-callee logic, mirroring the forward emission idiom in
`ArithLowering.cpp:118-124` (resolve callee → `CreateCall` → `setDebugLoc`).

**No new runtime symbols** (PRD §3): every target above is declared with zero
gaps (`_inv` template surface 586/586, `_controlled_inv` 196/196, `cqrt_free`
present). The opcode-table SHA is
**`addba88d85db7363479b7fe366724116a7b172f98e95d7e359221006bf81b7eb`**
(verified: matches both `shasum -a256 tools/opcode_table.yaml` and the banner at
`runtime/cq_templates.h:1`); the `cqrt_*` runtime gate surface (60 symbols, all
declared==defined) is hand-written and governed by unit/compile checks, not the
SHA. Step 8 re-runs `python3 tools/gen_templates.py --check --output-dir runtime`
(returncode 0) as the no-drift evidence.

---

## §4 Per-module implementation steps

Each module is built test-first: write the fixture, see it red, implement, see it
green. `file:line` anchors are verified against the tree.

**Live-from-commit-1 regression rule.** `uncompute()` is wired into **both**
entry points (`CQLoweringPass.cpp:79/124`) from commit 1 on, so it is live for
every existing fixture and e2e golden. Because escape/measure/flag-image filters
do not land in full until Steps 3/5, commit 1's `Uncomputation` is written
**conservatively** — it wires the pass but **emits nothing** until `ChainWalk` +
`FreePoint` land the selection logic (the minimal slice's terminal loop is
guarded so no adjoint/`cqrt_free` is emitted for unfiltered terminals). Every
commit from 1 on therefore re-runs the **full pre-Phase-5 LIT suite + e2e
goldens** as an acceptance gate (not just the new fixture), proving the live pass
keeps the existing suite green.

### 4.0 Step 0 — Phase-4 `FlagTeardown` hook (PRE-WORK, unblocks 2.7)

1. **Red:** write `ir-pass/test/phase4_flag_teardown_unchanged.ll` — reuse the
   `lowering_control_gate_br_i32.ll` body; `CHECK` the `cq_template_icmp_*_inv`
   teardown still emits byte-unchanged (a Phase-4 regression guard).
2. Add `DenseMap<Value*, CallInst*> FlagTeardown;` to `TaintSet`
   (`TaintPropagation.h:76`, alongside `ControlFlag`).
3. Populate it in `emitUncompute` (`ControlledLowering.cpp:72-112`): record the
   **first** instruction emitted at `At`, keyed by `region.Flag`. ~6 lines.
4. **Green:** the regression fixture passes unchanged; the new field is unread
   until Step 4.
- *Budget:* edit only; touches the legacy `ControlledLowering.cpp` minimally.

### 4.1 Step 1 — `WidthDispatch` seam + `EmitInverse` spine (zero selection logic)

1. **Red:** write `ir-pass/test/lowering_uncompute_lastuse_midfunc.ll` (PRD §4
   bullet 1, mid-function **non-`main`** last use). **Pin the body to a
   rotation-only, single-handle terminal** (`cq_theta → measure-free terminal`,
   **no arithmetic**) so commit 1's rotation-negate-only `EmitInverse` fully
   covers it; all template-`_inv` assertions are deferred to commit 2. Two RUN
   lines (per `lowering_basic.ll:4-5`): `CHECK` the reversed adjoint
   (`cqrt_ry/rz_<W>(…)` negated angle), then `CHECK` the `cqrt_free` call.
2. **Implement WidthDispatch first** (`EmitInverse` can't compile without it):
   - add `bool inverse=false` to `dataTemplateFn`/`compareTemplateFn`/`castTemplateFn`
     (`WidthDispatch.cpp:167-231`), threading into `dataName`/`compareName`/`castName`;
   - add `FunctionCallee freeFn() const;` — idempotent
     `M.getOrInsertFunction("cqrt_free", FunctionType::get(voidTy, {i32Ty()}, false))`.
3. **Implement `EmitInverse`** — `emitInverseCall` for the rotation-negate case
   first (`CreateFNeg` on the forward symbol), then the self-adjoint as-is case.
4. **Implement a minimal `Uncomputation`** single-op slice + a basic single-block
   `FreePoint`, and **wire `CQLoweringPass` + `CMakeLists` now** so the build
   links end-to-end. The slice is conservative (emits only for the rotation-only
   terminal the fixture pins; no filters yet ⇒ no spurious frees elsewhere).
5. **Green:** the mid-function fixture passes; `opt -verify` clean; **the full
   pre-Phase-5 LIT suite + e2e goldens stay green** (live-pass regression).
- *Budget:* `EmitInverse` ~250 (decoder carved into `InverseDecode` if needed),
  `WidthDispatch` Δ~60.

### 4.2 Step 2 — `ChainWalk` (whole-chain risk)

1. **Red:** write `ir-pass/test/lowering_uncompute_chain_reassign.ll` (PRD §4
   bullet 2, `q=cq_theta; q=q+1; q=q*2`) with **sequential** `CHECK` lines pinning
   `cq_template_mul_*_inv` **before** `cq_template_add_*_inv` **before**
   `cqrt_ry_<W>(…)` negated-angle, then `cqrt_free`.
2. **Implement** `recoverForwardChain` + `isTerminalHandle`, generalizing
   `recoverPrepChain` (`ControlledLowering.cpp:276-309`) to `cq_template_*` ops and
   the RAUW reassignment lineage; `BirthOrder` tie-break only.
3. **Extend `EmitInverse`** to the template `_inv` twin case (the
   fresh-returned-handle threading is logically part of the EmitInverse spine but
   first exercised here) — **thread the fresh returned handle** to the next link.
4. **Green:** the reassign fixture passes in order; full pre-Phase-5 suite green.
- *Budget:* `ChainWalk` ~210.

### 4.3 Step 3 — `FreePoint` (post-dom vs φ, measure, escapes, diagnostics)

1. **Red (3a):** `lowering_uncompute_branch_botharms.ll` (PRD §4 bullet 3,
   both-arm use → **single** uncompute at the φ-merge; `opt -verify` guards the φ;
   2.4). The prototype `input_phase5_branch.ll` trajectory.
2. **Red (3b):** `lowering_uncompute_hh_intermediate.ll` (bullet 4): the `q1*q2`
   temp reverted, but `CHECK-NOT` adjoint/free on the `cq_measure`'d terminal (2.5).
3. **Red (3c):** three positive **no-emit** escapes —
   `lowering_uncompute_escape_return.ll`, `_escape_main.ll`, `_escape_invert.ll`
   — each `CHECK-NOT: cqrt_free` (2.6).
4. **Red (3d):** three **negative** loud-diagnostic fixtures, single RUN line
   `RUN: not %cq-opt … 2>&1 | %filecheck %s` + `CHECK: error{{.*}}<exact Msg>`:
   `lowering_uncompute_escape_unrecognized.ll`, `_postmeasure_use.ll`,
   `_loop_backedge.ll` (2.6 / 2.5 / 2.9).
5. **Implement `computeFreePoint`** — productionize the prototype
   (`cq_pass.cpp:305-329`): `users()` → user-block set →
   `PDT.findNearestCommonDominator` → latest-in-common-block `->getNextNode()` else
   `&*Common->getFirstInsertionPt()` (after φ-nodes). **Deltas (fixture-pinned):**
   - (2.5) **exclude** `cqrt_measure_` users (`starts_with`, the `isMeasureSink`
     test at `TaintPropagation.cpp:80`) from the user set and return
     `FreePointKind::Measured`; a gate **after** measure → loud reject.
   - (2.6) `ReturnInst` / `main` / `cq_invert_*` → `FreePointKind::Escaped`
     (skip, no diag); **any other** unrecognized user OR a null common
     post-dominator → **loud** `DiagnosticInfoUnsupported` (never the prototype's
     silent `nullptr`).
   - (2.9) a backedge-crossing live range → loud diag.
   - Construct `PostDominatorTree PDT(F)` directly; **own** the exact `Msg` strings.
6. **Green:** all eight fixtures pass (negatives via real LIT — see §5 note); full
   pre-Phase-5 suite green.
- *Budget:* `FreePoint` ~290 (split to `EscapeClassify` if >340).

### 4.4 Step 4 — `InShadowAdjoint` (keep-alive; depends on Step 0)

1. **Red:** `lowering_uncompute_inshadow_controlled.ll` (PRD §4 bullet 5) with
   **sequential** `CHECK` pinning the `_controlled_inv` data-adjoint **before** the
   flag teardown `cq_template_icmp_*_inv` (LIFO bracket, 2.7); `opt -verify` clean.
   Doubles as the R2 stale-sequence guard (`_controlled_inv`, not plain `_inv`).
2. **Implement** `classifyInShadow`: `taint.ControlFlag.count(Terminal)` →
   `InShadow=true`, `Flag = taint.ControlFlag[Terminal]`,
   `KeepAliveAnchor = taint.FlagTeardown[Flag]`. Missing anchor → diagnostic
   (never silently emit unbracketed). Wire the controlled path in `EmitInverse`
   (`Flag` arg → `controlledDataTemplateFn(inverse=true)` /
   `controlledRotationFn(inverse=true)`).
3. **Polarity caveat (own it):** `ArmNegated` / WP8 false-arms wrap controlled
   gates in a `cqrt_x(flag) … cqrt_x(flag)` bracket firing on **¬flag**
   (`ControlledSubstitution.cpp:34-70`), while `ControlFlag` stores the **positive**
   flag. Anchoring on the recorded teardown lands the data-adjoint **inside** the
   same bracket → polarity correct. Add a false-arm sub-fixture or scope to
   positive-flag and **file a follow-up bead**.
4. **Green:** the in-shadow fixture passes in order; full pre-Phase-5 suite green.
- *Budget:* `InShadowAdjoint` ~150.

### 4.5 Step 5 — R1 double-emit guard (Uncomputation partition)

1. **Red:** `lowering_uncompute_no_flag_touch.ll` (PRD §4 bullet 8) — reuse a
   Phase-4 controlled-diamond body; `CHECK-NOT` any `cqrt_free`/`_inv` targeting a
   flag handle (the `ControlFlag` **image**).
2. **Implement / confirm** `Uncomputation` subtracts `ControlFlag` **values**, not
   keys (the direction trap, §2.2).
3. **Green.**

### 4.6 Step 6 — `Uncomputation` orchestrator + wiring finalize

1. Finalize the driver: target-set subtraction; per-function `DominatorTree DT(F)`
   + `PostDominatorTree PDT(F)`; honor the no-quantum fast path; terminal loop;
   per terminal: `classifyInShadow` → `recoverForwardChain` → `computeFreePoint`.
   `Measured` → skip entirely; `Escaped` → skip (already diagnosed). For `Insert`
   or in-shadow: set `IRBuilder` at `KeepAliveAnchor` (else the post-dom point),
   `emitInverseChain` with `Flag`, **then** `CreateCall(wd.freeFn(), {Terminal})`
   **after** the adjoint at the **same** point (2.10).
2. Confirm **both** `run()` and `runOnFunction()` call `uncompute`; `CMakeLists`
   lists all new files in case-insensitive alphabetical position.
3. **Green:** the full `ir-pass` LIT suite via `-passes=cq-lowering` (no new pass
   name, 2.8).
- *Budget:* `Uncomputation` ~200.

### 4.7 Step 7 — e2e trace smoke

1. `tests/e2e/slice_p5_lastuse.c` — a **non-`main`** `slice()` with a mid-function
   last use (so escape rules 2.6 don't suppress emission; `main` only calls
   `slice`).
2. `add_test(NAME e2e-slice-p5-lastuse …)` in `tests/e2e/CMakeLists.txt`, copying
   the 8-arg `COMMAND` form (`tests/e2e/CMakeLists.txt:43-49`).
3. **Capture** `slice_p5_lastuse.expected.log` from a **real run** — handle ids
   advance per alloc **and** per `_inv` template call; `cqrt_ry/rz/x/free` are void
   and mint **no** handle. **Never hand-author** the golden. `cqrt_free` traces as
   `cqrt_free(h<N>)` with **no** `-> ` arrow.
4. **Green:** `diff -u` clean (`tests/e2e/run_slice.sh:16`).

### 4.8 Step 8 — no-change evidence

`python3 tools/gen_templates.py --check --output-dir runtime` (returncode 0; run
from repo root — `--output-dir` is a **required** argument, omitting it exits
rc=2 argparse error); confirm the banner SHA `addba88d…b7eb` unchanged. Cite as
PRD §3 "no runtime/template changes."

---

## §5 Test plan

Positive fixtures carry the two-RUN-line shape (`lowering_basic.ll:4-5`):

```
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
```

Note the `opt -verify` line is written as a **pipeline** (`| %cq-opt -passes=verify
-disable-output -`), **not** a bare flag. Negative fixtures use a **single** RUN
line `RUN: not %cq-opt … -S %s 2>&1 | %filecheck %s` + `CHECK: error{{.*}}<text>`
(the `lowering_control_escape.ll:12-13` shape) and **omit** the verify line (no
valid IR to verify). FileCheck enforces order across sequential plain `CHECK`
directives — used to pin LIFO/reverse order.

**Row source legend:** rows tagged **[§4]** map 1:1 to one of the nine PRD §4
done-criteria (all nine are covered, verified); rows tagged **[inv]** are extra
invariant guards, **not** enumerated §4 bullets.

| Source | PRD §4 done-criterion / invariant | Fixture / e2e | Key idioms |
|---|---|---|---|
| [§4] | Mid-function non-`main` last use → reversed seq + `cqrt_free`, verify clean | `lowering_uncompute_lastuse_midfunc.ll` (rotation-only body) | `CHECK: call …` negated-angle then `CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})`; 2-RUN |
| [§4] | Reassigned variable → whole chain `mul_inv → add_inv → cqrt_ry(-θ)` (2.1) | `lowering_uncompute_chain_reassign.ll` | **sequential** `CHECK` lines (FileCheck order) pinning the three inv calls + `cqrt_free` |
| [§4] | Both-arm use → single uncompute at merge, no dup (2.4) | `lowering_uncompute_branch_botharms.ll` | one `CHECK: cqrt_free`; `CHECK-NOT` a second; `opt -verify` guards the φ |
| [§4] | HH intermediate reverted; measured-only handle gets no adjoint/free (2.5) | `lowering_uncompute_hh_intermediate.ll` | `CHECK` temp inv + free; `CHECK-NOT: cqrt_free(i32 %<measured>)`, `CHECK-NOT` adjoint on it |
| [§4] | In-shadow → `_controlled_inv`, nested before flag teardown (2.7) | `lowering_uncompute_inshadow_controlled.ll` | sequential `CHECK: …_controlled_inv` **before** `CHECK: cq_template_icmp_…_inv`; verify clean |
| [§4] | Escape: return → no emit (2.6) | `lowering_uncompute_escape_return.ll` | `CHECK-NOT: cqrt_free` (positive RUN; IR valid, nothing emitted) |
| [§4] | Escape: main → no emit (2.6) | `lowering_uncompute_escape_main.ll` | `CHECK-NOT: cqrt_free` |
| [§4] | Escape: cq_invert → no emit (2.6) | `lowering_uncompute_escape_invert.ll` | `CHECK-NOT: cqrt_free` |
| [§4] | Unrecognized escape → loud diag (2.6) | `lowering_uncompute_escape_unrecognized.ll` | `RUN: not …`; `CHECK: error{{.*}}<exact Msg>`; optional `!dbg` for `CHECK: error: <file>:<line>:<col>:` |
| [inv] | Post-measure use → loud reject (2.5 **sub-rule**, PRD §2.5) | `lowering_uncompute_postmeasure_use.ll` | `RUN: not …`; `CHECK: error{{.*}}<exact Msg>` |
| [§4] | Loop-backedge crossing → loud diag (2.9) | `lowering_uncompute_loop_backedge.ll` | `RUN: not …`; `CHECK: error{{.*}}<exact Msg>` |
| [inv] | Control flag not touched (R1) | `lowering_uncompute_no_flag_touch.ll` | `CHECK-NOT: cqrt_free(i32 %<flag>)`; no `_inv` on a `ControlFlag`-image handle |
| [inv] | R2 stale-sequence: no plain `_inv` in-shadow | (asserted inside `lowering_uncompute_inshadow_controlled.ll`) | `CHECK-NOT: <op>_inv\b` (no plain inv) |
| [§4] | e2e trace smoke clean | `tests/e2e/slice_p5_lastuse.c` + `.expected.log` | `run_slice.sh`; golden **captured from a real run** |

(The nine [§4] rows above are the nine PRD §4 done-criteria — three escapes count
as the single 2.6 no-emit bullet's enumerated cases.)

**How loud diagnostics are asserted + a SHIP-BLOCKER caveat.** `RUN: not` inverts
`opt`'s nonzero exit (a `DS_Error` `DiagnosticInfoUnsupported` makes `opt` exit
nonzero), `2>&1` routes the message to FileCheck. `FreePoint` **owns** the exact
`Msg` strings; the fixture `CHECK` must match them character-for-character — these
are **new** diagnostics (post-measure-use, loop-backedge, unrecognized-escape) and
are **not** necessarily the existing `"… under quantum control"` suffix
(`ControlDetection.cpp:53`), so the plan must publish each new `Msg` when
`FreePoint` lands and the fixture mirrors it. Reuse the `diagnoseEscape` idiom
(`ControlDetection.cpp:51-56`: `…getContext().diagnose(DiagnosticInfoUnsupported(*F,
Msg, Where->getDebugLoc()))`) so `!dbg` location prints.

**The shell fallback SKIPs negatives.** `ir-pass/test/run_shell_tests.sh:66-74`
explicitly SKIPs any fixture whose RUN line contains `not %cq-opt` (lines 66-67)
and any capture-var fixture (lines 68-69), then `continue`s (70-73) — so the three
loud-diagnostic done-criteria (2.5/2.6/2.9) **auto-pass by skip** without real
LIT. **Real LIT + FileCheck-19 (the `_use_lit` path, set at
`ir-pass/test/CMakeLists.txt:81`, guarded by `if(_use_lit)` at `:85`) MUST be
installed** for these gates to actually run; otherwise they ship untested. State
this in the PR description.

---

## §6 Commit sequence

Each commit is test-first and leaves the tree building + LIT green. Because
`uncompute()` is live in both entry points from commit 1, every commit's gate
includes **"full pre-Phase-5 LIT suite + e2e goldens stay green"** (the live-pass
regression rule, §4).

0. **`feat(phase4): record flag teardown in TaintSet for Phase-5 keep-alive`** —
   `TaintPropagation.h` (`FlagTeardown` field) + `ControlledLowering.cpp`
   `emitUncompute` (~6-line populate) + `ir-pass/test/phase4_flag_teardown_unchanged.ll`.
   *Green:* the Phase-4 regression fixture (teardown byte-unchanged).
1. **`feat(widthdispatch): inverse param + cqrt_free resolver`** +
   **`feat(emit-inverse): rotation-negate / self-adjoint spine + pass wiring`** —
   `WidthDispatch.*`, `EmitInverse.*` (+ `InverseDecode.*` if split), conservative
   `Uncomputation.*` (wires the pass, emits only the rotation-only terminal), basic
   `FreePoint.*`, `CQLoweringPass.cpp` (both slots), `CMakeLists.txt` +
   `lowering_uncompute_lastuse_midfunc.ll` (rotation-only body). *Green:*
   mid-function last use + `opt -verify` + **full pre-Phase-5 suite/e2e green**.
2. **`feat(chainwalk): whole-register forward-chain reconstruction`** —
   `ChainWalk.*`, `EmitInverse` template `_inv` extension (fresh-handle threading) +
   `lowering_uncompute_chain_reassign.ll`. *Green:* reassigned whole-chain order +
   full pre-Phase-5 suite green.
3. **`feat(freepoint): postdom last-use + measure/escape + loud diagnostics`** —
   `FreePoint.*` (+ `EscapeClassify.*` if split) + the eight Step-3 fixtures.
   *Green:* both-arm merge, HH intermediate, three escapes, three negatives + full
   pre-Phase-5 suite green.
4. **`feat(inshadow): controlled adjoint nested in Phase-4 flag bracket`** —
   `InShadowAdjoint.*`, `EmitInverse` controlled path +
   `lowering_uncompute_inshadow_controlled.ll`. *Green:* `_controlled_inv` before
   teardown.
5. **`test(uncompute): R1 no-flag-touch guard`** —
   `lowering_uncompute_no_flag_touch.ll`; confirm image-subtraction. *Green:* R1.
6. **`feat(uncompute): finalize orchestrator + partition`** — `Uncomputation.*`
   finalized; full LIT suite green via `-passes=cq-lowering`.
7. **`test(e2e): phase-5 mid-function last-use trace smoke`** —
   `slice_p5_lastuse.c`, `.expected.log` (captured), `CMakeLists` add_test.
   *Green:* e2e diff clean.
8. **`chore(phase5): no-runtime-change evidence`** — cite `gen_templates.py
   --check --output-dir runtime` returncode 0 + SHA `addba88d…b7eb` unchanged.

---

## §7 Risk mitigations

| PRD §6 risk | Mitigation (module + fixture) |
|---|---|
| **Double-emit across the Phase 4 seam (2.2/R1).** | `Uncomputation` subtracts the `ControlFlag` **image** (not keys — the direction trap, §2.2); `lowering_uncompute_no_flag_touch.ll` `CHECK-NOT` asserts no Phase-5 emission touches a flag handle. |
| **Stale-sequence reversal (2.8).** | Fixed **last** pass slot in both `CQLoweringPass` entry points; `lowering_uncompute_inshadow_controlled.ll` asserts `_controlled_inv` (not plain `_inv`). |
| **Flag-lifetime ordering under keep-alive (2.7).** | `InShadowAdjoint` anchors on the recorded `FlagTeardown` `CallInst`; the in-shadow fixture's sequential `CHECK` asserts the flag teardown follows the data-adjoint. |
| **Whole-chain vs per-SSA confusion (2.1).** | `ChainWalk` reconstructs from def-use operand-0 threading + `isTerminalHandle` collapses the chain; `lowering_uncompute_chain_reassign.ll` pins the order. |
| **Insertion point vs φ-nodes (2.4).** | `FreePoint` uses `getFirstInsertionPt()` (after φ); `lowering_uncompute_branch_botharms.ll` exercises a φ-bearing merge; the `opt -verify` RUN line guards. |
| **PostDominatorTree on unusual CFG (2.4/2.9).** | Acyclic assumption + loop-backedge diagnostic; a non-reconverging arm (null common post-dominator) is converted to a **loud** diagnostic (not the prototype's silent `nullptr`) — `lowering_uncompute_loop_backedge.ll` + `_escape_unrecognized.ll`. |

**NEW risks the maps surfaced (not in PRD §6):**

- **R-live-pass-regression (resolved by §4 rule + conservative commit-1).**
  `uncompute()` is live in both entry points from commit 1, so a "minimal" slice
  that frees terminals unconditionally would turn the entire existing Phase-1–4
  suite + e2e goldens red (measured/returned/`main`-resident handles everywhere).
  Mitigation: commit 1's `Uncomputation` emits **nothing** until `ChainWalk` +
  `FreePoint` land selection, and every commit re-runs the **full** pre-Phase-5
  suite as its gate.
- **R-keep-alive-discoverability (resolved by Step 0, mandatory).** PRD 2.7's
  "verify Phase 4 leaves the teardown discoverable" resolves to **No** — the
  plain-compare teardown is `cq_template_icmp_*_inv` over the **condition** data
  handles, not the flag (`ControlledLowering.cpp:110-111`), and `R.MergeBB` is
  erased post-linearization (`CFGLinearization.cpp:62`). The `TaintSet::FlagTeardown`
  hook is therefore a **hard precondition**, front-loaded as commit 0, not a
  verify-at-WP-time deferral.
- **R-birthorder-not-lineage (resolved by ChainWalk).** PRD 2.1/§6's "`BirthOrder`
  lineage walk" has no backing data structure — `BirthOrder` is a flat mint
  counter (`TaintPropagation.h:60`). `ChainWalk` reconstructs from def-use;
  `BirthOrder` is a tie-breaker only. We do **not** add a lineage map.
- **R-negated-flag-polarity (scoped + follow-up bead).** `ArmNegated`/WP8
  false-arms fire on **¬flag** (`ControlledSubstitution.cpp:34-70`) while
  `ControlFlag` stores the positive flag. Anchoring on the recorded teardown lands
  the adjoint inside the same `cqrt_x` bracket (polarity correct); a false-arm
  sub-fixture or an explicit follow-up bead covers the negative-polarity path.
- **R-template-inv-fresh-handle.** Both forward **and** `_inv` template stubs
  **mint a fresh handle**; `emitInverseChain` must thread the returned SSA value
  (rotations are void/in-place). The reassign and e2e goldens pin this; the e2e
  golden must be captured from a real run (handle-id drift).
- **R-toffoli-out-of-scope.** `cqrt_toffoli` *does* have a `_inv` twin
  (`ControlledSymbols.cpp:96`) but is Phase-4 flag-conjunction control scratch
  (PRD §2.2/§5) — it must **not** enter the Phase-5 emission table; §3 excludes it
  (and `cqrt_cnot`) so an out-of-scope target cannot be pulled into the recipe.

---

## §8 Reconciliations & open questions

**backend.md §9 vs PRD (refined by 2.1).** §9.1 frames last-use "per tainted
value/handle" and its prototype fixtures were single-op chains; PRD 2.1 pins this
to the terminal-handle **whole register chain**. §9.2's "adjoint of the gate
sequence that produced `%h`" means the **full reversed chain**, not just the last
op. The reassigned-variable fixture (`lowering_uncompute_chain_reassign.ll`) is the
artifact that disambiguates this — backend.md has no such fixture.

**backend.md §10.1 vs PRD (added by 2.3).** §10.1's `emit_inverse` pseudocode
covers only **gate** granularity (angle-negate vs self-adjoint) and omits the
template `_inv` twins; PRD 2.3 **adds** template-call granularity
(`cq_template_<op>_<W>` → `_inv`, controlled → `_controlled_inv`). §10.1's table
also omits `cqrt_cswap` and `cqrt_rz_controlled_inv`. Phase 5 implements
`emit_inverse` at **template-call** granularity (the §10.1 gate table is the
post-freeze form), so fixtures `CHECK` for `cq_template_*_inv` symbols, not raw
`cqrt_ry(-θ)` except for the directly-emitted rotation prep.

**backend.md §9.3 vs PRD 2.6 (cq_invert interaction).** §9.3 calls
`cq_invert_*` "a downstream concern" (deferred); PRD 2.6 requires Phase 5 to
actively **skip** handles inside `cq_invert_*` regions **now** (the `escape_invert`
fixture asserts no Phase-5 emit inside the bracket). Reconciliation: Phase 5 only
**skips** (no emit, no diag); Phase 7 (beads `test_C_libtooling-42t`) supersedes
with real inversion, reusing the 2.3 helper.

**Runtime-surface scoping (avoid a false gap claim).** "Every forward symbol has
an `_inv` twin" is true for the **template** surface (586/586) and the
**controlled-rotation** surface (`_controlled_inv` 196/196), but the
**uncontrolled rotation** primitives have **no** `_inv` symbol by design — the
inverse is the same `cqrt_ry/rz_<W>` with a negated angle. There is **no**
`cqrt_ry_<W>_controlled` forward (only `controlledRyInvFn`'s `_controlled_inv`,
`ControlledSymbols.cpp:74-89`); do not claim one exists. The plan's §3 keeps the
rotation-negation path stated separately from the template-twin path.

**Open questions to verify when modules land:**

1. **Conjunction / nested keep-alive anchor.** Step 0 records `FlagTeardown`
   keyed by `region.Flag`; confirm the conjunction path (`emitUncompute` →
   `uncombineFlags` then sub-compare `_inv`s, `ControlledLowering.cpp:86-93`)
   records the **first** emitted instruction so the data-adjoint nests outside the
   entire conjunction teardown (LIFO).
2. **Negated-flag bracket polarity.** Confirm anchoring on the recorded teardown
   places the controlled data-adjoint inside the correct `cqrt_x(flag)` bracket for
   `ArmNegated`/false-arm cases; add the sub-fixture or file the follow-up bead.
3. **MUX-EXCH naturally excluded.** `reduceAngleSwitchPhi` does **not** stamp
   `ControlFlag` (`MergeDissolution.cpp:595-599` — per-case flags, not a single
   `region.Flag`), so gated-switch arm handles are not in the map and Phase 5's
   keying on `ControlFlag` excludes them (PRD out-of-scope, Phase 4 control
   scratch, beads `test_C_libtooling-npu.6`) — confirm no terminal from those arms
   slips into the data target set.
4. **`runOnFunction` target-set scope.** The shim restricts work lists to a single
   `F`; confirm the Phase-5 target-set subtraction still reads the **full**
   `taint.ControlFlag` (a module-wide map) so per-function PDT walks don't
   mis-classify.
